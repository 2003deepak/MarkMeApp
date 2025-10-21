import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:markmeapp/core/theme/app_theme.dart';
import 'package:markmeapp/data/repositories/student_repository.dart';
import 'package:markmeapp/presentation/skeleton/student_edit_profile_skeleton.dart';
import 'package:markmeapp/presentation/widgets/academic_info_section.dart';
import 'package:markmeapp/presentation/widgets/save_button_section.dart';
import 'package:markmeapp/presentation/widgets/student_gallery_section.dart';
import 'package:markmeapp/presentation/widgets/student_personal_info_section.dart';
import 'package:markmeapp/presentation/widgets/ui/profile_picture.dart';
import 'package:markmeapp/state/student_state.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isFormDirty = false;

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _middleNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _rollCtrl;
  late final TextEditingController _batchYearCtrl;
  late final TextEditingController _semesterCtrl;

  DateTime? _dob;
  String _program = 'MCA';
  String _department = 'BTECH';
  int _semester = 1;
  String? _profilePicture;
  final List<String?> _gallery = List<String?>.filled(4, null);

  bool _initialDataLoaded = false;
  Map<String, dynamic>? _initialData;

  late final StudentRepository studentRepository;

  @override
  void initState() {
    super.initState();
    studentRepository = ref.read(studentRepositoryProvider);
    _initializeControllers();
    _setupListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchProfileData());
  }

  void _initializeControllers() {
    _firstNameCtrl = TextEditingController();
    _middleNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _dobCtrl = TextEditingController();
    _rollCtrl = TextEditingController();
    _batchYearCtrl = TextEditingController();
    _semesterCtrl = TextEditingController();
  }

  void _setupListeners() {
    _firstNameCtrl.addListener(_checkFormDirty);
    _middleNameCtrl.addListener(_checkFormDirty);
    _lastNameCtrl.addListener(_checkFormDirty);
    _emailCtrl.addListener(_checkFormDirty);
    _phoneCtrl.addListener(_checkFormDirty);
    _rollCtrl.addListener(_checkFormDirty);
    _batchYearCtrl.addListener(_checkFormDirty);
    _semesterCtrl.addListener(_checkFormDirty);
  }

  void _checkFormDirty() {
    if (!_initialDataLoaded) return;

    final currentData = _getCurrentFormData();
    final hasChanges = !_areMapsEqual(_initialData!, currentData);

    if (hasChanges != _isFormDirty) {
      setState(() {
        _isFormDirty = hasChanges;
      });
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
      'dob': _dob?.toIso8601String().split('T').first, // YYYY-MM-DD format
      'roll_number': _nullIfEmpty(_rollCtrl.text),
      'program': _program,
      'department': _department,
      'semester': _semester,
      'batch_year': _nullIfEmpty(_batchYearCtrl.text),
      'profile_picture': _profilePicture,
      'gallery': _gallery.whereType<String>().toList(),
    };
  }

  bool _areMapsEqual(Map<String, dynamic>? map1, Map<String, dynamic>? map2) {
    if (map1 == null || map2 == null) return map1 == map2;
    if (map1.length != map2.length) return false;

    for (final key in map1.keys) {
      if (key == 'gallery') {
        final list1 = map1[key] as List?;
        final list2 = map2[key] as List?;
        if (list1 == null && list2 == null) continue;
        if (list1 == null || list2 == null) return false;
        if (list1.length != list2.length) return false;
        for (int i = 0; i < list1.length; i++) {
          if (list1[i] != list2[i]) return false;
        }
      } else if (map1[key] != map2[key]) {
        return false;
      }
    }
    return true;
  }

  Future<void> _fetchProfileData() async {
    final studentStore = ref.read(studentStoreProvider.notifier);
    await studentStore.loadProfile();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Show loading state
        // ref.read(studentStoreProvider.notifier).setUpdating(true);

        final formData = FormData();

        // Add text fields (all optional as per backend)
        final data = _getCurrentFormData();

        // Add non-file fields according to backend expectations
        if (data['first_name'] != null) {
          formData.fields.add(MapEntry('first_name', data['first_name']!));
        }
        if (data['middle_name'] != null) {
          formData.fields.add(MapEntry('middle_name', data['middle_name']!));
        }
        if (data['last_name'] != null) {
          formData.fields.add(MapEntry('last_name', data['last_name']!));
        }
        if (data['email'] != null) {
          formData.fields.add(MapEntry('email', data['email']!));
        }
        if (data['phone'] != null) {
          formData.fields.add(MapEntry('phone', data['phone']!));
        }
        if (data['dob'] != null) {
          formData.fields.add(MapEntry('dob', data['dob']!));
        }
        if (data['roll_number'] != null) {
          formData.fields.add(MapEntry('roll_number', data['roll_number']!));
        }
        if (data['program'] != null) {
          formData.fields.add(MapEntry('program', data['program']!));
        }
        if (data['department'] != null) {
          formData.fields.add(MapEntry('department', data['department']!));
        }
        if (data['semester'] != null) {
          formData.fields.add(
            MapEntry('semester', data['semester'].toString()),
          );
        }
        if (data['batch_year'] != null) {
          formData.fields.add(MapEntry('batch_year', data['batch_year']!));
        }

        // Add profile picture file if changed
        if (_profilePicture != null &&
            _profilePicture!.isNotEmpty &&
            File(_profilePicture!).existsSync()) {
          final file = await MultipartFile.fromFile(
            _profilePicture!,
            filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          formData.files.add(MapEntry('profile_picture', file));
        }

        // Add gallery images (multiple files with same field name 'images')
        for (int i = 0; i < _gallery.length; i++) {
          final path = _gallery[i];
          if (path != null && path.isNotEmpty && File(path).existsSync()) {
            final file = await MultipartFile.fromFile(
              path,
              filename:
                  'gallery_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
            );
            formData.files.add(MapEntry('images', file));
          }
        }

        // Call the repository to update profile
        final result = await studentRepository.updateProfile(formData);

        if (result['status'] == 'success') {
          // Update the local state with the new profile data
          final studentStore = ref.read(studentStoreProvider.notifier);
          await studentStore.loadProfile();

          // Reset form state after successful save
          setState(() {
            _isFormDirty = false;
            _initialData = _getCurrentFormData();
          });

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result['message'] ?? 'Profile updated successfully',
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );

            Navigator.of(context).pop();
          }
        } else {
          // Show error message from backend
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to update profile'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        // Show generic error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        // // Hide loading state
        // if (mounted) {
        //   ref.read(studentStoreProvider.notifier).setUpdating(false);
        // }
      }
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
        _phoneCtrl.text = profile['phone'] ?? '';
        _rollCtrl.text = profile['roll_number']?.toString() ?? '';
        _batchYearCtrl.text = profile['batch_year']?.toString() ?? '';
        _semesterCtrl.text = profile['semester']?.toString() ?? '1';
        _program = profile['program'] ?? 'MCA';
        _department = profile['department'] ?? 'BTECH';
        _semester = profile['semester'] ?? 1;
        _profilePicture = profile['profile_picture'];

        // Populate gallery if available
        if (profile['gallery'] != null && profile['gallery'] is List) {
          final galleryList = profile['gallery'] as List;
          for (int i = 0; i < _gallery.length && i < galleryList.length; i++) {
            _gallery[i] = galleryList[i];
          }
        }

        // Parse and set DOB
        final dobString = profile['dob'];
        if (dobString != null) {
          _dob = DateTime.tryParse(dobString);
          if (_dob != null) {
            _dobCtrl.text = _formatDateForDisplay(_dob!);
          }
        }

        _initialDataLoaded = true;
        _initialData = _getCurrentFormData();
      });
    }
  }

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
      if (newDob != null) {
        _dobCtrl.text = _formatDateForDisplay(newDob);
      } else {
        _dobCtrl.clear();
      }
      _checkFormDirty();
    });
  }

  // Validation methods (optional since backend validates)
  String? _validateFirstName(String? value) {
    if (value != null && value.trim().isNotEmpty && value.trim().length < 2) {
      return 'First name must be at least 2 characters';
    }
    return null;
  }

  String? _validateLastName(String? value) {
    if (value != null && value.trim().isNotEmpty && value.trim().length < 2) {
      return 'Last name must be at least 2 characters';
    }
    return null;
  }

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
      if (cleaned.length != 10) {
        return 'Phone number must be 10 digits';
      }
      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
        return 'Please enter a valid phone number';
      }
    }
    return null;
  }

  String? _validateRollNumber(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (value.trim().length < 3) {
        return 'Roll number must be at least 3 characters';
      }
      if (int.tryParse(value.trim()) == null) {
        return 'Roll number must be a number';
      }
    }
    return null;
  }

  String? _validateBatchYear(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final year = int.tryParse(value.trim());
      if (year == null) {
        return 'Please enter a valid year';
      }
      final currentYear = DateTime.now().year;
      if (year < 2000 || year > currentYear + 1) {
        return 'Please enter a valid batch year';
      }
    }
    return null;
  }

  String? _validateSemester(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final semester = int.tryParse(value.trim());
      if (semester == null) {
        return 'Please enter a valid semester';
      }
      if (semester < 1 || semester > 12) {
        return 'Semester must be between 1 and 12';
      }
    }
    return null;
  }

  void _handleProgramChanged(String? value) {
    if (value != null) {
      setState(() {
        _program = value;
        _checkFormDirty();
      });
    }
  }

  void _handleDepartmentChanged(String? value) {
    if (value != null) {
      setState(() {
        _department = value;
        _checkFormDirty();
      });
    }
  }

  void _handleSemesterChanged(int? value) {
    if (value != null) {
      setState(() {
        _semester = value;
        _semesterCtrl.text = value.toString();
        _checkFormDirty();
      });
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.removeListener(_checkFormDirty);
    _middleNameCtrl.removeListener(_checkFormDirty);
    _lastNameCtrl.removeListener(_checkFormDirty);
    _emailCtrl.removeListener(_checkFormDirty);
    _phoneCtrl.removeListener(_checkFormDirty);
    _rollCtrl.removeListener(_checkFormDirty);
    _batchYearCtrl.removeListener(_checkFormDirty);
    _semesterCtrl.removeListener(_checkFormDirty);

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

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
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

    if (studentState.isLoading &&
        studentState.profile == null &&
        !_initialDataLoaded) {
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

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
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
        onPressed: () {
          if (_isFormDirty) {
            _showUnsavedChangesDialog();
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          if (_isFormDirty)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Unsaved',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      centerTitle: false,
    );
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
                Navigator.of(context).pop();
              },
              child: const Text('Leave', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildFormContent(StudentState studentState) {
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
        // onDobChanged: _handleDobChanged,
        // validateFirstName: _validateFirstName,
        // validateLastName: _validateLastName,
        // validateEmail: _validateEmail,
        // validatePhone: _validatePhone,
      ),
      const SizedBox(height: 24),
      _sectionHeader('ACADEMIC INFORMATION'),
      AcademicInfoSection(
        rollCtrl: _rollCtrl,
        batchYearCtrl: _batchYearCtrl,
        // semesterCtrl: _semesterCtrl,
        program: _program,
        department: _department,
        semester: _semester,
        onProgramChanged: _handleProgramChanged,
        onDepartmentChanged: _handleDepartmentChanged,
        onSemesterChanged: _handleSemesterChanged,
        cardDecoration: _cardDecoration,
        // validateRollNumber: _validateRollNumber,
        // validateBatchYear: _validateBatchYear,
        // validateSemester: _validateSemester,
      ),
      const SizedBox(height: 24),
      _sectionHeader('GALLERY'),
      StudentGallerySection(
        gallery: _gallery,
        onPickGalleryImage: _handleGalleryImagePicked,
        cardDecoration: _cardDecoration,
      ),
      const SizedBox(height: 32),
      SaveButtonSection(
        errorMessage: studentState.errorMessage,
        isUpdating: studentState.isUpdating,
        onSave: _updateProfile,
        onClearError: () =>
            ref.read(studentStoreProvider.notifier).clearError(),
        // isFormDirty: _isFormDirty,
      ),
      const SizedBox(height: 16),
    ];
  }

  String _formatDateForDisplay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
