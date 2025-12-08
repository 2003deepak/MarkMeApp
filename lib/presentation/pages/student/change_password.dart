import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/repositories/auth_repository.dart';
import 'package:markmeapp/presentation/widgets/ui/otp_field.dart';
import 'package:markmeapp/core/utils/app_logger.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final Color primaryColor = const Color(0xFF2563EB);
  final bool isDesktop = false;

  String _currentPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';
  bool _isLoading = false;

  void _onCurrentPasswordCompleted(String value) {
    setState(() => _currentPassword = value);
  }

  void _onNewPasswordCompleted(String value) {
    setState(() => _newPassword = value);
  }

  void _onConfirmPasswordCompleted(String value) {
    setState(() => _confirmPassword = value);
  }

  bool get _isFormValid {
    return _currentPassword.length == 6 &&
        _newPassword.length == 6 &&
        _confirmPassword.length == 6 &&
        _newPassword == _confirmPassword;
  }

  Future<void> _changePassword() async {
    if (!_isFormValid) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);

      final result = await authRepo.changePassword(
        _currentPassword,
        _newPassword,
      );

      AppLogger.info(result.toString());

      if (!mounted) return;

      if (result['success'] == true) {
        _showSuccessSnackBar(
          result['message'] ?? 'Password changed successfully!',
        );
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) context.go('/student/profile');
      } else {
        _showErrorSnackBar(result['error'] ?? 'Failed to change password');
      }
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Failed to change password: ${error.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleBackPress() {
    context.go("/student/profile");
  }

  Widget _buildPasswordOTPField({
    required String label,
    required Function(String) onCompleted,
    required String currentValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        OTPField(
          onCompleted: onCompleted,
          autoFocus: false,
          borderColor: Colors.grey.shade300,
          focusedBorderColor: primaryColor,
          cursorColor: primaryColor,
          fieldWidth: isDesktop ? 55 : 50,
          fieldHeight: isDesktop ? 65 : 60,
          borderRadius: BorderRadius.circular(12),
        ),
        if (currentValue.isNotEmpty && currentValue.length != 6)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(
              'Password must be exactly 6 digits',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 4,
        shadowColor: Colors.blue.shade900.withAlpha(77), // 0.3
        leading: IconButton(
          onPressed: _handleBackPress,
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51), // 0.2
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                const SizedBox(height: 8),

                // Current Password
                _buildPasswordOTPField(
                  label: 'Current Password',
                  onCompleted: _onCurrentPasswordCompleted,
                  currentValue: _currentPassword,
                ),
                const SizedBox(height: 20),

                // New Password
                _buildPasswordOTPField(
                  label: 'New Password',
                  onCompleted: _onNewPasswordCompleted,
                  currentValue: _newPassword,
                ),
                const SizedBox(height: 20),

                // Confirm Password
                _buildPasswordOTPField(
                  label: 'Confirm Password',
                  onCompleted: _onConfirmPasswordCompleted,
                  currentValue: _confirmPassword,
                ),

                // Validation messages
                if (_newPassword.isNotEmpty &&
                    _confirmPassword.isNotEmpty &&
                    _newPassword != _confirmPassword)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Passwords do not match',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_newPassword.isNotEmpty &&
                    _confirmPassword.isNotEmpty &&
                    _newPassword == _confirmPassword &&
                    _newPassword.length == 6)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Passwords match',
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Submit Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _isFormValid && !_isLoading
                        ? [
                            BoxShadow(
                              color: primaryColor.withAlpha(77), // 0.3
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : [],
                  ),
                  child: ElevatedButton(
                    onPressed: _isFormValid && !_isLoading
                        ? _changePassword
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid && !_isLoading
                          ? primaryColor
                          : Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
