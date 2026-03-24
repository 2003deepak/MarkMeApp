import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/repositories/clerk_repository.dart';
import 'package:markmeapp/presentation/widgets/ui/dropdown.dart';
import 'package:markmeapp/presentation/widgets/ui/input_field.dart';
import 'package:markmeapp/presentation/widgets/ui/snackbar.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';
import 'package:markmeapp/state/clerk_state.dart';

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

  List<String> _semesters = [];
  final List<String> _components = ['Lecture', 'Lab'];
  final List<int> _credits = [1, 2, 3, 4, 5, 6];
  List<String> _departments = [];
  List<String> _programs = [];

  //form change listener
  void _onFormChanged() {
    setState(() {});
  }

  bool get _isFormValid {
    print("Form changed!");

    print("Subject Name: ${_subjectNameController.text}");
    print("Subject Code: ${_subjectCodeController.text}");
    print("Selected Semester: $_selectedSemester");
    print("Selected Component: $_selectedComponent");
    print("Selected Credits: $_selectedCredits");
    print("Selected Department: $_selectedDepartment");
    print("Selected Program: $_selectedProgram");

    bool a =  _subjectNameController.text.isNotEmpty &&
        _subjectCodeController.text.isNotEmpty &&
        _selectedSemester != null &&
        _selectedComponent != null &&
        _selectedCredits != null &&
        _selectedDepartment != null &&
        _selectedProgram != null;

    print("Form is valid: $a");
    return a;
  }

  @override
  void initState() {
    super.initState();

    // Clerk profile should already be loaded

    //listen to text changes
    _subjectNameController.addListener(_onFormChanged);
    _subjectCodeController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    //remove listeners
    _subjectNameController.removeListener(_onFormChanged);
    _subjectCodeController.removeListener(_onFormChanged);

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
      _selectedDepartment = null;
      _selectedProgram = null;
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
        showSuccessSnackBar(context, '${result['message']}');

        // Reset form after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        _resetForm();

        // Clear focus
        if (mounted) {
          FocusScope.of(context).requestFocus(FocusNode());
        }
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
    final clerkState = ref.watch(clerkStoreProvider);
    final academicScopes = clerkState.profile?.academicScopes ?? [];
    
    _programs = academicScopes.map((e) => e.programId).toSet().toList();
    
    if (_selectedProgram != null) {
      _departments = academicScopes
          .where((e) => e.programId == _selectedProgram)
          .map((e) => e.departmentId)
          .toSet()
          .toList();
      
      if (_selectedDepartment != null) {
        // Default to 8 semesters since exact duration is not in profile
        _semesters = List.generate(8, (i) => (i + 1).toString());
      } else {
        _semesters = [];
      }
    } else {
      _departments = [];
      _semesters = [];
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: MarkMeAppBar(
        title: 'Add New Subject',
        onBackPressed: _isLoading ? null : () => context.pop(),
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
                            // Section: Academic Details
                            const Text(
                              'Academic Details',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 24),

                            Dropdown<String>(
                              label: "Program",
                              hint: "Select Program",
                              items: _programs,
                              value: _selectedProgram,
                              onChanged: (val) {
                                setState(() {
                                  _selectedProgram = val;
                                  _selectedDepartment = null;
                                  _selectedSemester = null;
                                });
                              },
                              validator: (val) => val == null ? "Required" : null,
                              isRequired: true,
                            ),

                            const SizedBox(height: 20),

                            Dropdown<String>(
                              label: "Department",
                              hint: "Select Department",
                              items: _departments,
                              value: _selectedDepartment,
                              onChanged: (val) {
                                setState(() {
                                  _selectedDepartment = val;
                                  _selectedSemester = null;
                                });
                              },
                              validator: (val) => val == null ? "Required" : null,
                              isRequired: true,
                            ),

                            const SizedBox(height: 20),

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
                                        () => _selectedSemester = int.tryParse(val ?? ''),
                                      );
                                    },
                                    validator: (val) => val == null ? "Required" : null,
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
                                    validator: (val) => val == null ? "Required" : null,
                                    isRequired: true,
                                    displayText: (val) => val.toString(),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),
                            const Divider(),
                            const SizedBox(height: 32),

                            // Section: Subject Details
                            const Text(
                              'Subject Information',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 24),

                            InputField(
                              label: "Subject Name",
                              hintText: "Enter full subject name",
                              controller: _subjectNameController,
                              isRequired: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                if (value.length < 3) return 'Too short';
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            InputField(
                              label: "Subject Code",
                              hintText: "e.g., CS101",
                              controller: _subjectCodeController,
                              isRequired: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            Dropdown<String>(
                              label: "Component Type",
                              hint: "Select Component",
                              items: _components,
                              value: _selectedComponent,
                              onChanged: (val) {
                                setState(() => _selectedComponent = val);
                              },
                              validator: (val) => val == null ? "Required" : null,
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
