import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:markmeapp/core/config/permission.dart';
import 'package:markmeapp/core/utils/get_device_info.dart';
import 'package:markmeapp/data/models/user_model.dart';
import 'package:markmeapp/presentation/widgets/ui/input_field.dart';
import 'package:markmeapp/presentation/widgets/ui/otp_field.dart';
import 'package:markmeapp/state/auth_state.dart';
import 'package:markmeapp/core/utils/app_logger.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _enteredPassword = '';
  bool _rememberMe = false;
  String _selectedRole = 'student'; // Default role
  bool _permissionsInitialized = false; // Add this flag

  @override
  void initState() {
    super.initState();
    _initializePermissions();
  }

  Future<void> _initializePermissions() async {
    if (!_permissionsInitialized) {
      // Skip permission initialization on desktop platforms
      if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
        await appPermissions.initialize(context);
        AppLogger.info("✅ Permissions initialized for mobile platform");
      } else {
        AppLogger.info("🖥️ Skipping permissions on desktop platform");
      }
      setState(() {
        _permissionsInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onPasswordCompleted(String password) {
    setState(() {
      _enteredPassword = password;
    });
    AppLogger.info('✅ Password Entered: $password');
  }

  Future<void> _handleLogin() async {
    AppLogger.info('🔵 [LoginPage] _handleLogin called');

    if (!mounted) {
      AppLogger.warning('🔴 [LoginPage] Widget not mounted, returning');
      return;
    }

    if (_formKey.currentState!.validate()) {
      AppLogger.info('🟢 [LoginPage] Form validation passed');

      if (_enteredPassword.isEmpty || _enteredPassword.length != 6) {
        _showSnackBar('Please enter a 6-digit password', isError: true);
        return;
      }

      // Platform-specific FCM token handling
      String? fcmToken;
      try {
        // Only get FCM token on mobile platforms
        if (Platform.isAndroid || Platform.isIOS) {
          fcmToken = await FirebaseMessaging.instance.getToken();
          AppLogger.info("📱 FCM Token: $fcmToken");
        } else {
          // Desktop platforms - generate mock token
          fcmToken = "desktop-token-${DateTime.now().millisecondsSinceEpoch}";
          AppLogger.info("🖥️ Using mock FCM token for desktop");
        }
      } catch (e) {
        AppLogger.error("⚠️ Error getting FCM token: $e");
        fcmToken = "error-token-${DateTime.now().millisecondsSinceEpoch}";
      }

      // Platform-specific device info
      final platformType = getPlatformType();
      final deviceType = platformType == 'android'
          ? "android"
          : platformType == 'ios'
          ? "ios"
          : platformType; // windows, macos, linux

      final deviceInfo = await getDeviceInfo();

      final user = User(
        firstName: '',
        lastName: '',
        email: _emailController.text.trim(),
        password: _enteredPassword,
        fcmToken: fcmToken ?? "unknown-token",
        deviceType: deviceType,
        deviceInfo: deviceInfo,
      );

      AppLogger.info(
        '🔵 [LoginPage] Attempting login with email: ${user.email}, role: $_selectedRole, platform: $platformType',
      );

      final authStore = ref.read(authStoreProvider.notifier);

      if (!mounted) return;

      // ✅ Await here
      final result = await authStore.loginUser(user, _selectedRole);

      AppLogger.info('🟢 [LoginPage] The response from state is = $result');

      if (result['success'] == true) {
        _showSnackBar(result['message'] ?? 'Login successful!', isError: false);
        if (mounted) {
          // Navigate based on role
          final route = authStore.getRouteForRole(_selectedRole);
          context.go(route);
        }
      } else {
        _showSnackBar(result['message'] ?? 'Login failed', isError: true);
      }
    } else {
      AppLogger.warning('🔴 [LoginPage] Form validation failed');
    }
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;
    final primaryColor = Colors.blue.shade600;

    // REMOVED: appPermissions.initialize(context) from here

    // Watch the auth state for loading & errors
    final authState = ref.watch(authStoreProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 32.0 : 24.0),
        child: Column(
          children: [
            SizedBox(height: isDesktop ? 40 : 20),

            // Logo
            SvgPicture.asset('assets/logo.svg', height: 80),

            const SizedBox(height: 24),
            const Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to your account to continue',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Enhanced Role Toggle: Student vs College Staff
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.blue.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue.shade200, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withAlpha(26), // 0.1
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRole = 'student'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _selectedRole == 'student'
                                ? [Colors.blue.shade600, Colors.blue.shade500]
                                : [Colors.transparent, Colors.transparent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: _selectedRole == 'student'
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.withAlpha(77), // 0.3
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              color: _selectedRole == 'student'
                                  ? Colors.white
                                  : Colors.blue.shade600,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Student',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedRole == 'student'
                                    ? Colors.white
                                    : Colors.blue.shade600,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRole = 'teacher'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _selectedRole != 'student'
                                ? [Colors.blue.shade600, Colors.blue.shade500]
                                : [Colors.transparent, Colors.transparent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: _selectedRole != 'student'
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.withAlpha(77), // 0.3
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.work_outline,
                              color: _selectedRole != 'student'
                                  ? Colors.white
                                  : Colors.blue.shade600,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'College Staff',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedRole != 'student'
                                    ? Colors.white
                                    : Colors.blue.shade600,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              reverseDuration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1.0,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: _selectedRole != 'student'
                  ? Column(
                      key: const ValueKey('staff_options'),
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Your Role',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildRoleOption(
                                    value: 'teacher',
                                    label: 'Teacher',
                                    icon: Icons.school,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildRoleOption(
                                    value: 'clerk',
                                    label: 'Clerk',
                                    icon: Icons.assignment_ind,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildRoleOption(
                                    value: 'admin',
                                    label: 'Admin',
                                    icon: Icons.admin_panel_settings,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(key: ValueKey('empty_options')),
            ),

            const SizedBox(height: 32),

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Email Field
                  InputField(
                    label: 'Email Address',
                    hintText: 'aryan@gmail.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    isRequired: true,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email address';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // 6-Digit Password Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '6-Digit Password',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const Text(
                            ' *',
                            style: TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      OTPField(
                        onCompleted: _onPasswordCompleted,
                        autoFocus: false,
                        borderColor: Colors.grey.shade400,
                        focusedBorderColor: primaryColor,
                        cursorColor: primaryColor,
                        fieldWidth: isDesktop ? 55 : 50,
                        fieldHeight: isDesktop ? 65 : 60,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Remember Me and Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Transform.scale(
                            scale: 0.8,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              activeColor: Colors.blue.shade600,
                            ),
                          ),
                          Text(
                            'Remember me',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          context.go('/forgot-password');
                        },
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Sign In Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient:
                          (_enteredPassword.length != 6 || authState.isLoading)
                          ? LinearGradient(
                              colors: [
                                Colors.grey.shade400,
                                Colors.grey.shade500,
                              ],
                            )
                          : LinearGradient(
                              colors: [primaryColor, Colors.blue.shade700],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow:
                          (_enteredPassword.length != 6 || authState.isLoading)
                          ? []
                          : [
                              BoxShadow(
                                color: primaryColor.withAlpha(77), // 0.3
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    child: ElevatedButton(
                      onPressed:
                          (_enteredPassword.length != 6 || authState.isLoading)
                          ? null
                          : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Divider with text
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Don't have an account?",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Create Account Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: authState.isLoading
                          ? null
                          : () {
                              context.go('/signup');
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                      child: const Text(
                        'Create Account',
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
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade600 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : Colors.blue.shade600,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
