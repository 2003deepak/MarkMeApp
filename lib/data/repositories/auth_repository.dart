import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';

class AuthRepository {
  final String baseUrl;

  AuthRepository()
    : baseUrl =
          dotenv.env['BASE_URL'] ?? 'http://localhost:3000'; // Fallback URL

  Future<Map<String, dynamic>> registerUser(User user) async {
    print('🔵 [AuthRepository] registerUser called with email: ${user.email}');

    try {
      final url = '$baseUrl/student/register';
      print('🔵 [AuthRepository] Making POST request to: $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'first_name': user.firstName,
              'last_name': user.lastName,
              'email': user.email,
              'password': user.password,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('🔵 [AuthRepository] HTTP Status Code: ${response.statusCode}');
      print('🔵 [AuthRepository] Response Body: ${response.body}');

      final responseBody = jsonDecode(response.body);

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
      final url = '$baseUrl/auth/login';
      print('🔵 [AuthRepository] Making POST request to: $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': user.email,
              'password': user.password,
              'role': role,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('🔵 [AuthRepository] HTTP Status Code: ${response.statusCode}');
      print('🔵 [AuthRepository] Response Body: ${response.body}');

      final responseBody = jsonDecode(response.body);

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
    } catch (e) {
      print('🔴 [AuthRepository] Exception caught: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email, String role) async {
    try {
      final url = '$baseUrl/auth/forgot-password';
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'role': role}),
          )
          .timeout(const Duration(seconds: 30));

      final responseBody = jsonDecode(response.body);

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
      final url = '$baseUrl/auth/verify-otp';
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'role': role, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 30));

      final responseBody = jsonDecode(response.body);

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
      final url = '$baseUrl/auth/reset-password';
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'role': role,
              'new_password': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final responseBody = jsonDecode(response.body);

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
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
