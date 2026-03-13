import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/models/user_model.dart';
import 'package:markmeapp/data/repositories/auth_repository.dart';
import 'package:markmeapp/presentation/widgets/ui/input_field.dart';
import 'package:markmeapp/presentation/widgets/ui/otp_field.dart';
import 'package:markmeapp/presentation/widgets/ui/snackbar.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';
import 'package:markmeapp/state/admin_state.dart';
import 'package:markmeapp/state/clerk_state.dart';
import 'package:markmeapp/presentation/widgets/ui/dropdown.dart';

class AddStudentPage extends ConsumerStatefulWidget {
  const AddStudentPage({super.key});

  @override
  ConsumerState<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends ConsumerState<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  String? _selectedProgram;
  String? _selectedDepartment;
  String? _selectedSemester;

  @override
  void initState() {
    super.initState();
    // Add listeners to update button state
    _firstNameController.addListener(_updateFormState);
    _lastNameController.addListener(_updateFormState);
    _emailController.addListener(_updateFormState);

    // Clerk profile should already be loaded
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _updateFormState() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isFormValid {
    final isEmailValid = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(_emailController.text.trim());

    return _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        isEmailValid &&
        _selectedProgram != null &&
        _selectedDepartment != null &&
        _selectedSemester != null;
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    setState(() {
      _selectedProgram = null;
      _selectedDepartment = null;
      _selectedSemester = null;
    });
  }

  Future<void> _registerStudent() async {
    if (_formKey.currentState!.validate() && _isFormValid) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authRepo = ref.read(authRepositoryProvider);

        final user = User(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim()
        );

        final result = await authRepo.registerUser(
          user,
          program: _selectedProgram,
          department: _selectedDepartment,
          semester: int.tryParse(_selectedSemester ?? ''),
        );

        if (!mounted) return;

        if (result['success'] == true) {
          showSuccessSnackBar(context, 'Student registered successfully!');
          await Future.delayed(const Duration(milliseconds: 500));
          _resetForm();
          FocusScope.of(context).requestFocus(FocusNode());
        } else {
          showErrorSnackBar(
            context,
            result['message'] ?? 'Failed to register student',
          );
        }
      } catch (e) {
        if (mounted) {
          showErrorSnackBar(context, 'An error occurred: $e');
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

  @override
  Widget build(BuildContext context) {
    final clerkState = ref.watch(clerkStoreProvider);
    final academicScopes = clerkState.profile?.academicScopes ?? [];

    final programItems = academicScopes.map((e) => e.programId).toSet().toList();
    
    List<String> departmentItems = [];
    if (_selectedProgram != null) {
      departmentItems = academicScopes
          .where((e) => e.programId == _selectedProgram)
          .map((e) => e.departmentId)
          .toSet()
          .toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: MarkMeAppBar(
        title: 'Add Student',
        onBackPressed: _isLoading ? null : () => context.go("/clerk"),
        isLoading: _isLoading,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
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
                                  Icons.person_add_alt_1_rounded,
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
                                      'Add New Student',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Enter student details to register',
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
                              'Student Information',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Personal details and credentials',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // First Name
                            InputField(
                              label: "First Name",
                              hintText: "Enter student's first name",
                              controller: _firstNameController,
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter first name';
                                }
                                if (value.length < 2) {
                                  return 'Must be at least 2 characters';
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
                              hintText: "Enter student's last name",
                              controller: _lastNameController,
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter last name';
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
                              hintText: "Enter student email",
                              controller: _emailController,
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

                            // Academic Information Header
                            const Text(
                              'Academic Information',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Program, Department and Semester details',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Program Dropdown
                            Dropdown(
                                label: "Program",
                                items: programItems,
                                value: _selectedProgram,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedProgram = value;
                                    _selectedDepartment = null;
                                    _selectedSemester = null;
                                  });
                                },
                                hint: "Select Program",
                              ),

                              const SizedBox(height: 20),

                              // Department Dropdown
                              Dropdown(
                                label: "Department",
                                items: departmentItems,
                                value: _selectedDepartment,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDepartment = value;
                                    _selectedSemester = null;
                                  });
                                },
                                hint: "Select Department",
                              ),

                              const SizedBox(height: 20),

                              // Semester Dropdown
                              Dropdown(
                                label: "Semester",
                                items: const ['1', '2', '3', '4', '5', '6', '7', '8'],
                                value: _selectedSemester,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSemester = value;
                                  });
                                },
                                hint: "Select Semester",
                              ),

                            const SizedBox(height: 32),
                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _isFormValid && !_isLoading
                                        ? _registerStudent
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _isFormValid && !_isLoading
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFFE2E8F0),
                                  foregroundColor:
                                      _isFormValid && !_isLoading
                                          ? Colors.white
                                          : const Color(0xFF94A3B8),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                  shadowColor: const Color(0x3D3B82F6),
                                  disabledBackgroundColor: const Color(
                                    0xFFF1F5F9,
                                  ),
                                ),
                                child:
                                    _isLoading
                                        ? SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<
                                                  Color
                                                >(
                                                  Colors.white.withOpacity(0.9),
                                                ),
                                          ),
                                        )
                                        : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(width: 10),
                                            Text(
                                              'Register Student',
                                              style: TextStyle(
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
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ]
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF475569),
      ),
    );
  }
}
