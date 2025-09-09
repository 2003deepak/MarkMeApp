import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import '../models/user_model.dart';

class AuthRepository {
  final String baseUrl;

  AuthRepository() : baseUrl = dotenv.env['BASE_URL'] ??
      (throw Exception('BASE_URL not found in .env file'));

  Future<Map<String, dynamic>> registerUser(User user) async {
    print('🔵 [AuthRepository] registerUser called with email: ${user.email}');
    
    try {
      final url = '$baseUrl/student/register';
      print('🔵 [AuthRepository] Making POST request to: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'first_name': user.firstName,
          'last_name': user.lastName,
          'email': user.email,
          'password': user.password,
        }),
      );

      print('🔵 [AuthRepository] HTTP Status Code: ${response.statusCode}');
      print('🔵 [AuthRepository] Response Body: ${response.body}');

      if (response.statusCode != 200) {
        print('🔴 [AuthRepository] Registration failed with status: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Server responded with status: ${response.statusCode}',
        };
      }

      final dynamic responseBody = jsonDecode(response.body);

      if (responseBody is! Map<String, dynamic>) {
        print('🔴 [AuthRepository] Invalid response format');
        return {
          'success': false,
          'error': 'Invalid response format from server',
        };
      }

      final responseData = responseBody;

      if (responseData['status'] == 'success') {
        print('🟢 [AuthRepository] Registration successful');
        return {'success': true, 'data': responseData['data']};
      } else {
        print('🔴 [AuthRepository] Registration failed: ${responseData['message']}');
        return {
          'success': false,
          'error': responseData['message'] ?? 'Unknown error occurred',
        };
      }
    } catch (e) {
      print('🔴 [AuthRepository] Exception caught: $e');
      return {'success': false, 'error': 'Exception: $e'};
    }
  }

  /// Login with role-based endpoint - FIXED ENDPOINT PATHS
  Future<Map<String, dynamic>> loginUser(User user, String role) async {
    print('🔵 [AuthRepository] loginUser called with email: ${user.email}, role: $role');
    
    String endpoint;

    endpoint = 'auth/login';

    try {
      final url = '$baseUrl$endpoint';
      print('🔵 [AuthRepository] Making POST request to: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'email': user.email,
          'password': user.password,
          'role': role, // Added role parameter as per your working API
        }),
      );

      print('🔵 [AuthRepository] HTTP Status Code: ${response.statusCode}');
      print('🔵 [AuthRepository] Response Body: ${response.body}');

      if (response.statusCode != 200) {
        print('🔴 [AuthRepository] Login failed with status: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Server responded with status: ${response.statusCode}',
        };
      }

      final dynamic responseBody = jsonDecode(response.body);

      if (responseBody is! Map<String, dynamic>) {
        print('🔴 [AuthRepository] Invalid response format');
        return {
          'success': false,
          'error': 'Invalid response format from server',
        };
      }

      final responseData = responseBody;

      if (responseData['status'] == 'success') {
        print('🟢 [AuthRepository] Login successful');
        return {
          'success': true,
          'data': {
            ...responseData['data'],
            'role': role,
          },
        };
      } else {
        print('🔴 [AuthRepository] Login failed: ${responseData['message']}');
        return {
          'success': false,
          'error': responseData['message'] ?? 'Unknown error occurred',
        };
      }
    } catch (e) {
      print('🔴 [AuthRepository] Exception caught: $e');
      return {'success': false, 'error': 'Exception: $e'};
    }
  }
}