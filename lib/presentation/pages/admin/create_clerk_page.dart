import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/presentation/widgets/ui/dropdown.dart';
import 'package:markmeapp/presentation/widgets/ui/input_field.dart';
import 'package:markmeapp/presentation/widgets/ui/snackbar.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';
import 'package:markmeapp/state/admin_state.dart';

class CreateClerkPage extends ConsumerStatefulWidget {
  const CreateClerkPage({super.key});

  @override
  ConsumerState<CreateClerkPage> createState() => _CreateClerkPageState();
}

class AcademicScope {
  String? program;
  String? department;

  AcademicScope({this.program, this.department});

  Map<String, String> toJson() => {
        'program_id': program ?? '',
        'department_id': department ?? '',
      };
}

class _CreateClerkPageState extends ConsumerState<CreateClerkPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();

  final List<AcademicScope> _academicScopes = [AcademicScope()];
  
  bool _isLoading = false;
  bool _isFetchingMetadata = true;
  Map<String, dynamic> _hierarchyData = {};

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    setState(() => _isFetchingMetadata = true);
    final result = await ref.read(adminStoreProvider.notifier).fetchHierarchicalMetadata();
    
    if (mounted) {
      setState(() {
        _isFetchingMetadata = false;
        if (result['success'] == true) {
          _hierarchyData = result['data'] ?? {};
        }
      });
    }
  }

  bool get _isFormValid {
    return _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _mobileController.text.isNotEmpty &&
        _academicScopes.isNotEmpty &&
        _academicScopes.every((s) => s.program != null && s.department != null);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _addScope() {
    setState(() {
      _academicScopes.add(AcademicScope());
    });
  }

  void _removeScope(int index) {
    if (_academicScopes.length > 1) {
      setState(() {
        _academicScopes.removeAt(index);
      });
    } else {
      showErrorSnackBar(context, 'At least one academic scope is required');
    }
  }

  Future<void> _saveClerk() async {
    if (!_formKey.currentState!.validate() || !_isFormValid) return;

    // Check for duplicate scopes
    final scopeKeys = _academicScopes.map((s) => '${s.program}+${s.department}').toList();
    if (scopeKeys.length != scopeKeys.toSet().length) {
      showErrorSnackBar(context, 'Duplicate academic scopes are not allowed');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final result = await ref.read(adminStoreProvider.notifier).createClerk(
            firstName: _firstNameController.text.trim(),
            middleName: _middleNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: _emailController.text.trim(),
            mobileNumber: int.parse(_mobileController.text.trim()),
            academicScopes: _academicScopes.map((s) => s.toJson()).toList(),
          );

      if (!mounted) return;

      if (result['success'] == true) {
        showSuccessSnackBar(context, result['message'] ?? 'Clerk created successfully!');
        _resetForm();
        context.pop();
      } else {
        showErrorSnackBar(
          context,
          result['error'] ?? 'Failed to create clerk',
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    _firstNameController.clear();
    _middleNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _mobileController.clear();
    _academicScopes.clear();
    _academicScopes.add(AcademicScope());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<String> programs = _hierarchyData.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: MarkMeAppBar(
        title: 'Create Clerk',
        onBackPressed: _isLoading ? null : () => context.pop(),
        isLoading: _isLoading,
      ),
      body: SafeArea(
        child: _isFetchingMetadata
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                            child: Row(
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
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Register Clerk',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Create a new clerk account for institutional management',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
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
                                  InputField(
                                    label: "First Name",
                                    hintText: "Enter first name",
                                    controller: _firstNameController,
                                    isRequired: true,
                                    validator: (val) => val == null || val.isEmpty ? "Required" : null,
                                  ),
                                  const SizedBox(height: 20),
                                  InputField(
                                    label: "Middle Name",
                                    hintText: "Enter middle name",
                                    controller: _middleNameController,
                                  ),
                                  const SizedBox(height: 20),
                                  InputField(
                                    label: "Last Name",
                                    hintText: "Enter last name",
                                    controller: _lastNameController,
                                    isRequired: true,
                                    validator: (val) => val == null || val.isEmpty ? "Required" : null,
                                  ),
                                  const SizedBox(height: 20),
                                  InputField(
                                    label: "Email Address",
                                    hintText: "clerk@example.com",
                                    controller: _emailController,
                                    isRequired: true,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (val) {
                                      if (val == null || val.isEmpty) return "Required";
                                      if (!val.contains('@')) return "Invalid email";
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  InputField(
                                    label: "Mobile Number",
                                    hintText: "Enter 10 digit number",
                                    controller: _mobileController,
                                    isRequired: true,
                                    keyboardType: TextInputType.phone,
                                    validator: (val) {
                                      if (val == null || val.isEmpty) return "Required";
                                      if (val.length < 10) return "Invalid number";
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 32),

                                  // Academic Scopes Section
                                  const Row(
                                    children: [
                                      Icon(Icons.school_outlined, size: 20, color: Color(0xFF2563EB)),
                                      SizedBox(width: 8),
                                      Text(
                                        "Academic Scopes",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _academicScopes.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 20),
                                    itemBuilder: (context, index) {
                                      final scope = _academicScopes[index];
                                      final List<String> departments = scope.program != null
                                          ? (_hierarchyData[scope.program] as Map<String, dynamic>?)?.keys.toList() ?? []
                                          : [];

                                      return Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  "Scope #${index + 1}",
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                                if (_academicScopes.length > 1)
                                                  IconButton(
                                                    onPressed: () => _removeScope(index),
                                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Dropdown<String>(
                                              label: "Program",
                                              hint: "Select Program",
                                              items: programs,
                                              value: scope.program,
                                              onChanged: (val) {
                                                setState(() {
                                                  scope.program = val;
                                                  scope.department = null;
                                                });
                                              },
                                              isRequired: true,
                                              validator: (val) => val == null ? "Required" : null,
                                            ),
                                            const SizedBox(height: 16),
                                            Dropdown<String>(
                                              label: "Department",
                                              hint: "Select Department",
                                              items: departments,
                                              value: scope.department,
                                              onChanged: (val) {
                                                setState(() => scope.department = val);
                                              },
                                              isRequired: true,
                                              validator: (val) => val == null ? "Required" : null,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  OutlinedButton.icon(
                                    onPressed: _addScope,
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    label: const Text("Add Academic Scope"),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF2563EB),
                                      side: const BorderSide(color: Color(0xFF3B82F6)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),

                                  const SizedBox(height: 40),

                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isFormValid && !_isLoading ? _saveClerk : null,
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
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              'Create Clerk Account',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
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
                ],
              ),
      ),
    );
  }
}
