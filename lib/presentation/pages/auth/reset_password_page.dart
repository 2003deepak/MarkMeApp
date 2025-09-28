// lib/presentation/pages/reset_password_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:markmeapp/providers/auth_provider.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  final String email;
  final String role;

  const ResetPasswordPage({
    Key? key,
    required this.email,
    required this.role,
  }) : super(key: key);

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  final List<TextEditingController> _passwordControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _passwordFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  final List<TextEditingController> _confirmPasswordControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _confirmPasswordFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  bool _isOtpStep = true;
  int _countdown = 30;
  Timer? _timer;
  String _errorMessage = '';
  bool _passwordsMatch = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();

    // Add listeners to all password and confirm password controllers
    for (var controller in _passwordControllers) {
      controller.addListener(_validatePassword);
    }
    for (var controller in _confirmPasswordControllers) {
      controller.addListener(_validatePassword);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    for (var controller in _passwordControllers) {
      controller.dispose();
    }
    for (var focusNode in _passwordFocusNodes) {
      focusNode.dispose();
    }
    for (var controller in _confirmPasswordControllers) {
      controller.dispose();
    }
    for (var focusNode in _confirmPasswordFocusNodes) {
      focusNode.dispose();
    }
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

  void _validatePassword() {
    final password = _passwordControllers.map((c) => c.text).join();
    final confirmPassword = _confirmPasswordControllers.map((c) => c.text).join();

    setState(() {
      _passwordsMatch = password.isNotEmpty && password == confirmPassword;
    });
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1) {
      if (index < 5) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  void _onPasswordChanged(String value, int index, bool isPasswordField) {
    final controllers = isPasswordField
        ? _passwordControllers
        : _confirmPasswordControllers;
    final focusNodes = isPasswordField
        ? _passwordFocusNodes
        : _confirmPasswordFocusNodes;

    if (value.length == 1) {
      if (index < 5) {
        focusNodes[index + 1].requestFocus();
      } else {
        focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length == 6) {
      setState(() {
        _errorMessage = '';
      });

      final authNotifier = ref.read(authStoreProvider.notifier);
      final success = await authNotifier.verifyOtp(
        widget.email,
        widget.role.toLowerCase(),
        otp,
        context,
      );

      if (success && mounted) {
        setState(() {
          _isOtpStep = false;
        });
      } else if (mounted) {
        final error = ref.read(authErrorProvider);
        setState(() {
          _errorMessage = error ?? 'OTP verification failed';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Please enter complete 6-digit OTP';
      });
    }
  }

  Future<void> _resetPassword() async {
    final password = _passwordControllers.map((c) => c.text).join();
    final confirmPassword = _confirmPasswordControllers.map((c) => c.text).join();

    if (password.length == 6 && confirmPassword.length == 6 && _passwordsMatch) {
      setState(() {
        _errorMessage = '';
      });

      final authNotifier = ref.read(authStoreProvider.notifier);
      final success = await authNotifier.resetPassword(
        widget.email,
        widget.role.toLowerCase(),
        password,
        context,
      );

      if (success && mounted) {
        _showSuccessDialog();
      } else if (mounted) {
        final error = ref.read(authErrorProvider);
        setState(() {
          _errorMessage = error ?? 'Password reset failed';
        });
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
  }

  Widget _buildOtpInput() {
    final isLoading = ref.watch(authLoadingProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF4A90E2).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_reset, color: Color(0xFF4A90E2), size: 40),
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

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return Container(
              width: 50,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                keyboardType: TextInputType.number,
                maxLength: 1,
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => _onOtpChanged(value, index),
              ),
            );
          }),
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
                onTap: _resendOtp,
                child: const Text(
                  'Resend',
                  style: TextStyle(
                    color: Color(0xFF4A90E2),
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
            onPressed: isLoading ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
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
    final isLoading = ref.watch(authLoadingProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF4A90E2).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_outline, color: Color(0xFF4A90E2), size: 40),
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

        const Text(
          'New PIN',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return Container(
              width: 50,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: TextField(
                controller: _passwordControllers[index],
                focusNode: _passwordFocusNodes[index],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                keyboardType: TextInputType.number,
                maxLength: 1,
                obscureText: true,
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => _onPasswordChanged(value, index, true),
              ),
            );
          }),
        ),

        const SizedBox(height: 20),
        const Text(
          'Confirm PIN',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return Container(
              width: 50,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: TextField(
                controller: _confirmPasswordControllers[index],
                focusNode: _confirmPasswordFocusNodes[index],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                keyboardType: TextInputType.number,
                maxLength: 1,
                obscureText: true,
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => _onPasswordChanged(value, index, false),
              ),
            );
          }),
        ),

        const SizedBox(height: 24),
        _buildValidationItem('PINs match', _passwordsMatch),

        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
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

  Widget _buildValidationItem(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.cancel,
            color: isValid ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isValid ? Colors.green : Colors.red,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch for error messages from auth state
    final errorMessage = ref.watch(authErrorProvider);
    
    // Show error message if any from auth state
    if (errorMessage != null && errorMessage.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _errorMessage = errorMessage;
          });
          // Clear error after showing
          ref.read(authStoreProvider.notifier).clearError();
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
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
      ),
    );
  }
}