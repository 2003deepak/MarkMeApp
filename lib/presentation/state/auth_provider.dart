import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:markmeapp/data/repositories/auth_repository.dart';
import 'package:markmeapp/data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userData => _userData;
  String? get token => _userData?['access_token'];
  bool get isLoggedIn => token != null;
  String? get userRole => _userData?['role'];

  void clearError() {
    print('🔵 [AuthProvider] clearError called');
    _errorMessage = null;
    notifyListeners();
  }

  /// Save user data
  Future<void> _saveUserData(dynamic data) async {
    print('🔵 [AuthProvider] _saveUserData called with data: $data');
    try {
      Map<String, dynamic> userData;
      if (data is Map<String, dynamic>) {
        userData = data;
      } else if (data is Map) {
        userData = data.cast<String, dynamic>();
      } else {
        throw Exception('Invalid data type for user data: ${data.runtimeType}');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userData', jsonEncode(userData));
      _userData = userData;
      print('🟢 [AuthProvider] User data saved successfully: $_userData');
      notifyListeners();
    } catch (e) {
      print('🔴 [AuthProvider] Error saving user data: $e');
      rethrow;
    }
  }

  /// Load on app start
  Future<void> loadUserData() async {
    print('🔵 [AuthProvider] loadUserData called');
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('userData');
    if (stored != null) {
      try {
        final decoded = jsonDecode(stored);
        if (decoded is Map<String, dynamic>) {
          _userData = decoded;
        } else if (decoded is Map) {
          _userData = decoded.cast<String, dynamic>();
        }
        print('🟢 [AuthProvider] Loaded user data: $_userData');
        notifyListeners();
      } catch (e) {
        print('🔴 [AuthProvider] Failed to decode stored user data: $e');
        await clearUserData();
      }
    }
  }

  /// Clear on logout
  Future<void> clearUserData() async {
    print('🔵 [AuthProvider] clearUserData called');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
    _userData = null;
    notifyListeners();
  }

  /// Login
  Future<void> loginUser(User user, String role, BuildContext context) async {
    print(
      '🔵 [AuthProvider] loginUser called with email: ${user.email}, role: $role',
    );
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepo.loginUser(user, role);
      if (result['success'] == true) {
        await _saveUserData(result['data']);
        if (context.mounted) {
          if (role == 'teacher') {
            context.go('/teacher');
          } else if (role == 'admin') {
            context.go('/admin-dashboard');
          } else {
            context.go('/student');
          }
        }
      } else {
        _errorMessage = result['error'] ?? 'Login failed';
      }
    } catch (e) {
      _errorMessage = 'Login error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register
  Future<void> registerUser(User user, BuildContext context) async {
    print('🔵 [AuthProvider] registerUser called with email: ${user.email}');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepo.registerUser(user);
      if (result['success'] == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please login.'),
            ),
          );
          context.go('/login');
        }
      } else {
        _errorMessage = result['error'] ?? 'Registration failed';
      }
    } catch (e) {
      _errorMessage = 'Registration error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Forgot password (Step 1)
  Future<bool> forgotPassword(
    String email,
    String role,
    BuildContext context,
  ) async {
    print('🔵 [AuthProvider] forgotPassword called');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepo.forgotPassword(email, role);
      if (result['success'] == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'OTP sent to email')),
          );
          context.go('/verify-otp');
        }
        return true;
      } else {
        _errorMessage = result['error'];
        return false;
      }
    } catch (e) {
      _errorMessage = 'Forgot password error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verify OTP (Step 2)
  Future<bool> verifyOtp(
    String email,
    String role,
    String otp,
    BuildContext context,
  ) async {
    print('🔵 [AuthProvider] verifyOtp called');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepo.verifyOtp(email, role, otp);
      if (result['success'] == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'OTP verified')),
          );
        }
        return true; // ✅ no navigation, ResetPasswordPage continues with _isOtpStep=false
      } else {
        _errorMessage = result['error'];
        return false;
      }
    } catch (e) {
      _errorMessage = 'OTP verification error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset Password (Step 3)
  Future<bool> resetPassword(
    String email,
    String role,
    String newPassword,
    BuildContext context,
  ) async {
    print('🔵 [AuthProvider] resetPassword called');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepo.resetPassword(email, role, newPassword);
      if (result['success'] == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Password reset successful'),
            ),
          );
          context.go('/login'); // ✅ After reset, send user back to login
        }
        return true;
      } else {
        _errorMessage = result['error'];
        return false;
      }
    } catch (e) {
      _errorMessage = 'Reset password error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
