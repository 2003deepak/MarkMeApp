import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSending = true;
      });

      // TODO: Implement password reset logic
      print('Sending reset email to: ${_emailController.text}');
      
      // Simulate API call
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Password reset email sent to ${_emailController.text}'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate back to login
          context.go('/login');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDesktop = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF), // Light blue tint background
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 450 : double.infinity,
              maxHeight: isDesktop ? screenHeight * 0.9 : double.infinity,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 32.0 : 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(isDesktop ? 32.0 : 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: isDesktop ? 40 : 20),
                      
                      // Header Icon with lock
                      Center(
                        child: Container(
                          width: isDesktop ? 100 : 80,
                          height: isDesktop ? 100 : 80,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.lock_reset,
                              color: Colors.white,
                              size: isDesktop ? 50 : 40,
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: isDesktop ? 32 : 24),
                      
                      // Title
                      Text(
                        'Forgot Password',
                        style: TextStyle(
                          fontSize: isDesktop ? 32 : 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: isDesktop ? 16 : 12),
                      
                      Text(
                        'Enter your email address and we\'ll send you a link to reset your password',
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 14,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: isDesktop ? 40 : 32),
                      
                      // Email Field
                      Text(
                        'Email Address',
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 12 : 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: isDesktop ? 16 : 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: isDesktop ? 16 : 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: isDesktop ? 16 : 14,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: isDesktop ? 40 : 32),
                      
                      // Reset Password Button
                      ElevatedButton(
                        onPressed: _isSending ? null : _handleResetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: isDesktop ? 16 : 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSending
                            ? SizedBox(
                                height: isDesktop ? 20 : 18,
                                width: isDesktop ? 20 : 18,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Send Reset Link',
                                style: TextStyle(
                                  fontSize: isDesktop ? 16 : 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      
                      SizedBox(height: isDesktop ? 32 : 24),
                      
                      // Back to Login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_back,
                            size: isDesktop ? 20 : 18,
                            color: Colors.black,
                          ),
                          SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              context.go('/login');
                            },
                            child: Text(
                              'Back to Login',
                              style: TextStyle(
                                fontSize: isDesktop ? 14 : 12,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 