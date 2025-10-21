import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/core/network/api_client.dart';
import '../models/user_model.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<Map<String, dynamic>> registerUser(User user) async {
    print('🔵 [AuthRepository] registerUser called with email: ${user.email}');

    try {
      final url = '/student/register';
      print('🔵 [AuthRepository] Making POST request to: $url');

      final response = await _dio.post(
        url,
        data: {
          'first_name': user.firstName,
          'last_name': user.lastName,
          'email': user.email,
          'password': user.password,
        },
      );

      print('🔵 [AuthRepository] HTTP Status Code: ${response.statusCode}');
      print('🔵 [AuthRepository] Response Body: ${response.data}');

      final responseBody = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseBody['status'] == 'success') {
          print('🟢 [AuthRepository] Registration successful');
          return {'success': true, 'data': responseBody['data']};
        } else {
          return {
            'success': false,
            'error': responseBody['message'] ?? 'Registration failed',
          };
        }
      } else {
        return {
          'success': false,
          'error':
              responseBody['message'] ?? 'Server error: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      print('🔴 [AuthRepository] DioException caught: $e');
      print('🔴 [AuthRepository] Error response: ${e.response?.data}');

      final errorMessage =
          e.response?.data?['message'] ?? e.message ?? 'Network error occurred';
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      print('🔴 [AuthRepository] Exception caught: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> loginUser(User user, String role) async {
    print(
      '🔵 [AuthRepository] loginUser called with email: ${user.email}, role: $role',
    );

    try {
      final url = '/auth/login';
      print('🔵 [AuthRepository] Making POST request to: $url');

      final response = await _dio.post(
        url,
        data: {'email': user.email, 'password': user.password, 'role': role},
      );

      print('🔵 [AuthRepository] HTTP Status Code: ${response.statusCode}');
      print('🔵 [AuthRepository] Response Body: ${response.data}');

      final responseBody = response.data;

      if (response.statusCode == 200) {
        print('🟢 [AuthRepository] Login successful');
        // Ensure role is included in the response data
        final userData = responseBody['data'] ?? {};
        if (userData is Map<String, dynamic>) {
          userData['role'] = role;
        }
        return {'success': true, 'data': userData};
      } else {
        print(responseBody);
        return {
          'success': false,
          'error': responseBody['message'] ?? 'Login failed',
        };
      }
    } on DioException catch (e) {
      print('🔴 [AuthRepository] DioException caught: $e');
      print('🔴 [AuthRepository] Error response: ${e.response?.data}');

      final errorMessage =
          e.response?.data?['message'] ?? e.message ?? 'Network error occurred';
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      print('🔴 [AuthRepository] Exception caught: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email, String role) async {
    try {
      final url = '/auth/forgot-password';
      final response = await _dio.post(
        url,
        data: {'email': email, 'role': role},
      );

      final responseBody = response.data;

      if (response.statusCode == 200) {
        if (responseBody['status'] == 'success') {
          return {'success': true, 'message': responseBody['message']};
        } else {
          return {
            'success': false,
            'error': responseBody['message'] ?? 'Failed to send OTP',
          };
        }
      } else {
        return {
          'success': false,
          'error': responseBody['message'] ?? 'Server error',
        };
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data?['message'] ?? e.message ?? 'Network error occurred';
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(
    String email,
    String role,
    String otp,
  ) async {
    try {
      final url = '/auth/verify-otp';
      final response = await _dio.post(
        url,
        data: {'email': email, 'role': role, 'otp': otp},
      );

      final responseBody = response.data;

      if (response.statusCode == 200) {
        if (responseBody['status'] == 'success') {
          return {'success': true, 'message': responseBody['message']};
        } else {
          return {
            'success': false,
            'error': responseBody['message'] ?? 'OTP verification failed',
          };
        }
      } else {
        return {
          'success': false,
          'error': responseBody['message'] ?? 'Server error',
        };
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data?['message'] ?? e.message ?? 'Network error occurred';
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> resetPassword(
    String email,
    String role,
    String newPassword,
  ) async {
    try {
      final url = '/auth/reset-password';
      final response = await _dio.post(
        url,
        data: {'email': email, 'role': role, 'new_password': newPassword},
      );

      final responseBody = response.data;

      if (response.statusCode == 200) {
        if (responseBody['status'] == 'success') {
          return {'success': true, 'message': responseBody['message']};
        } else {
          return {
            'success': false,
            'error': responseBody['message'] ?? 'Password reset failed',
          };
        }
      } else {
        return {
          'success': false,
          'error': responseBody['message'] ?? 'Server error',
        };
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data?['message'] ?? e.message ?? 'Network error occurred';
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final url = '/auth/refresh-token';
      final response = await _dio.post(
        url,
        data: {'refresh_token': refreshToken},
      );

      final responseBody = response.data;

      if (response.statusCode == 200) {
        if (responseBody['status'] == 'success') {
          return {'success': true, 'data': responseBody['data']};
        } else {
          return {
            'success': false,
            'error': responseBody['message'] ?? 'Token refresh failed',
          };
        }
      } else {
        return {
          'success': false,
          'error': responseBody['message'] ?? 'Server error',
        };
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data?['message'] ?? e.message ?? 'Network error occurred';
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}

// Auth Repository Provider - FIXED: Now properly provides Dio instance
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});
