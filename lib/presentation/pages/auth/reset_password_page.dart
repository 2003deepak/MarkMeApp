import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:markmeapp/presentation/state/auth_provider.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String role;

  const ResetPasswordPage({Key? key, required this.email, required this.role})
    : super(key: key);

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
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
  bool _isLoading = false;
  int _countdown = 30;
  Timer? _timer;
  String _errorMessage = '';

  // Password validation states
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
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
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
    final confirmPassword = _confirmPasswordControllers
        .map((c) => c.text)
        .join();

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

  void _verifyOtp() async {
    String otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length == 6) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.verifyOtp(
          widget.email,
          widget.role.toLowerCase(),
          otp,
          context,
        );

        if (success) {
          setState(() {
            _isLoading = false;
            _isOtpStep = false; // Switch to password reset UI
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage =
                authProvider.errorMessage ?? 'OTP verification failed';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error verifying OTP: $e';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Please enter complete 6-digit OTP';
      });
    }
  }

  void _resetPassword() async {
    final password = _passwordControllers.map((c) => c.text).join();
    final confirmPassword = _confirmPasswordControllers
        .map((c) => c.text)
        .join();

    if (password.length == 6 &&
        confirmPassword.length == 6 &&
        _passwordsMatch) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.resetPassword(
          widget.email,
          widget.role.toLowerCase(),
          password,
          context,
        );

        if (success) {
          setState(() {
            _isLoading = false;
          });
          _showSuccessDialog();
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage =
                authProvider.errorMessage ?? 'Password reset failed';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error resetting password: $e';
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
                child: Icon(Icons.check, color: Colors.green, size: 40),
              ),
              SizedBox(height: 24),
              Text(
                'PIN Reset Successful!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Your PIN has been successfully reset. You can now login with your new PIN.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/login'); // Navigate to login page
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4A90E2),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Color(0xFF4A90E2).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.lock_reset, color: Color(0xFF4A90E2), size: 40),
        ),
        SizedBox(height: 32),
        Text(
          'Enter OTP',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'We\'ve sent a 6-digit OTP to your email address. Please enter it below to reset your PIN.',
          style: TextStyle(color: Colors.grey[600], fontSize: 16, height: 1.4),
        ),
        SizedBox(height: 32),

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
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                keyboardType: TextInputType.number,
                maxLength: 1,
                decoration: InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => _onOtpChanged(value, index),
              ),
            );
          }),
        ),

        SizedBox(height: 24),
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
              SizedBox(width: 8),
              GestureDetector(
                onTap: _resendOtp,
                child: Text(
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
        SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _verifyOtp(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4A90E2),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : Text(
                    'Verify OTP',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordReset() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Color(0xFF4A90E2).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.lock_outline, color: Color(0xFF4A90E2), size: 40),
        ),
        SizedBox(height: 32),
        Text(
          'Create New PIN',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Please create a 6-digit PIN that you will remember.',
          style: TextStyle(color: Colors.grey[600], fontSize: 16, height: 1.4),
        ),
        SizedBox(height: 32),

        Text(
          'New PIN',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        SizedBox(height: 8),
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
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                keyboardType: TextInputType.number,
                maxLength: 1,
                obscureText: true,
                decoration: InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => _onPasswordChanged(value, index, true),
              ),
            );
          }),
        ),

        SizedBox(height: 20),
        Text(
          'Confirm PIN',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        SizedBox(height: 8),
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
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                keyboardType: TextInputType.number,
                maxLength: 1,
                obscureText: true,
                decoration: InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => _onPasswordChanged(value, index, false),
              ),
            );
          }),
        ),

        SizedBox(height: 24),
        _buildValidationItem('PINs match', _passwordsMatch),

        SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4A90E2),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : Text(
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
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.cancel,
            color: isValid ? Colors.green : Colors.red,
            size: 16,
          ),
          SizedBox(width: 8),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _isOtpStep ? _buildOtpInput() : _buildPasswordReset(),

              if (_errorMessage.isNotEmpty) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, color: Colors.grey[600], size: 16),
                      SizedBox(width: 4),
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
