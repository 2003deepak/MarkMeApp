import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/state/student_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/data/repositories/auth_repository.dart';
import 'package:markmeapp/data/models/user_model.dart';

/// AuthState - Simple state container
class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final bool hasLoaded;
  final String? accessToken;
  final String? role;
  final Map<String, dynamic>? user;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.hasLoaded = false,
    this.accessToken,
    this.role,
    this.user,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    bool? hasLoaded,
    String? accessToken,
    String? role,
    Map<String, dynamic>? user,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      accessToken: accessToken ?? this.accessToken,
      role: role ?? this.role,
      user: user ?? this.user,
    );
  }

  @override
  String toString() {
    return 'AuthState(isLoggedIn: $isLoggedIn, isLoading: $isLoading, hasLoaded: $hasLoaded, role: $role)';
  }
}

/// AuthStore - Combined state management and repository interactions
class AuthStore extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;

  AuthStore(this._authRepo) : super(const AuthState());

  String? get accessToken => state.accessToken;
  bool get isLoggedIn => state.isLoggedIn;
  String? get role => state.role;
  bool get isLoading => state.isLoading;

  /// Load user data from SharedPreferences
  Future<void> loadUserData(WidgetRef ref, BuildContext context) async {
    try {
      debugPrint('🟡 [AuthStore] Loading user data from SharedPreferences');
      final prefs = await SharedPreferences.getInstance();
      final storedRefreshToken = prefs.getString('refreshToken');

      if (storedRefreshToken == null) {
        debugPrint('🟡 [AuthStore] No stored refresh token found');
        state = state.copyWith(hasLoaded: true, isLoggedIn: false);
        return;
      }

      // Try refreshing access token
      final refreshResult = await refreshAccessToken();

      if (refreshResult['success'] == true) {
        debugPrint('🟢 [AuthStore] Access token refresh successful');

        // ✅ Fetch user profile (based on role, here student example)
        final studentStore = ref.read(studentStoreProvider.notifier);
        final profileResult = await studentStore.loadProfile();

        if (profileResult['success'] == true) {
          // Extract role from profile or token payload
          final role = profileResult['data']?['role'] ?? 'student';

          // ✅ Update AuthState
          state = state.copyWith(
            isLoggedIn: true,
            hasLoaded: true,
            isLoading: false,
            role: role,
          );

          debugPrint(
            '🟢 [AuthStore] User auto-login completed, navigating to $role dashboard',
          );
        } else {
          debugPrint('🔴 [AuthStore] Profile fetch failed');
          await prefs.remove('refreshToken');
          state = const AuthState(hasLoaded: true, isLoggedIn: false);
        }
      } else {
        debugPrint(
          '🔴 [AuthStore] Token refresh failed: ${refreshResult['message']}',
        );

        // ❌ Clear invalid token
        await prefs.remove('refreshToken');
        state = const AuthState(hasLoaded: true, isLoggedIn: false);

        if (context.mounted) {
          context.go('/login');
        }
      }
    } catch (e) {
      debugPrint('🔴 [AuthStore] Error during auto-login: $e');
      state = state.copyWith(hasLoaded: true, isLoggedIn: false);

      // Optional fallback navigation
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  /// Set login state and save to SharedPreferences
  Future<void> setLogIn(Map<String, dynamic> userData) async {
    try {
      debugPrint('🟡 [AuthStore] Setting login state with user data');
      final prefs = await SharedPreferences.getInstance();
      // Save refresh token if available
      if (userData['refresh_token'] != null) {
        await prefs.setString('refreshToken', userData['refresh_token']);
      }

      state = state.copyWith(
        user: userData,
        role: userData['role'],
        accessToken: userData['access_token'],
        isLoggedIn: true,
        isLoading: false,
        hasLoaded: true,
      );

      debugPrint(
        '🟢 [AuthStore] Login state set successfully. isLoggedIn: true, role: ${userData['role']}',
      );
    } catch (e) {
      debugPrint('🔴 [AuthStore] Error saving login data: $e');
      state = state.copyWith(isLoading: false, hasLoaded: true);
    }
  }

  /// Logout - Clear all data
  Future<void> setLogOut() async {
    try {
      debugPrint('🟡 [AuthStore] Starting logout process');
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('refreshToken');
      debugPrint('🟡 [AuthStore] Removed refresh token from SharedPreferences');

      state = const AuthState(hasLoaded: true);

      debugPrint(
        '🟢 [AuthStore] Logout completed. State reset to: isLoggedIn: false, hasLoaded: true',
      );
    } catch (e) {
      debugPrint('🔴 [AuthStore] Error during logout: $e');
      state = state.copyWith(hasLoaded: true);
    }
  }

  /// Login User
  Future<Map<String, dynamic>> loginUser(
    User userModel,
    String role,
    BuildContext context,
  ) async {
    if (state.isLoading) {
      return {'success': false, 'message': 'Operation already in progress'};
    }

    debugPrint('🟡 [AuthStore] Starting login process for role: $role');
    state = state.copyWith(isLoading: true);

    try {
      final result = await _authRepo.loginUser(userModel, role);

      // ✅ Safely read message from repository result
      final bool success = result['success'] == true;
      final String message = result['message'] ?? '';

      if (success) {
        debugPrint('🟢 [AuthStore] Login successful, setting login state');
        await setLogIn(result['data']);
        state = state.copyWith(isLoading: false);
        return {
          'success': true,
          'message': message.isNotEmpty ? message : 'Login successful',
        };
      } else {
        debugPrint('🔴 [AuthStore] Login failed: $message');
        state = state.copyWith(isLoading: false);
        return {
          'success': false,
          'message': message.isNotEmpty ? message : 'Login failed',
        };
      }
    } catch (e) {
      debugPrint('🔴 [AuthStore] Login error: $e');
      final errorMessage =
          'Network error: Please check your internet connection';
      state = state.copyWith(isLoading: false);
      return {'success': false, 'message': errorMessage};
    }
  }

  /// Get route based on user role
  String getRouteForRole(String role) {
    switch (role) {
      case 'teacher':
        return '/teacher';
      case 'admin':
        return '/admin';
      case 'clerk':
        return '/clerk';
      default:
        return '/student';
    }
  }

  /// Register User
  Future<Map<String, dynamic>> registerUser(User userModel) async {
    try {
      final response = await _authRepo.registerUser(userModel);

      print("Message from state = $response");

      if (response['success'] == true) {
        return {
          'success': true,
          'data': response['data'],
          'message': response['message'] ?? 'Registration successful',
        };
      } else {
        return {
          'success': 'fail',
          'message': response['message'] ?? 'Registration failed',
        };
      }
    } on DioException catch (e) {
      debugPrint('🔴 [AuthRepository] Error response: ${e.response?.data}');
      return {
        'status': 'fail',
        // ✅ Preserve backend message here
        'message':
            e.response?.data['message'] ??
            'Registration failed. Please try again.',
      };
    } catch (e) {
      debugPrint('🔴 [AuthRepository] Unexpected error: $e');
      return {
        'status': 'fail',
        'message': 'Unexpected error occurred. Please try again.',
      };
    }
  }

  /// Forgot Password
  Future<Map<String, dynamic>> forgotPassword(
    String email,
    String role,
    BuildContext context,
  ) async {
    if (state.isLoading) {
      return {'status': 'fail', 'message': 'Operation already in progress'};
    }

    state = state.copyWith(isLoading: true);

    try {
      final result = await _authRepo.forgotPassword(email, role);

      // Check if status is "success" (not true/false)
      if (result['status'] == 'success') {
        state = state.copyWith(isLoading: false);
        return {
          'status': 'success',
          'message': result['message'] ?? 'OTP sent to your email.',
        };
      } else {
        final error = result['message'] ?? 'Failed to send OTP';
        state = state.copyWith(isLoading: false);
        return {'status': 'fail', 'message': error};
      }
    } catch (e) {
      debugPrint('🔴 [AuthStore] Forgot password error: $e');
      final errorMessage = 'Failed to send OTP. Please try again.';
      state = state.copyWith(isLoading: false);
      return {'status': 'fail', 'message': errorMessage};
    }
  }

  /// Verify OTP
  Future<Map<String, dynamic>> verifyOtp(
    String email,
    String role,
    String otp,
    BuildContext context,
  ) async {
    if (state.isLoading) {
      return {'status': 'fail', 'message': 'Operation already in progress'};
    }

    state = state.copyWith(isLoading: true);

    try {
      final result = await _authRepo.verifyOtp(email, role, otp);

      // Check if status is "success" (not true/false)
      if (result['status'] == 'success') {
        state = state.copyWith(isLoading: false);
        return {
          'status': 'success',
          'message': result['message'] ?? 'OTP verified successfully.',
        };
      } else {
        final error = result['message'] ?? 'OTP verification failed';
        state = state.copyWith(isLoading: false);
        return {'status': 'fail', 'message': error};
      }
    } catch (e) {
      debugPrint('🔴 [AuthStore] OTP verification error: $e');
      final errorMessage = 'OTP verification failed. Please try again.';
      state = state.copyWith(isLoading: false);
      return {'status': 'fail', 'message': errorMessage};
    }
  }

  /// Reset Password
  Future<Map<String, dynamic>> resetPassword(
    String email,
    String role,
    String newPassword,
    BuildContext context,
  ) async {
    if (state.isLoading) {
      return {'status': 'fail', 'message': 'Operation already in progress'};
    }

    state = state.copyWith(isLoading: true);

    try {
      final result = await _authRepo.resetPassword(email, role, newPassword);

      // Check if status is "success" (not true/false)
      if (result['status'] == 'success') {
        state = state.copyWith(isLoading: false);
        return {
          'status': 'success',
          'message': result['message'] ?? 'Password reset successfully.',
        };
      } else {
        final error = result['message'] ?? 'Password reset failed';
        state = state.copyWith(isLoading: false);
        return {'status': 'fail', 'message': error};
      }
    } catch (e) {
      debugPrint('🔴 [AuthStore] Reset password error: $e');
      final errorMessage = 'Password reset failed. Please try again.';
      state = state.copyWith(isLoading: false);
      return {'status': 'fail', 'message': errorMessage};
    }
  }

  /// Get refresh token from SharedPreferences
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refreshToken');
  }

  /// Refresh access token
  Future<Map<String, dynamic>> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        debugPrint('🔴 [AuthStore] No refresh token available');
        return {'success': false, 'message': 'No refresh token available'};
      }

      debugPrint('🟡 [AuthStore] Refreshing access token');
      final result = await _authRepo.refreshToken(refreshToken);
      print("🟢 [AuthStore] Repo result → $result");

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        final newAccessToken = data['access_token'];

        if (newAccessToken == null || newAccessToken.isEmpty) {
          throw Exception('Access token missing in response');
        }

        // ✅ Update the store state
        state = state.copyWith(accessToken: newAccessToken);

        debugPrint('🟢 [AuthStore] Access token refreshed successfully');

        return {
          'success': true,
          'data': {'access_token': newAccessToken},
          'message': result['message'] ?? 'Token refreshed successfully',
        };
      } else {
        final error = result['error'] ?? 'Token refresh failed';
        debugPrint('🔴 [AuthStore] Token refresh failed: $error');
        return {'success': false, 'message': error};
      }
    } catch (e) {
      debugPrint("🔴 [AuthStore] Token refresh error: $e");
      return {'success': false, 'message': 'Token refresh failed'};
    }
  }
}

// Provider for AuthStore
final authStoreProvider = StateNotifierProvider<AuthStore, AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthStore(authRepo);
});
