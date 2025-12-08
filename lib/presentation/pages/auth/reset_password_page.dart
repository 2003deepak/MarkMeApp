import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/state/auth_state.dart';
import 'package:markmeapp/presentation/widgets/ui/otp_field.dart';
import 'dart:async';

class ResetPasswordPage extends ConsumerStatefulWidget {
  final String email;
  final String role;

  const ResetPasswordPage({super.key, required this.email, required this.role});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  String _enteredOtp = '';
  String _newPassword = '';
  String _confirmPassword = '';

  bool _isOtpStep = true;
  int _countdown = 30;
  Timer? _timer;
  String _errorMessage = '';
  bool _passwordsMatch = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
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

  void _onOtpCompleted(String otp) {
    setState(() {
      _enteredOtp = otp;
    });
    debugPrint('✅ OTP Entered: $otp');
  }

  void _onNewPasswordCompleted(String password) {
    setState(() {
      _newPassword = password;
    });
    _validatePasswords();
    debugPrint('✅ New Password Entered: $password');
  }

  void _onConfirmPasswordCompleted(String password) {
    setState(() {
      _confirmPassword = password;
    });
    _validatePasswords();
    debugPrint('✅ Confirm Password Entered: $password');
  }

  void _validatePasswords() {
    setState(() {
      _passwordsMatch =
          _newPassword.isNotEmpty &&
          _confirmPassword.isNotEmpty &&
          _newPassword == _confirmPassword;
    });
  }

  Future<void> _verifyOtp() async {
    if (_enteredOtp.length == 6) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final authNotifier = ref.read(authStoreProvider.notifier);
        final response = await authNotifier.verifyOtp(
          widget.email,
          widget.role.toLowerCase(),
          _enteredOtp,
          context,
        );

        if (response['status'] == 'success') {
          _showSnackBar(response['message'] ?? 'OTP verified successfully');
          if (mounted) {
            setState(() {
              _isOtpStep = false;
              _isLoading = false;
            });
          }
        } else {
          _showSnackBar(
            response['message'] ?? 'OTP verification failed',
            isError: true,
          );
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        _showSnackBar('An error occurred. Please try again.', isError: true);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _errorMessage = 'Please enter complete 6-digit OTP';
      });
    }
  }

  Future<void> _resetPassword() async {
    if (_newPassword.length == 6 &&
        _confirmPassword.length == 6 &&
        _passwordsMatch) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final authNotifier = ref.read(authStoreProvider.notifier);
        final response = await authNotifier.resetPassword(
          widget.email,
          widget.role.toLowerCase(),
          _newPassword,
          context,
        );

        if (response['status'] == 'success') {
          _showSnackBar(response['message'] ?? 'Password reset successfully');
          _showSuccessDialog();
        } else {
          _showSnackBar(
            response['message'] ?? 'Password reset failed',
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
    } else {
      setState(() {
        _errorMessage = 'Please ensure both PINs are 6 digits and match';
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.green, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'PIN Reset Successful!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your PIN has been successfully reset. You can now login with your new PIN.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _resendOtp() {
    setState(() {
      _countdown = 30;
      _errorMessage = '';
    });
    _startCountdown();

    // Call the forgot password API again to resend OTP
    final authNotifier = ref.read(authStoreProvider.notifier);
    authNotifier
        .forgotPassword(widget.email, widget.role.toLowerCase(), context)
        .then((response) {
          if (response['status'] == 'success') {
            _showSnackBar('OTP resent successfully');
          } else {
            _showSnackBar('Failed to resend OTP', isError: true);
          }
        });
  }

  Widget _buildOtpInput() {
    final primaryColor = Colors.blue.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.lock_reset, color: primaryColor, size: 40),
        ),
        const SizedBox(height: 32),
        const Text(
          'Enter OTP',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We\'ve sent a 6-digit OTP to ${widget.email}. Please enter it below to reset your PIN.',
          style: TextStyle(color: Colors.grey[600], fontSize: 16, height: 1.4),
        ),
        const SizedBox(height: 32),

        // OTP Field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter OTP',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            OTPField(
              onCompleted: _onOtpCompleted,
              autoFocus: false,
              borderColor: Colors.grey.shade400,
              focusedBorderColor: primaryColor,
              cursorColor: primaryColor,
              fieldWidth: 50,
              fieldHeight: 60,
              borderRadius: BorderRadius.circular(12),
            ),
            if (_enteredOtp.isNotEmpty && _enteredOtp.length == 6)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'OTP entered successfully',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _countdown > 0
                  ? 'Resend OTP in ${_countdown}s'
                  : 'Didn\'t receive OTP?',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (_countdown == 0) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isLoading ? null : _resendOtp,
                child: Text(
                  'Resend',
                  style: TextStyle(
                    color: _isLoading ? Colors.grey : primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_enteredOtp.length == 6 && !_isLoading)
                ? _verifyOtp
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Verify OTP',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordReset() {
    final primaryColor = Colors.blue.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.lock_outline, color: primaryColor, size: 40),
        ),
        const SizedBox(height: 32),
        const Text(
          'Create New PIN',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Please create a 6-digit PIN that you will remember.',
          style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.4),
        ),
        const SizedBox(height: 32),

        // New Password Field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New PIN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            OTPField(
              onCompleted: _onNewPasswordCompleted,
              autoFocus: false,
              borderColor: Colors.grey.shade400,
              focusedBorderColor: primaryColor,
              cursorColor: primaryColor,
              fieldWidth: 50,
              fieldHeight: 60,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Confirm Password Field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm PIN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            OTPField(
              onCompleted: _onConfirmPasswordCompleted,
              autoFocus: false,
              borderColor: Colors.grey.shade400,
              focusedBorderColor: primaryColor,
              cursorColor: primaryColor,
              fieldWidth: 50,
              fieldHeight: 60,
              borderRadius: BorderRadius.circular(12),
            ),
            if (_newPassword.isNotEmpty && _confirmPassword.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(
                      _passwordsMatch ? Icons.check_circle : Icons.cancel,
                      color: _passwordsMatch
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _passwordsMatch ? 'PINs match' : 'PINs do not match',
                      style: TextStyle(
                        fontSize: 13,
                        color: _passwordsMatch
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_passwordsMatch && !_isLoading) ? _resetPassword : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Reset PIN',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isOtpStep ? 'Verify OTP' : 'Reset PIN'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _isOtpStep ? _buildOtpInput() : _buildPasswordReset(),

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: () => context.go('/login'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Back to Login page',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
