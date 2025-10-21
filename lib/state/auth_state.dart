import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
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
  final String? errorMessage;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.hasLoaded = false,
    this.accessToken,
    this.role,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    bool? hasLoaded,
    String? accessToken,
    String? role,
    Map<String, dynamic>? user,
    String? errorMessage,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      accessToken: accessToken ?? this.accessToken,
      role: role ?? this.role,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'AuthState(isLoggedIn: $isLoggedIn, isLoading: $isLoading, hasLoaded: $hasLoaded, role: $role, errorMessage: $errorMessage)';
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
  String? get errorMessage => state.errorMessage;

  /// Load user data from SharedPreferences
  Future<void> loadUserData() async {
    try {
      debugPrint('🟡 [AuthStore] Loading user data from SharedPreferences');
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('userData');

      if (stored != null) {
        debugPrint('🟡 [AuthStore] Found stored user data');
        final decoded = jsonDecode(stored);
        if (decoded is Map<String, dynamic>) {
          debugPrint('🟡 [AuthStore] Setting user as logged in');
          state = state.copyWith(
            user: decoded,
            role: decoded['role'],
            accessToken: decoded['token'] ?? decoded['access_token'],
            isLoggedIn: true,
            hasLoaded: true,
          );
          return;
        }
      }

      // No user data found
      debugPrint('🟡 [AuthStore] No stored user data found');
      state = state.copyWith(hasLoaded: true);
    } catch (e) {
      debugPrint('🔴 [AuthStore] Error loading user data: $e');
      state = state.copyWith(hasLoaded: true);
    }
  }

  /// Set login state and save to SharedPreferences
  Future<void> setLogIn(Map<String, dynamic> userData) async {
    try {
      debugPrint('🟡 [AuthStore] Setting login state with user data');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userData', jsonEncode(userData));

      // Save refresh token if available
      if (userData['refresh_token'] != null) {
        await prefs.setString('refreshToken', userData['refresh_token']);
      }

      state = state.copyWith(
        user: userData,
        role: userData['role'],
        accessToken: userData['token'] ?? userData['access_token'],
        isLoggedIn: true,
        errorMessage: null,
        isLoading: false,
        hasLoaded: true,
      );

      debugPrint(
        '🟢 [AuthStore] Login state set successfully. isLoggedIn: true, role: ${userData['role']}',
      );
    } catch (e) {
      debugPrint('🔴 [AuthStore] Error saving login data: $e');
      state = state.copyWith(
        errorMessage: 'Error saving login data: $e',
        isLoading: false,
        hasLoaded: true,
      );
    }
  }

  /// Logout - Clear all data
  Future<void> setLogOut() async {
    try {
      debugPrint('🟡 [AuthStore] Starting logout process');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userData');
      debugPrint('🟡 [AuthStore] Removed user data from SharedPreferences');

      state = const AuthState(hasLoaded: true);

      debugPrint(
        '🟢 [AuthStore] Logout completed. State reset to: isLoggedIn: false, hasLoaded: true',
      );
    } catch (e) {
      debugPrint('🔴 [AuthStore] Error during logout: $e');
      state = state.copyWith(
        errorMessage: 'Error during logout: $e',
        hasLoaded: true,
      );
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Login User
  Future<void> loginUser(
    User userModel,
    String role,
    BuildContext context,
  ) async {
    if (state.isLoading) return;

    debugPrint('🟡 [AuthStore] Starting login process for role: $role');
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _authRepo.loginUser(userModel, role);

      if (result['success'] == true && result['data'] != null) {
        debugPrint('🟢 [AuthStore] Login successful, setting login state');
        await setLogIn(result['data']);

        if (context.mounted) {
          final route = _getRouteForRole(role);
          debugPrint('🟡 [AuthStore] Navigating to: $route');
          context.go(route);
        }
      } else {
        final error =
            result['error'] ?? 'Login failed. Please check your credentials.';
        debugPrint('🔴 [AuthStore] Login failed: $error');
        state = state.copyWith(errorMessage: error, isLoading: false);
      }
    } catch (e) {
      debugPrint('🔴 [AuthStore] Login error: $e');
      state = state.copyWith(
        errorMessage: 'Network error: Please check your internet connection',
        isLoading: false,
      );
    }
  }

  /// Get route based on user role
  String _getRouteForRole(String role) {
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

  /// Forgot Password
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

  /// Reset Password
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

  /// Get refresh token from SharedPreferences
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refreshToken');
  }

  /// Refresh access token
  Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        debugPrint('🔴 [AuthStore] No refresh token available');
        return null;
      }

      debugPrint('🟡 [AuthStore] Refreshing access token');

      final response = await Dio().post(
        '${dotenv.env['BASE_URL']}/auth/refresh-token',
        options: Options(headers: {'x-internal-token': 'Bearer $refreshToken'}),
      );

      if (response.statusCode == 200 &&
          response.data['data'] != null &&
          response.data['data']['access_token'] != null) {
        final newToken = response.data['data']['access_token'];
        debugPrint('🟢 [AuthStore] Access token refreshed successfully');

        // Update the state properly
        state = state.copyWith(accessToken: newToken);

        return newToken;
      } else {
        debugPrint('🔴 [AuthStore] Token refresh failed: ${response.data}');
        throw Exception('Failed to refresh token');
      }
    } catch (e) {
      debugPrint("🔴 [AuthStore] Token refresh error: $e");
      return null;
    }
  }
}

// Provider for AuthStore
final authStoreProvider = StateNotifierProvider<AuthStore, AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthStore(authRepo);
});
