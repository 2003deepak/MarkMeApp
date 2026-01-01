import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/state/auth_state.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';
import 'package:markmeapp/presentation/widgets/ui/input_field.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _selectedRole = 'Student';
  bool _isLoading = false;

  final List<String> _roles = ['Student', 'Clerk', 'Admin', 'Teacher'];

  // Constants for styling
  static const _primaryColor = Color(0xFF2563EB);
  static const _backgroundColor = Color(0xFFF5F7FA);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _sendResetLink() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authStore = ref.read(authStoreProvider.notifier);
        final response = await authStore.forgotPassword(
          _emailController.text.trim(),
          _selectedRole.toLowerCase(),
        );

        // Fixed: Check specifically for success boolean
        if (response['success'] == true) {
          _showSnackBar(
            response['message'] ?? 'OTP sent successfully to your email',
          );

          // Navigate to reset password page after a short delay
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              context.go(
                '/reset-password',
                extra: {
                  'email': _emailController.text.trim(),
                  'role': _selectedRole.toLowerCase(),
                },
              );
            }
          });
        } else {
          _showSnackBar(
            response['message'] ?? 'Failed to send OTP',
            isError: true,
          );
        }
      } catch (e) {
        _showSnackBar('An error occurred. Please try again.', isError: true);
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
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: MarkMeAppBar(
        title: 'Forgot Password',
        onBackPressed: () => context.go('/login'),
        isLoading: _isLoading,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 24),
              _buildFormContainer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.lock_reset, size: 40, color: _primaryColor),
          ),
          const SizedBox(height: 20),
          const Text(
            'Reset Password',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Enter your email address and select your role.\nWe\'ll send you an OTP to reset your password.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContainer() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            InputField(
              label: 'Email Address',
              controller: _emailController,
              hintText: 'Enter your email address',
              keyboardType: TextInputType.emailAddress,
              isRequired: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Role',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                    Text(
                      '*',
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      elevation: 16,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                      onChanged: _isLoading
                          ? null
                          : (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedRole = newValue;
                                });
                              }
                            },
                      items: _roles.map<DropdownMenuItem<String>>((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendResetLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.blue.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Send OTP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _isLoading ? null : () => context.go('/login'),
              child: Text(
                'Back to Login',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
