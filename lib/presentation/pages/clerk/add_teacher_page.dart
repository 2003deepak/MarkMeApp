import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/repositories/clerk_repository.dart';
import 'package:markmeapp/presentation/widgets/ui/dropdown.dart';
import 'package:markmeapp/presentation/widgets/ui/input_field.dart';
import 'package:markmeapp/presentation/widgets/ui/snackbar.dart';
import 'package:markmeapp/core/utils/app_logger.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';

class AddTeacherPage extends ConsumerStatefulWidget {
  const AddTeacherPage({super.key});

  @override
  ConsumerState<AddTeacherPage> createState() => _AddTeacherPageState();
}

class _AddTeacherPageState extends ConsumerState<AddTeacherPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _emailIdController = TextEditingController();

  // Dynamic subject assignments
  final List<Map<String, String?>> _subjectAssignments = [];

  // Dynamic subjects from API
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = false;
  bool _isFetchingSubjects = true;
  String? _subjectsError;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
    // Add listeners to update button state
    _firstNameController.addListener(_updateFormState);
    _lastNameController.addListener(_updateFormState);
    _mobileNumberController.addListener(_updateFormState);
    _emailIdController.addListener(_updateFormState);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileNumberController.dispose();
    _emailIdController.dispose();
    super.dispose();
  }

  void _updateFormState() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isFormValid {
    return _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _mobileNumberController.text.isNotEmpty &&
        _emailIdController.text.isNotEmpty &&
        _subjectAssignments.isNotEmpty &&
        _subjectAssignments.every(
          (assignment) =>
              assignment['subject'] != null &&
              assignment['subject']!.isNotEmpty,
        ) &&
        !_isFetchingSubjects &&
        _subjectsError == null;
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _firstNameController.clear();
    _lastNameController.clear();
    _mobileNumberController.clear();
    _emailIdController.clear();
    setState(() {
      _subjectAssignments.clear();
    });
  }

  Future<void> _fetchSubjects() async {
    setState(() {
      _isFetchingSubjects = true;
      _subjectsError = null;
    });

    try {
      final clerkRepo = ref.read(clerkRepositoryProvider);
      final result = await clerkRepo.fetchSubjects(mode: 'subject_listing');

      if (result['success'] == true) {
        final subjectsData = result['data'] as List<dynamic>;

        // Transform data for UI
        final List<Map<String, dynamic>> processedSubjects = [];

        for (var subject in subjectsData) {
          final subjectId = subject['subject_id'];
          final subjectName = subject['subject_name'];
          final component = subject['component'];

          if (subjectId != null && subjectName != null) {
            processedSubjects.add({
              'id': subjectId,
              'name': subjectName,
              'component': component ?? '',
              'display': '$subjectName ($component)',
            });
          }
        }

        setState(() {
          _subjects = processedSubjects;
        });
      } else {
        setState(() {
          _subjectsError = result['error'] ?? 'Unknown error';
        });
      }
    } catch (error) {
      setState(() {
        _subjectsError = error.toString();
      });
    } finally {
      setState(() {
        _isFetchingSubjects = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: MarkMeAppBar(
        title: 'Add Teacher',
        onBackPressed: _isLoading ? null : () => context.go("/clerk"),
        isLoading: _isLoading,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    // Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFEFF6FF), Color(0xFFF0F9FF)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE0F2FE),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x0A3B82F6),
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person_add_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Add New Teacher',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Enter teacher details and assign subjects',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Form
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 20,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Teacher Information',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Personal details and contact info',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // First Name
                            InputField(
                              label: "First Name",
                              hintText: "Enter teacher's first name",
                              controller: _firstNameController,
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter first name';
                                }
                                if (value.length < 2) {
                                  return 'Must be at least 2 characters';
                                }
                                if (value.length > 50) {
                                  return 'Must be less than 50 characters';
                                }
                                if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                                  return 'Only letters and spaces allowed';
                                }
                                return null;
                              },
                              isRequired: true,
                              textInputAction: TextInputAction.next,
                            ),

                            const SizedBox(height: 20),

                            // Last Name
                            InputField(
                              label: "Last Name",
                              hintText: "Enter teacher's last name",
                              controller: _lastNameController,
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter last name';
                                }
                                if (value.length < 2) {
                                  return 'Must be at least 2 characters';
                                }
                                if (value.length > 50) {
                                  return 'Must be less than 50 characters';
                                }
                                if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                                  return 'Only letters and spaces allowed';
                                }
                                return null;
                              },
                              isRequired: true,
                              textInputAction: TextInputAction.next,
                            ),

                            const SizedBox(height: 20),

                            // Mobile Number
                            InputField(
                              label: "Mobile Number",
                              hintText: "Enter mobile number",
                              controller: _mobileNumberController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter mobile number';
                                }
                                if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                                  return 'Enter a valid 10-digit number';
                                }
                                return null;
                              },
                              isRequired: true,
                              textInputAction: TextInputAction.next,
                            ),

                            const SizedBox(height: 20),

                            // Email ID
                            InputField(
                              label: "Email ID",
                              hintText: "Enter teacher email",
                              controller: _emailIdController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter email ID';
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                              isRequired: true,
                              textInputAction: TextInputAction.next,
                            ),

                            const SizedBox(height: 32),

                            // Subject Assignment Section
                            _buildSubjectAssignmentSection(),

                            const SizedBox(height: 32),

                            // Save Button
                            _buildSaveTeacherButton(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectAssignmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subject Assignment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Assign subjects to teacher',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            if (!_isFetchingSubjects && _subjectsError == null)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _subjectAssignments.add({'subject': null});
                  });
                  _updateFormState();
                },
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add Subject'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isFetchingSubjects) _buildLoadingIndicator(),

        if (_subjectsError != null) _buildErrorWidget(),

        if (!_isFetchingSubjects && _subjectsError == null)
          _buildSubjectAssignmentsList(),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color(0xFF2563EB).withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to load subjects: $_subjectsError',
                  style: const TextStyle(
                    color: Color(0xFF991B1B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _fetchSubjects,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
              ),
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectAssignmentsList() {
    if (_subjectAssignments.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.library_books_outlined,
                size: 32,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'No subjects assigned yet',
                style: TextStyle(color: Colors.grey.shade500),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _subjectAssignments.add({'subject': null});
                  });
                  _updateFormState();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2563EB),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: const Text('Assign Subject'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _subjectAssignments.length,
      itemBuilder: (context, index) {
        final assignment = _subjectAssignments[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Expanded(
                child: _buildSubjectDropdown(
                  value: assignment['subject'],
                  onChanged: (newValue) {
                    setState(() {
                      assignment['subject'] = newValue;
                    });
                    _updateFormState();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(
                  top: 28,
                ), // Align with input field
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _subjectAssignments.removeAt(index);
                    });
                    _updateFormState();
                  },
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red.shade400,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubjectDropdown({
    String? value,
    required Function(String?) onChanged,
  }) {
    return Dropdown<String>(
      label: "Subject",
      hint: "Select Subject",
      items: _subjects.map((subject) => subject['display'] as String).toList(),
      value: value,
      onChanged: onChanged,
      validator: (val) => val == null ? "Please select subject" : null,
      isRequired: true,
    );
  }

  Widget _buildSaveTeacherButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isFormValid && !_isLoading ? _saveTeacherDetails : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFormValid && !_isLoading
              ? const Color(0xFF2563EB)
              : const Color(0xFFE2E8F0),
          foregroundColor: _isFormValid && !_isLoading
              ? Colors.white
              : const Color(0xFF94A3B8),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
          shadowColor: const Color(0x3D3B82F6),
          disabledBackgroundColor: const Color(0xFFF1F5F9),
        ),
        child: _isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.9),
                  ),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 10),
                  Text(
                    'Save Teacher Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _saveTeacherDetails() async {
    if (_formKey.currentState!.validate() && _isFormValid) {
      // Hide keyboard
      FocusScope.of(context).unfocus();

      setState(() {
        _isLoading = true;
      });

      try {
        final clerkRepo = ref.read(clerkRepositoryProvider);

        // Get subject IDs for selected subject assignments
        final subjectsAssigned = _subjectAssignments.map((assignment) {
          final displayString = assignment['subject'];
          final subject = _subjects.firstWhere(
            (s) => s['display'] == displayString,
          );
          return subject['id'] as String;
        }).toList();

        final teacherData = {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'email': _emailIdController.text.trim(),
          'mobile_number': _mobileNumberController.text.trim(),
          'subjects_assigned': subjectsAssigned,
        };

        AppLogger.info('Teacher Data: $teacherData');

        final result = await clerkRepo.createTeacher(teacherData);

        if (!mounted) return;

        if (result['success'] == true) {
          // Show success snackbar
          showSuccessSnackBar(context, 'Teacher created successfully!');

          // Reset form after a short delay
          await Future.delayed(const Duration(milliseconds: 500));
          _resetForm();

          // Clear focus
          FocusScope.of(context).requestFocus(FocusNode());
        } else {
          // Show error snackbar
          showErrorSnackBar(
            context,
            '${result['error'] ?? 'Failed to create teacher'}',
          );
        }
      } catch (error) {
        // Show error snackbar for network/other errors
        if (mounted) {
          showErrorSnackBar(
            context,
            'Failed to save teacher: ${error.toString()}',
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
