import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markmeapp/core/theme/app_theme.dart';
import 'package:markmeapp/presentation/widgets/save_button_section.dart';
import 'package:markmeapp/presentation/widgets/ui/profile_picture.dart';
import 'package:markmeapp/presentation/widgets/ui/input_field.dart';
import 'package:markmeapp/state/teacher_state.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';
import 'package:flutter/services.dart';

class TeacherEditProfilePage extends ConsumerStatefulWidget {
  const TeacherEditProfilePage({super.key});

  @override
  ConsumerState<TeacherEditProfilePage> createState() =>
      _TeacherEditProfilePageState();
}

class _TeacherEditProfilePageState
    extends ConsumerState<TeacherEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isFormDirty = false;
  bool _isUpdating = false;

  // Form data
  String? _profilePicture;
  bool _initialDataLoaded = false;
  Map<String, dynamic>? _initialData;

  // Controllers
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _middleNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _departmentCtrl = TextEditingController();

  // List of controllers that should trigger form dirty check
  List<TextEditingController> get _listenableControllers => [
        _firstNameCtrl,
        _middleNameCtrl,
        _lastNameCtrl,
        _emailCtrl,
        _phoneCtrl,
      ];

  @override
  void initState() {
    super.initState();
    _setupListeners();
    // Pre-load data if available in state, otherwise fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(teacherStoreProvider);
      if (state.profile != null) {
        _populateFormFromState(state.profile!);
      } else {
        _fetchProfileData();
      }
    });
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
    String? nullIfEmpty(String? value) =>
        (value == null || value.trim().isEmpty) ? null : value.trim();

    return {
      'first_name': nullIfEmpty(_firstNameCtrl.text),
      'middle_name': nullIfEmpty(_middleNameCtrl.text),
      'last_name': nullIfEmpty(_lastNameCtrl.text),
      'email': nullIfEmpty(_emailCtrl.text),
      'phone_number': nullIfEmpty(
        _phoneCtrl.text,
      ), // Key typically matches backend expectation
      'profile_picture': _profilePicture,
    };
  }

  bool _areMapsEqual(Map<String, dynamic>? map1, Map<String, dynamic>? map2) {
    if (map1 == null || map2 == null) return map1 == map2;
    if (map1.length != map2.length) return false;

    for (final key in map1.keys) {
      if (map1[key] != map2[key]) {
        return false;
      }
    }
    return true;
  }

  bool get _isSaveEnabled {
    if (!_isFormDirty || _isUpdating) return false;
    return true;
  }

  Future<void> _fetchProfileData() async {
    final store = ref.read(teacherStoreProvider.notifier);
    await store.loadProfile();
  }

  Future<void> _updateProfile() async {
    if (!_initialDataLoaded || _isUpdating) return;

    final changedData = _getChangedData();
    if (changedData.isEmpty) {
      _showSnackBar("No changes to save.", Colors.orange);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _showSnackBar("Please fix the errors before saving.", Colors.red);
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final formData = await _buildFormData(changedData);
      final store = ref.read(teacherStoreProvider.notifier);
      final result = await store.updateProfile(formData);

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
      if (value != initialValue) {
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
      } else {
        formData.fields.add(MapEntry(entry.key, entry.value?.toString() ?? ''));
      }
    }

    return formData;
  }

  Future<void> _handleUpdateSuccess() async {
    _initialData = _getCurrentFormData();

    if (mounted) {
      setState(() => _isFormDirty = false);
      _showSnackBar('Profile updated successfully', Colors.green);
      context.pop();
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor),
      );
    }
  }

  void _populateFormFromState(Map<String, dynamic> profile) {
    if (!_initialDataLoaded && profile.isNotEmpty) {
      setState(() {
        _firstNameCtrl.text = profile['first_name']?.toString() ?? '';
        _middleNameCtrl.text = profile['middle_name']?.toString() ?? '';
        _lastNameCtrl.text = profile['last_name']?.toString() ?? '';
        _emailCtrl.text = profile['email']?.toString() ?? '';
        _phoneCtrl.text = profile['mobile_number']?.toString() ?? '';
        _departmentCtrl.text = profile['department']?.toString() ?? '';
        _profilePicture = profile['profile_picture']?.toString();

        _initialDataLoaded = true;
        _initialData = _getCurrentFormData();
      });
    }
  }

  // Event handlers
  void _handleProfilePictureChanged(String? imagePath) {
    setState(() {
      _profilePicture = imagePath;
      _checkFormDirty();
    });
  }

  // Validation methods
  String? _validateFirstName(String? value) =>
      _validateMinLength(value, 2, 'First name');
  String? _validateLastName(String? value) =>
      _validateMinLength(value, 2, 'Last name');

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

  String? _validateMinLength(String? value, int min, String field) {
    if (value != null && value.trim().isNotEmpty && value.trim().length < min) {
      return '$field must be at least $min characters';
    }
    return null;
  }

  @override
  void dispose() {
    for (final controller in _listenableControllers) {
      controller.removeListener(_checkFormDirty);
    }

    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _departmentCtrl.dispose();

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
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
              letterSpacing: 0.2,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherStoreProvider);

    // If state is updated externally, re-sync might be needed,
    // but typically we rely on initial load and local edits.
    // However, if we just came from storage or reload, ensure we populate.
    if (state.profile != null && !_initialDataLoaded) {
      _populateFormFromState(state.profile!);
    }

    if (_isUpdating) return _buildLoadingOverlay(state.subjects);

    if (state.isLoading && !_initialDataLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: MarkMeAppBar(
          title: 'Edit Profile',
          onBackPressed: _isUpdating ? null : _handleBackPressed,
          isLoading: _isUpdating,
          titleWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Profile',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (_isFormDirty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Unsaved',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: null,
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: _buildFormContent(state.subjects),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(List<dynamic> subjects) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: MarkMeAppBar(
          title: 'Edit Profile',
          onBackPressed: null, // Disable back button during loading
          isLoading: true,
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: _buildFormContent(subjects),
            ),
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Updating Profile...',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
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

  void _handleBackPressed() {
    if (_isFormDirty) {
      _showUnsavedChangesDialog();
    } else {
      context.pop();
    }
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
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
                  context.pop();
                },
                child: const Text('Leave', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  List<Widget> _buildFormContent(List<dynamic> subjects) {
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
      Container(
        decoration: _cardDecoration,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: InputField(
                    label: 'First name',
                    controller: _firstNameCtrl,
                    isRequired: true,
                    hintText: 'First name',
                    validator: _validateFirstName,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InputField(
                    label: 'Middle name',
                    controller: _middleNameCtrl,
                    hintText: 'Middle name',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InputField(
              label: 'Last name',
              controller: _lastNameCtrl,
              isRequired: true,
              hintText: 'Last name',
              validator: _validateLastName,
            ),
            const SizedBox(height: 16),
            InputField(
              label: 'Email',
              controller: _emailCtrl,
              readOnly: true,
              hintText: 'Email',
              suffixIcon: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 16),
            InputField(
              label: 'Phone',
              controller: _phoneCtrl,
              isRequired: true,
              hintText: '10-digit phone number',
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _validatePhone,
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      _sectionHeader('ACADEMIC INFORMATION'),
      Container(
        decoration: _cardDecoration,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            InputField(
              label: 'Department',
              controller: _departmentCtrl,
              readOnly: true,
              hintText: 'Department',
              suffixIcon: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      if (subjects.isNotEmpty) ...[
        _sectionHeader('ASSIGNED SUBJECTS'),
        Container(
          decoration: _cardDecoration,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              for (var i = 0; i < subjects.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      height: 1,
                      color: const Color(0xFFF1F5F9),
                    ),
                  ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.book_outlined,
                        color: Color(0xFF4F46E5),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subjects[i]['subject_name']?.toString() ??
                                'Unknown Subject',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                subjects[i]['subject_code']?.toString() ?? '-',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD1D5DB),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  subjects[i]['component']?.toString() ??
                                      'Theory',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
      const SizedBox(height: 32),
      SaveButtonSection(
        onSave: _updateProfile,
        isSaveEnabled: _isSaveEnabled,
        isLoading: _isUpdating,
      ),
      const SizedBox(height: 16),
    ];
  }
}
