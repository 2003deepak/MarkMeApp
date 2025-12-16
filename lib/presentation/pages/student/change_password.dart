import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/repositories/auth_repository.dart';
import 'package:markmeapp/presentation/widgets/ui/input_field.dart';
import 'package:markmeapp/presentation/widgets/ui/snackbar.dart';
import 'package:markmeapp/core/utils/app_logger.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add listeners to update button state
    _currentPasswordController.addListener(_updateFormState);
    _newPasswordController.addListener(_updateFormState);
    _confirmPasswordController.addListener(_updateFormState);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updateFormState() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isFormValid {
    return _currentPasswordController.text.length == 6 &&
        _newPasswordController.text.length == 6 &&
        _confirmPasswordController.text.length == 6 &&
        _newPasswordController.text == _confirmPasswordController.text;
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate() || !_isFormValid) return;

    // Unfocus keyboard
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);

      final result = await authRepo.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      AppLogger.info(result.toString());

      if (!mounted) return;

      if (result['success'] == true) {
        showSuccessSnackBar(
          context,
          result['message'] ?? 'Password changed successfully!',
        );
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) context.go('/student/profile');
      } else {
        showErrorSnackBar(
          context,
          result['error'] ?? 'Failed to change password',
        );
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          'Failed to change password: ${error.toString()}',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleBackPress() {
    context.go("/student/profile");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: MarkMeAppBar(
        title: 'Change Password',
        onBackPressed: _isLoading ? null : _handleBackPress,
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
                                  Icons.lock_reset_rounded,
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
                                      'Update Password',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Secure your account with a new password',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
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

                    // Form Container
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
                              'Password Details',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter your current and new password',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Current Password
                            InputField(
                              label: "Current Password",
                              hintText: "Enter 6-digit current password",
                              controller: _currentPasswordController,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              maxLength: 6,
                              showCounter: false,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter current password';
                                }
                                if (value.length != 6) {
                                  return 'Must be exactly 6 digits';
                                }
                                return null;
                              },
                              isRequired: true,
                              textInputAction: TextInputAction.next,
                            ),

                            const SizedBox(height: 20),

                            // New Password
                            InputField(
                              label: "New Password",
                              hintText: "Enter 6-digit new password",
                              controller: _newPasswordController,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              maxLength: 6,
                              showCounter: false,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter new password';
                                }
                                if (value.length != 6) {
                                  return 'Must be exactly 6 digits';
                                }
                                return null;
                              },
                              isRequired: true,
                              textInputAction: TextInputAction.next,
                            ),

                            const SizedBox(height: 20),

                            // Confirm Password
                            InputField(
                              label: "Confirm Password",
                              hintText: "Re-enter new password",
                              controller: _confirmPasswordController,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              maxLength: 6,
                              showCounter: false,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm new password';
                                }
                                if (value != _newPasswordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                              isRequired: true,
                              textInputAction: TextInputAction.done,
                            ),

                            const SizedBox(height: 32),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _changePassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
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
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(width: 10),
                                          Text(
                                            'Change Password',
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
