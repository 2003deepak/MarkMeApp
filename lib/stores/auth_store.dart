import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/data/repositories/auth_repository.dart';
import 'package:markmeapp/data/models/user_model.dart';
import 'package:markmeapp/state/auth_state.dart';

class AuthStore extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;

  AuthStore(this._authRepo) : super(const AuthState());

  String? get token => state.token;

  /// Load user data from SharedPreferences
  Future<void> loadUserData() async {
    try {
      print('🟡 [AuthStore] Loading user data from SharedPreferences');
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('userData');

      if (stored != null) {
        print('🟡 [AuthStore] Found stored user data');
        final decoded = jsonDecode(stored);
        if (decoded is Map<String, dynamic>) {
          print('🟡 [AuthStore] Setting user as logged in');
          state = state.copyWith(
            user: decoded,
            role: decoded['role'],
            access_token: decoded['token'],
            isLoggedIn: true,
            hasLoaded: true,
          );
          return;
        }
      }

      // No user data found
      print('🟡 [AuthStore] No stored user data found');
      state = state.copyWith(hasLoaded: true);
    } catch (e) {
      print('🔴 [AuthStore] Error loading user data: $e');
      // On error, set hasLoaded to true but don't log in
      state = state.copyWith(hasLoaded: true);
    }
  }

  Future<void> setLogIn(Map<String, dynamic> userData) async {
    try {
      print('🟡 [AuthStore] Setting login state with user data');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userData', jsonEncode(userData));

      state = state.copyWith(
        user: userData,
        role: userData['role'],
        access_token: userData['token'] ?? userData['access_token'],
        isLoggedIn: true,
        errorMessage: null,
        isLoading: false,
        hasLoaded: true,
      );
      
      print('🟢 [AuthStore] Login state set successfully. isLoggedIn: true, role: ${userData['role']}');
    } catch (e) {
      print('🔴 [AuthStore] Error saving login data: $e');
      state = state.copyWith(
        errorMessage: 'Error saving login data: $e',
        isLoading: false,
        hasLoaded: true,
      );
    }
  }

  Future<void> setLogOut() async {
    try {
      print('🟡 [AuthStore] Starting logout process');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userData');
      print('🟡 [AuthStore] Removed user data from SharedPreferences');

      // Reset to initial state - THIS IS THE KEY FIX
      state = const AuthState(hasLoaded: true);
      
      print('🟢 [AuthStore] Logout completed. State reset to: isLoggedIn: false, hasLoaded: true');
    } catch (e) {
      print('🔴 [AuthStore] Error during logout: $e');
      state = state.copyWith(
        errorMessage: 'Error during logout: $e',
        hasLoaded: true,
      );
    }
  }

  Future<void> clearError() {
    state = state.copyWith(errorMessage: null);
    return Future.value();
  }

  Future<void> loginUser(
    User userModel,
    String role,
    BuildContext context,
  ) async {
    // Check if already loading
    if (state.isLoading) return;

    print('🟡 [AuthStore] Starting login process for role: $role');
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _authRepo.loginUser(userModel, role);

      if (result['success'] == true && result['data'] != null) {
        print('🟢 [AuthStore] Login successful, setting login state');
        await setLogIn(result['data']);

        if (context.mounted) {
          // Navigate based on role
          final route = _getRouteForRole(role);
          print('🟡 [AuthStore] Navigating to: $route');
          context.go(route);
        }
      } else {
        final error = result['error'] ?? 'Login failed. Please check your credentials.';
        print('🔴 [AuthStore] Login failed: $error');
        state = state.copyWith(
          errorMessage: error,
          isLoading: false,
        );
      }
    } catch (e) {
      print('🔴 [AuthStore] Login error: $e');
      state = state.copyWith(
        errorMessage: 'Network error: Please check your internet connection',
        isLoading: false,
      );
    }
  }

  String _getRouteForRole(String role) {
    switch (role) {
      case 'teacher':
        return '/teacher';
      case 'admin':
        return '/admin';
      case 'clerk':
        return '/clerk';
      default: // student
        return '/student';
    }
  }

  /// Register
  Future<void> registerUser(User userModel, BuildContext context) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _authRepo.registerUser(userModel);

      if (result['success'] == true) {
        state = state.copyWith(isLoading: false);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please login.'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/login');
        }
      } else {
        state = state.copyWith(
          errorMessage:
              result['error'] ?? 'Registration failed. Please try again.',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Registration error: Please try again later',
        isLoading: false,
      );
    }
  }

  /// Forgot password
  Future<bool> forgotPassword(
    String email,
    String role,
    BuildContext context,
  ) async {
    if (state.isLoading) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _authRepo.forgotPassword(email, role);

      if (result['success'] == true) {
        state = state.copyWith(isLoading: false);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'OTP sent to your email.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return true;
      } else {
        state = state.copyWith(errorMessage: result['error'], isLoading: false);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to send OTP. Please try again.',
        isLoading: false,
      );
      return false;
    }
  }

  /// Verify OTP
  Future<bool> verifyOtp(
    String email,
    String role,
    String otp,
    BuildContext context,
  ) async {
    if (state.isLoading) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _authRepo.verifyOtp(email, role, otp);

      if (result['success'] == true) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(errorMessage: result['error'], isLoading: false);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'OTP verification failed. Please try again.',
        isLoading: false,
      );
      return false;
    }
  }

  /// Reset password
  Future<bool> resetPassword(
    String email,
    String role,
    String newPassword,
    BuildContext context,
  ) async {
    if (state.isLoading) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _authRepo.resetPassword(email, role, newPassword);

      if (result['success'] == true) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(errorMessage: result['error'], isLoading: false);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Password reset failed. Please try again.',
        isLoading: false,
      );
      return false;
    }
  }
}