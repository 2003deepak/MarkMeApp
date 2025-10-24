import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/core/theme/app_theme.dart';
import 'package:markmeapp/data/repositories/student_repository.dart';
import 'package:markmeapp/presentation/skeleton/student_edit_profile_skeleton.dart';
import 'package:markmeapp/presentation/widgets/academic_info_section.dart';
import 'package:markmeapp/presentation/widgets/save_button_section.dart';
import 'package:markmeapp/presentation/widgets/student_gallery_section.dart';
import 'package:markmeapp/presentation/widgets/student_personal_info_section.dart';
import 'package:markmeapp/presentation/widgets/ui/profile_picture.dart';
import 'package:markmeapp/state/student_state.dart';
import 'package:collection/collection.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isFormDirty = false;
  bool _isUpdating = false;

  // Form data
  DateTime? _dob;
  String _program = 'MCA';
  String _department = 'BTECH';
  int _semester = 1;
  String? _profilePicture;
  final List<String?> _gallery = List<String?>.filled(4, null);
  bool _isEmbeddings = false;

  bool _initialDataLoaded = false;
  Map<String, dynamic>? _initialData;

  // Initialize controllers directly instead of using late final
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _middleNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _dobCtrl = TextEditingController();
  final TextEditingController _rollCtrl = TextEditingController();
  final TextEditingController _batchYearCtrl = TextEditingController();
  final TextEditingController _semesterCtrl = TextEditingController();

  // List of controllers that should trigger form dirty check
  List<TextEditingController> get _listenableControllers => [
    _firstNameCtrl,
    _middleNameCtrl,
    _lastNameCtrl,
    _emailCtrl,
    _phoneCtrl,
    _rollCtrl,
    _batchYearCtrl,
    _semesterCtrl,
  ];

  @override
  void initState() {
    super.initState();
    _setupListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchProfileData());
  }

  void _setupListeners() {
    for (final controller in _listenableControllers) {
      controller.addListener(_checkFormDirty);
    }
  }

  void _checkFormDirty() {
    if (!_initialDataLoaded) return;

    final hasChanges = !_areMapsEqual(_initialData, _getCurrentFormData());

    if (hasChanges != _isFormDirty) {
      setState(() => _isFormDirty = hasChanges);
    }
  }

  Map<String, dynamic> _getCurrentFormData() {
    String? _nullIfEmpty(String? value) =>
        (value == null || value.trim().isEmpty) ? null : value.trim();

    return {
      'first_name': _nullIfEmpty(_firstNameCtrl.text),
      'middle_name': _nullIfEmpty(_middleNameCtrl.text),
      'last_name': _nullIfEmpty(_lastNameCtrl.text),
      'email': _nullIfEmpty(_emailCtrl.text),
      'phone': _nullIfEmpty(_phoneCtrl.text),
      'dob': _dob?.toIso8601String().split('T').first,
      'roll_number': _nullIfEmpty(_rollCtrl.text),
      'program': _program,
      'department': _department,
      'semester': _semester,
      'batch_year': _nullIfEmpty(_batchYearCtrl.text),
      'profile_picture': _profilePicture,
      'gallery': _gallery.whereType<String>().toList(),
      'is_embeddings': _isEmbeddings,
    };
  }

  bool _areMapsEqual(Map<String, dynamic>? map1, Map<String, dynamic>? map2) {
    if (map1 == null || map2 == null) return map1 == map2;
    if (map1.length != map2.length) return false;

    for (final key in map1.keys) {
      if (key == 'gallery') {
        final list1 = map1[key] as List?;
        final list2 = map2[key] as List?;
        if (!const ListEquality().equals(list1, list2)) return false;
      } else if (map1[key] != map2[key]) {
        return false;
      }
    }
    return true;
  }

  bool get _isSaveEnabled {
    if (!_isFormDirty || _isUpdating) return false;
    if (!_isEmbeddings && _gallery.whereType<String>().length != 4)
      return false;
    return true;
  }

  Future<void> _fetchProfileData() async {
    final studentStore = ref.read(studentStoreProvider.notifier);
    await studentStore.loadProfile();
  }

  Future<void> _updateProfile() async {
    if (!_initialDataLoaded || _isUpdating) return;

    final changedData = _getChangedData();
    if (changedData.isEmpty) {
      _showSnackBar("No changes to save.", Colors.orange);
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final formData = await _buildFormData(changedData);
      final studentStore = ref.read(studentStoreProvider.notifier);
      final result = await studentStore.updateProfile(formData);

      if (result['success'] == true) {
        await _handleUpdateSuccess();
      } else {
        _showSnackBar(
          result['message'] ?? 'Failed to update profile',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('An error occurred: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Map<String, dynamic> _getChangedData() {
    final currentData = _getCurrentFormData();
    final changedData = <String, dynamic>{};

    currentData.forEach((key, value) {
      final initialValue = _initialData?[key];
      if (key == 'gallery') {
        final initialGallery = (initialValue ?? []) as List;
        final currentGallery = (value ?? []) as List;
        if (!const ListEquality().equals(initialGallery, currentGallery)) {
          changedData[key] = currentGallery;
        }
      } else if (value != initialValue) {
        changedData[key] = value;
      }
    });

    return changedData;
  }

  Future<FormData> _buildFormData(Map<String, dynamic> changedData) async {
    final formData = FormData();

    for (final entry in changedData.entries) {
      if (entry.key == 'profile_picture') {
        if (entry.value != null && File(entry.value).existsSync()) {
          final file = await MultipartFile.fromFile(
            entry.value,
            filename: "profile.jpg",
          );
          formData.files.add(MapEntry('profile_picture', file));
        }
      } else if (entry.key == 'gallery' && !_isEmbeddings) {
        await _addGalleryImages(formData, entry.value as List<String>);
      } else if (entry.value != null) {
        formData.fields.add(MapEntry(entry.key, entry.value.toString()));
      }
    }

    return formData;
  }

  Future<void> _addGalleryImages(
    FormData formData,
    List<String> galleryPaths,
  ) async {
    for (int i = 0; i < galleryPaths.length; i++) {
      final path = galleryPaths[i];
      if (path.isNotEmpty && File(path).existsSync()) {
        final file = await MultipartFile.fromFile(
          path,
          filename: 'gallery_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );
        formData.files.add(MapEntry('images', file));
      }
    }
  }

  Future<void> _handleUpdateSuccess() async {
    _initialData = _getCurrentFormData();
    await _fetchProfileData();

    if (mounted) {
      setState(() => _isFormDirty = false);
      _showSnackBar('Profile updated successfully', Colors.green);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor),
      );
    }
  }

  void _populateFormFromState() {
    final state = ref.read(studentStoreProvider);
    final profile = state.profile;

    if (profile != null && !_initialDataLoaded) {
      setState(() {
        _firstNameCtrl.text = profile['first_name'] ?? '';
        _middleNameCtrl.text = profile['middle_name'] ?? '';
        _lastNameCtrl.text = profile['last_name'] ?? '';
        _emailCtrl.text = profile['email'] ?? '';
        _dobCtrl.text = profile['dob'] ?? '';
        _phoneCtrl.text = profile['phone'] ?? '';
        _rollCtrl.text = profile['roll_number']?.toString() ?? '';
        _batchYearCtrl.text = profile['batch_year']?.toString() ?? '';
        _semesterCtrl.text = profile['semester']?.toString() ?? '1';
        _program = profile['program'] ?? 'MCA';
        _department = profile['department'] ?? 'BTECH';
        _semester = profile['semester'] ?? 1;
        _profilePicture = profile['profile_picture'];
        _isEmbeddings = profile['is_embeddings'] ?? false;

        _populateGallery(profile);
        _populateDob(profile);

        _initialDataLoaded = true;
        _initialData = _getCurrentFormData();
      });
    }
  }

  void _populateGallery(Map<String, dynamic> profile) {
    if (!_isEmbeddings &&
        profile['gallery'] != null &&
        profile['gallery'] is List) {
      final galleryList = profile['gallery'] as List;
      for (int i = 0; i < _gallery.length && i < galleryList.length; i++) {
        _gallery[i] = galleryList[i];
      }
    }
  }

  void _populateDob(Map<String, dynamic> profile) {
    final dobString = profile['dob'];
    if (dobString != null) {
      _dob = DateTime.tryParse(dobString);
      if (_dob != null) {
        _dobCtrl.text = _formatDateForDisplay(_dob!);
      }
    }
  }

  // Event handlers
  void _handleProfilePictureChanged(String? imagePath) {
    setState(() {
      _profilePicture = imagePath;
      _checkFormDirty();
    });
  }

  void _handleGalleryImagePicked(int index, String imagePath) {
    setState(() {
      _gallery[index] = imagePath;
      _checkFormDirty();
    });
  }

  void _handleDobChanged(DateTime? newDob) {
    setState(() {
      _dob = newDob;
      _dobCtrl.text = newDob != null ? _formatDateForDisplay(newDob) : '';
      _checkFormDirty();
    });
  }

  void _handleProgramChanged(String? value) {
    if (value != null) _updateValue(() => _program = value);
  }

  void _handleDepartmentChanged(String? value) {
    if (value != null) _updateValue(() => _department = value);
  }

  void _handleSemesterChanged(int? value) {
    if (value != null) {
      _updateValue(() {
        _semester = value;
        _semesterCtrl.text = value.toString();
      });
    }
  }

  void _updateValue(VoidCallback updateCallback) {
    setState(updateCallback);
    _checkFormDirty();
  }

  // Validation methods
  String? _validateFirstName(String? value) =>
      _validateMinLength(value, 2, 'First name');
  String? _validateLastName(String? value) =>
      _validateMinLength(value, 2, 'Last name');

  String? _validateEmail(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      if (!emailRegex.hasMatch(value.trim())) {
        return 'Please enter a valid email address';
      }
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final cleaned = value.trim().replaceAll(RegExp(r'[^\d]'), '');
      if (cleaned.length != 10) return 'Phone number must be 10 digits';
      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
        return 'Please enter a valid phone number';
      }
    }
    return null;
  }

  String? _validateRollNumber(String? value) =>
      _validateNumeric(value, 'Roll number');
  String? _validateBatchYear(String? value) => _validateYear(value);
  String? _validateSemester(String? value) => _validateSemesterValue(value);

  String? _validateMinLength(String? value, int min, String field) {
    if (value != null && value.trim().isNotEmpty && value.trim().length < min) {
      return '$field must be at least $min characters';
    }
    return null;
  }

  String? _validateNumeric(String? value, String field) {
    if (value != null && value.trim().isNotEmpty) {
      if (value.trim().length < 3) {
        return '$field must be at least 3 characters';
      }
      if (int.tryParse(value.trim()) == null) return '$field must be a number';
    }
    return null;
  }

  String? _validateYear(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final year = int.tryParse(value.trim());
      if (year == null) return 'Please enter a valid year';
      final currentYear = DateTime.now().year;
      if (year < 2000 || year > currentYear + 1) {
        return 'Please enter a valid batch year';
      }
    }
    return null;
  }

  String? _validateSemesterValue(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final semester = int.tryParse(value.trim());
      if (semester == null) return 'Please enter a valid semester';
      if (semester < 1 || semester > 12) {
        return 'Semester must be between 1 and 12';
      }
    }
    return null;
  }

  @override
  void dispose() {
    for (final controller in _listenableControllers) {
      controller.removeListener(_checkFormDirty);
    }

    // Dispose all controllers
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _rollCtrl.dispose();
    _batchYearCtrl.dispose();
    _semesterCtrl.dispose();

    super.dispose();
  }

  // UI Constants
  final _cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 4)),
    ],
  );

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4B5563),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentState = ref.watch(studentStoreProvider);

    if (studentState.profile != null && !_initialDataLoaded) {
      _populateFormFromState();
    }

    if (_isUpdating) return _buildLoadingOverlay();
    if (studentState.profile == null && !_initialDataLoaded) {
      return const StudentEditProfileSkeleton();
    }

    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildAppBar(),
        body: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: _buildFormContent(studentState),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: _buildFormContent(ref.read(studentStoreProvider)),
            ),
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Updating Profile...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF2563EB),
      elevation: 0,
      leading: IconButton(
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(0xFF475569),
          ),
        ),
        onPressed: _isUpdating ? null : _handleBackPressed,
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (_isFormDirty)
            ..._buildStatusBadge('Unsaved', const Color(0xFFEF4444)),
          if (_isUpdating)
            ..._buildStatusBadge('Saving...', const Color(0xFF3B82F6)),
        ],
      ),
      centerTitle: true,
    );
  }

  List<Widget> _buildStatusBadge(String text, Color color) {
    return [
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ];
  }

  void _handleBackPressed() {
    if (_isFormDirty) {
      _showUnsavedChangesDialog();
    } else {
      context.go("/student/profile");
    }
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go("/student/profile");
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFormContent(StudentState studentState) {
    final galleryImageCount = _gallery.whereType<String>().length;

    return [
      ProfilePicture(
        profilePicture: _profilePicture,
        cardDecoration: _cardDecoration,
        onProfilePictureChanged: _handleProfilePictureChanged,
        showChangeText: true,
        imageSize: 120,
        cameraIconSize: 36,
      ),
      const SizedBox(height: 24),
      _sectionHeader('PERSONAL INFORMATION'),
      StudentPersonalInfoSection(
        firstNameCtrl: _firstNameCtrl,
        middleNameCtrl: _middleNameCtrl,
        lastNameCtrl: _lastNameCtrl,
        emailCtrl: _emailCtrl,
        phoneCtrl: _phoneCtrl,
        dobCtrl: _dobCtrl,
        dob: _dob,
        cardDecoration: _cardDecoration,
        onDobChanged: _handleDobChanged,
        validateFirstName: _validateFirstName,
        validateLastName: _validateLastName,
        validateEmail: _validateEmail,
        validatePhone: _validatePhone,
      ),
      const SizedBox(height: 24),
      _sectionHeader('ACADEMIC INFORMATION'),
      AcademicInfoSection(
        rollCtrl: _rollCtrl,
        batchYearCtrl: _batchYearCtrl,
        program: _program,
        department: _department,
        semester: _semester,
        onProgramChanged: _handleProgramChanged,
        onDepartmentChanged: _handleDepartmentChanged,
        onSemesterChanged: _handleSemesterChanged,
        cardDecoration: _cardDecoration,
        validateRollNumber: _validateRollNumber,
        validateBatchYear: _validateBatchYear,
        validateSemester: _validateSemester,
      ),
      if (!_isEmbeddings) ..._buildGallerySection(galleryImageCount),
      const SizedBox(height: 32),
      SaveButtonSection(
        onSave: _updateProfile,
        isSaveEnabled: _isSaveEnabled,
        isLoading: _isUpdating,
      ),
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _buildGallerySection(int galleryImageCount) {
    return [
      const SizedBox(height: 24),
      _sectionHeader('GALLERY'),
      StudentGallerySection(
        gallery: _gallery,
        onPickGalleryImage: _handleGalleryImagePicked,
        cardDecoration: _cardDecoration,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Text(
          'All 4 photos must be uploaded to save changes ($galleryImageCount/4)',
          style: TextStyle(
            fontSize: 12,
            color: galleryImageCount == 4 ? Colors.green : Colors.orange,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ];
  }

  String _formatDateForDisplay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
