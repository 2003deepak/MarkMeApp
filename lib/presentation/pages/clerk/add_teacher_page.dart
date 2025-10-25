import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/repositories/clerk_repository.dart';
import 'package:markmeapp/presentation/widgets/ui/dropdown.dart';
import 'package:markmeapp/presentation/widgets/ui/input_field.dart';

class AddTeacherPage extends ConsumerStatefulWidget {
  const AddTeacherPage({Key? key}) : super(key: key);

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
  List<Map<String, String?>> _subjectAssignments = [
    {'subject': null},
  ];

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

  Future<void> _fetchSubjects() async {
    setState(() {
      _isFetchingSubjects = true;
      _subjectsError = null;
    });

    try {
      final clerkRepo = ref.read(clerkRepositoryProvider);
      final result = await clerkRepo.fetchSubjects();

      if (result['success'] == true) {
        final subjectsData = result['data']['subjects'] as List<dynamic>;

        // Extract unique subjects by subject_code to avoid duplicates
        final uniqueSubjects = <String, Map<String, dynamic>>{};

        for (var subject in subjectsData) {
          final subjectCode = subject['subject_code'];
          final subjectName = subject['subject_name'];

          if (!uniqueSubjects.containsKey(subjectCode)) {
            uniqueSubjects[subjectCode] = {
              'subject_code': subjectCode,
              'subject_name': subjectName,
            };
          }
        }

        setState(() {
          _subjects = uniqueSubjects.values.toList();
        });
      } else {
        setState(() {
          _subjectsError = result['error'];
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
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
          onPressed: _isLoading ? null : () => context.go("/clerk"),
        ),
        title: const Text(
          'Add Teacher',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

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
                      return 'First name must be at least 2 characters long';
                    }
                    if (value.length > 50) {
                      return 'First name must be less than 50 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                      return 'First name can only contain letters and spaces';
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
                      return 'Last name must be at least 2 characters long';
                    }
                    if (value.length > 50) {
                      return 'Last name must be less than 50 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                      return 'Last name can only contain letters and spaces';
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

                const SizedBox(height: 20),

                // Subject Assignment Section
                _buildSubjectAssignmentSection(),

                const SizedBox(height: 20),

                // Save Button
                _buildSaveTeacherButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectAssignmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subject Assignment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        if (_isFetchingSubjects) _buildLoadingIndicator(),

        if (_subjectsError != null) _buildErrorWidget(),

        if (!_isFetchingSubjects && _subjectsError == null)
          _buildSubjectAssignmentsList(),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      children: [
        Text(
          'Failed to load subjects: $_subjectsError',
          style: const TextStyle(color: Colors.red),
        ),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: _fetchSubjects, child: const Text('Retry')),
      ],
    );
  }

  Widget _buildSubjectAssignmentsList() {
    return Column(
      children: [
        ListView.builder(
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
                  if (_subjectAssignments.length > 1)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _subjectAssignments.removeAt(index);
                        });
                        _updateFormState();
                      },
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade400,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _subjectAssignments.add({'subject': null});
            });
            _updateFormState();
          },
          icon: const Icon(Icons.add, color: Color(0xFF2563EB)),
          label: const Text(
            'Add More Subjects',
            style: TextStyle(color: Color(0xFF2563EB)),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectDropdown({
    String? value,
    required Function(String?) onChanged,
  }) {
    return Dropdown<String>(
      label: "Subject",
      hint: "Select Subject",
      items: _subjects
          .map((subject) => subject['subject_name'] as String)
          .toList(),
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
              : Colors.grey.shade400,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Save Teacher Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Future<void> _saveTeacherDetails() async {
    if (_formKey.currentState!.validate() && _isFormValid) {
      setState(() {
        _isLoading = true;
      });

      try {
        final clerkRepo = ref.read(clerkRepositoryProvider);

        // Get subject codes for selected subject names
        final subjectsAssigned = _subjectAssignments.map((assignment) {
          final subjectName = assignment['subject'];
          final subject = _subjects.firstWhere(
            (s) => s['subject_name'] == subjectName,
          );
          return subject['subject_code'] as String;
        }).toList();

        final teacherData = {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'email': _emailIdController.text.trim(),
          'mobile_number': _mobileNumberController.text.trim(),
          'subjects_assigned': subjectsAssigned,
        };

        print('Teacher Data: $teacherData');

        final result = await clerkRepo.createTeacher(teacherData);

        if (result['success'] == true) {
          // Show success snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Teacher created successfully!',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );

          // Navigate back to clerk page after a short delay
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            context.go('/clerk');
          }
        } else {
          // Show error snackbar from API response
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['error'] ?? 'Failed to create teacher',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (error) {
        // Show error snackbar for network/other errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save teacher: ${error.toString()}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
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
