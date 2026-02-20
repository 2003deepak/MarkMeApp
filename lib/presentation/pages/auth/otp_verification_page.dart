import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/presentation/widgets/ui/otp_field.dart';
import 'package:markmeapp/state/auth_state.dart';
import 'package:markmeapp/core/utils/snackbar_utils.dart';
import 'package:markmeapp/core/utils/app_logger.dart';
import 'package:markmeapp/data/repositories/auth_repository.dart';

class OTPVerificationPage extends ConsumerStatefulWidget {
  final String email;
  final String role;

  const OTPVerificationPage({
    super.key,
    required this.email,
    required this.role,
  });

  @override
  ConsumerState<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends ConsumerState<OTPVerificationPage> {
  String _otp = '';
  bool _isResending = false;
  bool _isLoading = false;

  // Timer related
  Timer? _timer;
  int _remainingSeconds = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _remainingSeconds = 30;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  void _onOTPCompleted(String otp) {
    setState(() {
      _otp = otp;
    });
  }

  Future<void> _handleVerify() async {
    if (_otp.length != 6) {
      showAppSnackBar('Please enter a valid 6-digit OTP', isError: true, context: context);
      return;
    }

    // Use local loading state
    _showLoading(true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.verifyOtp(widget.email, widget.role, _otp);
      
      if (!mounted) return;
      _showLoading(false);

      if (result['success'] == true) {
        showAppSnackBar(result['message'] ?? 'Email verified successfully!', isError: false, context: context);
        if (mounted) {
           // Navigate to Login with verified=true
           context.go('/login', extra: {'verified': true, 'error': ''});
        }
      } else {
         showAppSnackBar(result['error'] ?? 'Verification failed', isError: true, context: context);
      }
    } catch (e) {
      if (!mounted) return;
      _showLoading(false);
      showAppSnackBar('An error occurred: $e', isError: true, context: context);
    }
  }

  Future<void> _handleResendOtp() async {
    setState(() {
      _isResending = true;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.resendOtp(widget.email, widget.role);

      if (!mounted) return;

      setState(() {
        _isResending = false;
      });

      if (result['success'] == true) {
        showAppSnackBar(result['message'] ?? 'OTP resent successfully!', isError: false, context: context);
        _startTimer();
      } else {
        showAppSnackBar(result['error'] ?? 'Failed to resend OTP', isError: true, context: context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
      });
      showAppSnackBar('An error occurred: $e', isError: true, context: context);
    }
  }
  
  void _showLoading(bool loading) {
      if (mounted) {
        setState(() {
          _isLoading = loading;
        });
      }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;
    final primaryColor = Colors.blue.shade600;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 32.0 : 24.0),
        child: Column(
          children: [
            SizedBox(height: isDesktop ? 60 : 40),
            SvgPicture.asset('assets/logo.svg', height: 80),
            const SizedBox(height: 32),
            
            Text(
              'Verification',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
             const SizedBox(height: 12),
            Text(
              'Enter the 6-digit code sent to\n${widget.email}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            
            const SizedBox(height: 40),
            
            OTPField(
              length: 6,
              onCompleted: _onOTPCompleted,
              onChanged: _onOTPCompleted,
              fieldWidth: isDesktop ? 60 : 50,
              fieldHeight: isDesktop ? 70 : 60,
              borderColor: Colors.grey.shade300,
              focusedBorderColor: primaryColor,
            ),
            
            const SizedBox(height: 40),
            
             SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isLoading || _otp.length != 6) ? null : _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                  'Verify Email',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            TextButton(
              onPressed: (_isResending || !_canResend) ? null : _handleResendOtp,
              child: _isResending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _canResend
                          ? 'Resend Code'
                          : 'Resend Code in ${_remainingSeconds}s',
                      style: TextStyle(
                        color: _canResend ? primaryColor : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
