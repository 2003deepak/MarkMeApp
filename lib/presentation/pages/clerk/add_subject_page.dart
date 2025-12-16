import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/repositories/clerk_repository.dart';
import 'package:markmeapp/presentation/widgets/ui/dropdown.dart';
import 'package:markmeapp/presentation/widgets/ui/input_field.dart';
import 'package:markmeapp/presentation/widgets/ui/snackbar.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';

class AddSubjectPage extends ConsumerStatefulWidget {
  const AddSubjectPage({super.key});

  @override
  ConsumerState<AddSubjectPage> createState() => _AddSubjectPageState();
}

class _AddSubjectPageState extends ConsumerState<AddSubjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectNameController = TextEditingController();
  final _subjectCodeController = TextEditingController();

  int? _selectedSemester;
  String? _selectedComponent;
  int? _selectedCredits;
  String? _selectedDepartment;
  String? _selectedProgram;
  bool _isLoading = false;

  final List<String> _semesters = List.generate(10, (i) => '${i + 1}');
  final List<String> _components = ['Lecture', 'Lab'];
  final List<int> _credits = [1, 2, 3, 4, 5, 6];
  final List<String> _departments = ['BTECH', 'MTECH', 'BSC', 'MBA'];
  final List<String> _programs = ['MCA', "AI"];

  bool get _isFormValid {
    return _subjectNameController.text.isNotEmpty &&
        _subjectCodeController.text.isNotEmpty &&
        _selectedSemester != null &&
        _selectedComponent != null &&
        _selectedCredits != null &&
        _selectedDepartment != null &&
        _selectedProgram != null;
  }

  @override
  void initState() {
    super.initState();
    // Set default values
    _selectedDepartment = _departments.first;
    _selectedProgram = _programs.first;
  }

  @override
  void dispose() {
    _subjectNameController.dispose();
    _subjectCodeController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _subjectNameController.clear();
    _subjectCodeController.clear();
    setState(() {
      _selectedSemester = null;
      _selectedComponent = null;
      _selectedCredits = null;
      _selectedDepartment = _departments.first;
      _selectedProgram = _programs.first;
    });
  }

  Future<void> _saveSubject() async {
    if (!_formKey.currentState!.validate() || !_isFormValid) return;

    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final clerkRepo = ref.read(clerkRepositoryProvider);

      final subjectData = {
        'subject_code': _subjectCodeController.text.trim().toUpperCase(),
        'subject_name': _subjectNameController.text.trim(),
        'semester': _selectedSemester,
        'component': _selectedComponent,
        'credit': _selectedCredits,
        'department': _selectedDepartment,
        'program': _selectedProgram,
      };

      final result = await clerkRepo.createSubject(subjectData);

      if (!mounted) return;

      if (result['success'] == true) {
        // Show success snackbar
        showSuccessSnackBar(context, 'Subject added successfully!');

        // Reset form after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        _resetForm();

        // Clear focus
        FocusScope.of(context).requestFocus(FocusNode());
      } else {
        showErrorSnackBar(
          context,
          '${result['error'] ?? 'Failed to add subject. Please try again.'}',
        );
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          'Error: ${error.toString().replaceAll("Exception: ", "")}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: MarkMeAppBar(
        title: 'Add New Subject',
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
                                  Icons.school_rounded,
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
                                      'Create New Subject',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Fill in all required fields to add a new subject',
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
                            // Section Title
                            Text(
                              'Subject Information',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter basic subject details',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Subject Name
                            InputField(
                              label: "Subject Name",
                              hintText: "Enter full subject name",
                              controller: _subjectNameController,
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Subject name is required';
                                }
                                if (value.length < 3) {
                                  return 'Must be at least 3 characters';
                                }
                                return null;
                              },
                              isRequired: true,
                              textInputAction: TextInputAction.next,
                            ),

                            const SizedBox(height: 20),

                            // Subject Code
                            InputField(
                              label: "Subject Code",
                              hintText: "e.g., CS101, MAT201",
                              controller: _subjectCodeController,
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Subject code is required';
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

                            // Semester & Credits Row
                            Row(
                              children: [
                                Expanded(
                                  child: Dropdown<String>(
                                    label: "Semester",
                                    hint: "Select Semester",
                                    items: _semesters,
                                    value: _selectedSemester?.toString(),
                                    onChanged: (val) {
                                      setState(
                                        () => _selectedSemester = int.tryParse(
                                          val ?? '',
                                        ),
                                      );
                                    },
                                    validator: (val) =>
                                        val == null ? "Required" : null,
                                    isRequired: true,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Dropdown<int>(
                                    label: "Credits",
                                    hint: "Select Credits",
                                    items: _credits,
                                    value: _selectedCredits,
                                    onChanged: (val) {
                                      setState(() => _selectedCredits = val);
                                    },
                                    validator: (val) =>
                                        val == null ? "Required" : null,
                                    isRequired: true,
                                    displayText: (val) => val.toString(),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Department & Program Row
                            Row(
                              children: [
                                Expanded(
                                  child: Dropdown<String>(
                                    label: "Department",
                                    hint: "Select Dept",
                                    items: _departments,
                                    value: _selectedDepartment,
                                    onChanged: (val) {
                                      setState(() => _selectedDepartment = val);
                                    },
                                    validator: (val) =>
                                        val == null ? "Required" : null,
                                    isRequired: true,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Dropdown<String>(
                                    label: "Program",
                                    hint: "Select Program",
                                    items: _programs,
                                    value: _selectedProgram,
                                    onChanged: (val) {
                                      setState(() => _selectedProgram = val);
                                    },
                                    validator: (val) =>
                                        val == null ? "Required" : null,
                                    isRequired: true,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Component Type
                            Dropdown<String>(
                              label: "Component Type",
                              hint: "Select Component",
                              items: _components,
                              value: _selectedComponent,
                              onChanged: (val) {
                                setState(() => _selectedComponent = val);
                              },
                              validator: (val) =>
                                  val == null ? "Required" : null,
                              isRequired: true,
                            ),

                            const SizedBox(height: 32),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isFormValid && !_isLoading
                                    ? _saveSubject
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isFormValid && !_isLoading
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFE2E8F0),
                                  foregroundColor: _isFormValid && !_isLoading
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
                                child: _isLoading
                                    ? SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white.withOpacity(0.9),
                                              ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(width: 10),
                                          Text(
                                            'Add Subject',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 16),
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
}
