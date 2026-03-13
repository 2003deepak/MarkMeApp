import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/presentation/widgets/ui/dropdown.dart';
import 'package:markmeapp/presentation/widgets/ui/input_field.dart';
import 'package:markmeapp/presentation/widgets/ui/snackbar.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';
import 'package:markmeapp/state/admin_state.dart';

class CreateProgramPage extends ConsumerStatefulWidget {
  const CreateProgramPage({super.key});

  @override
  ConsumerState<CreateProgramPage> createState() => _CreateProgramPageState();
}

class _CreateProgramPageState extends ConsumerState<CreateProgramPage> {
  final _formKey = GlobalKey<FormState>();
  final _programNameController = TextEditingController();
  final _programCodeController = TextEditingController();
  
  int? _selectedDuration;
  bool _isLoading = false;

  final List<int> _durations = [1, 2, 3, 4, 5];

  bool get _isFormValid {
    return _programNameController.text.isNotEmpty &&
        _programCodeController.text.isNotEmpty &&
        _selectedDuration != null;
  }

  @override
  void dispose() {
    _programNameController.dispose();
    _programCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveProgram() async {
    if (!_formKey.currentState!.validate() || !_isFormValid) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final result = await ref.read(adminStoreProvider.notifier).createProgram(
            fullName: _programNameController.text.trim(),
            programCode: _programCodeController.text.trim().toUpperCase(),
            durationYears: _selectedDuration!,
          );

      if (!mounted) return;

      if (result['success'] == true) {
        showSuccessSnackBar(context, result['message'] ?? 'Program created successfully!');
        context.pop();
      } else {
        showErrorSnackBar(
          context,
          result['error'] ?? 'Failed to create program',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: MarkMeAppBar(
        title: 'Create Program',
        onBackPressed: _isLoading ? null : () => context.pop(),
        isLoading: _isLoading,
      ),
      body: SafeArea(
        child: CustomScrollView(
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
                                    const Text(
                                      'Add New Program',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Define a new academic program like B.Tech or M.Tech',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF64748B),
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
                            const Text(
                              'Program Details',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 24),

                            InputField(
                              label: "Program Name",
                              hintText: "e.g. Bachelor of Technology",
                              controller: _programNameController,
                              isRequired: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Program name is required';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            InputField(
                              label: "Program Code",
                              hintText: "e.g. BTECH",
                              controller: _programCodeController,
                              isRequired: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Program code is required';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            Dropdown<int>(
                              label: "Duration (Years)",
                              hint: "Select Duration",
                              items: _durations,
                              value: _selectedDuration,
                              onChanged: (val) {
                                setState(() => _selectedDuration = val);
                              },
                              validator: (val) => val == null ? "Required" : null,
                              isRequired: true,
                              displayText: (val) => '$val ${val == 1 ? 'Year' : 'Years'}',
                            ),

                            const SizedBox(height: 32),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isFormValid && !_isLoading ? _saveProgram : null,
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
                                        'Create Program',
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
