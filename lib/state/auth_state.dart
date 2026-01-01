import 'package:dio/dio.dart';
import 'package:markmeapp/core/utils/get_device_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/data/repositories/auth_repository.dart';
import 'package:markmeapp/data/models/user_model.dart';
import 'package:markmeapp/core/utils/app_logger.dart';

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

/// AuthStore
class AuthStore extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;

  AuthStore(this._authRepo) : super(const AuthState()) {
    _restoreSession();
  }

  String? get accessToken => state.accessToken;
  bool get isLoggedIn => state.isLoggedIn;
  String? get role => state.role;
  bool get isLoading => state.isLoading;

  /// Set login state + save refresh token + save role
  Future<void> setLogIn(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (userData['refresh_token'] != null) {
        await prefs.setString('refreshToken', userData['refresh_token']);
      }

      await prefs.setString('role', userData['role']);

      state = state.copyWith(
        user: userData,
        role: userData['role'],
        accessToken: userData['access_token'],
        isLoggedIn: true,
        isLoading: false,
        hasLoaded: true,
      );

      AppLogger.info('🟢 Login state saved');
    } catch (e) {
      AppLogger.error('🔴 Error saving login data: $e');
      state = state.copyWith(isLoading: false, hasLoaded: true);
    }
  }

  /// Logout
  Future<void> setLogOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fcmToken = prefs.getString('fcmToken');

      await _authRepo.logoutUser(fcmToken ?? "");

      await prefs.remove('refreshToken');
      await prefs.remove('fcmToken');
      await prefs.remove('role');

      state = const AuthState(hasLoaded: true);
    } catch (e) {
      AppLogger.error('🔴 Logout error: $e');
    }
  }

  /// Login User
  Future<Map<String, dynamic>> loginUser(User userModel, String role) async {
    if (state.isLoading) {
      return {'success': false, 'message': 'Operation already in progress'};
    }

    try {
      state = state.copyWith(isLoading: true);

      final result = await _authRepo.loginUser(userModel, role);

      if (result['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcmToken', userModel.fcmToken!);

        await setLogIn(result['data']);

        return {
          'success': true,
          'message': result['message'] ?? 'Login successful',
        };
      }

      return {'success': false, 'message': result['message']};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Refresh access token
  Future<Map<String, dynamic>> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();

      if (refreshToken == null) {
        return {'success': false, 'message': 'No refresh token available'};
      }

      final result = await _authRepo.refreshToken(refreshToken);

      if (result['success'] == true) {
        final newToken = result['data']['access_token'];
        state = state.copyWith(accessToken: newToken);

        return {
          'success': true,
          'data': {'access_token': newToken},
        };
      }

      return {'success': false, 'message': result['error']};
    } catch (e) {
      return {'success': false, 'message': 'Token refresh failed'};
    }
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refreshToken');
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

      AppLogger.info("Message from state = $response");

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
      AppLogger.error(
        '🔴 [AuthRepository] Error response: ${e.response?.data}',
      );
      return {
        'status': 'fail',
        // ✅ Preserve backend message here
        'message':
            e.response?.data['message'] ??
            'Registration failed. Please try again.',
      };
    } catch (e) {
      AppLogger.error('🔴 [AuthRepository] Unexpected error: $e');
      return {
        'status': 'fail',
        'message': 'Unexpected error occurred. Please try again.',
      };
    }
  }

  /// Forgot Password
  Future<Map<String, dynamic>> forgotPassword(String email, String role) async {
    if (state.isLoading) {
      return {'status': 'fail', 'message': 'Operation already in progress'};
    }

    state = state.copyWith(isLoading: true);

    try {
      final result = await _authRepo.forgotPassword(email, role);

      // Check if status is "success" (not true/false)
      if (result['success'] == true) {
        state = state.copyWith(isLoading: false);
        return {
          'success': true,
          'message': result['message'] ?? 'OTP sent to your email.',
        };
      } else {
        final error = result['message'] ?? 'Failed to send OTP';
        state = state.copyWith(isLoading: false);
        return {'status': 'fail', 'message': error};
      }
    } catch (e) {
      AppLogger.error('🔴 [AuthStore] Forgot password error: $e');
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
  ) async {
    if (state.isLoading) {
      return {'status': 'fail', 'message': 'Operation already in progress'};
    }

    state = state.copyWith(isLoading: true);

    try {
      final result = await _authRepo.verifyOtp(email, role, otp);

      // Check if status is "success" (not true/false)
      if (result['success'] == true) {
        state = state.copyWith(isLoading: false);
        return {
          'success': true,
          'message': result['message'] ?? 'OTP verified successfully.',
        };
      } else {
        final error = result['message'] ?? 'OTP verification failed';
        state = state.copyWith(isLoading: false);
        return {'status': 'fail', 'message': error};
      }
    } catch (e) {
      AppLogger.error('🔴 [AuthStore] OTP verification error: $e');
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
  ) async {
    if (state.isLoading) {
      return {'status': 'fail', 'message': 'Operation already in progress'};
    }

    state = state.copyWith(isLoading: true);

    try {
      final result = await _authRepo.resetPassword(email, role, newPassword);

      // Check if status is "success" (not true/false)
      if (result['success'] == true) {
        state = state.copyWith(isLoading: false);
        return {
          'success': true,
          'message': result['message'] ?? 'Password reset successfully.',
        };
      } else {
        final error = result['message'] ?? 'Password reset failed';
        state = state.copyWith(isLoading: false);
        return {'status': 'fail', 'message': error};
      }
    } catch (e) {
      AppLogger.error('🔴 [AuthStore] Reset password error: $e');
      final errorMessage = 'Password reset failed. Please try again.';
      state = state.copyWith(isLoading: false);
      return {'status': 'fail', 'message': errorMessage};
    }
  }

  Future<void> _restoreSession() async {
    try {
      AppLogger.info('🟡 Restoring session');

      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refreshToken');
      final role = prefs.getString('role');

      if (refreshToken == null || role == null) {
        state = const AuthState(hasLoaded: true, isLoggedIn: false);
        return;
      }

      final refreshResult = await refreshAccessToken();

      if (refreshResult['success'] != true) {
        await clearSession(prefs);
        state = const AuthState(hasLoaded: true, isLoggedIn: false);
        return;
      }

      state = state.copyWith(hasLoaded: true, isLoggedIn: true, role: role);

      AppLogger.info('🟢 Auto-login success → $role');
    } catch (e) {
      AppLogger.error('🔴 Restore session failed: $e');
      state = const AuthState(hasLoaded: true, isLoggedIn: false);
    }
  }
}

/// Provider for AuthStore
final authStoreProvider = StateNotifierProvider<AuthStore, AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthStore(authRepo);
});
