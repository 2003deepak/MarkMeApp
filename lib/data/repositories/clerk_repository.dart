import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/core/network/api_client.dart';

class ClerkRepository {
  final Dio _dio;

  ClerkRepository(this._dio);

  Future<Map<String, dynamic>> fetchProfile() async {
    try {
      final response = await _dio.get('/clerk/me');

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data['data']};
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to fetch profile',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createSubject(Map<String, dynamic> data) async {
    try {
      final requestBody = {
        "subject_code": data['subject_code'],
        "subject_name": data['subject_name'],
        "department": data['department'],
        "semester": data['semester'],
        "program": data['program'],
        "component": data['component'],
        "credit": data['credit'],
      };

      print("Request body: $requestBody");

      final response = await _dio.post('/clerk/subject', data: requestBody);

      // ✅ Parse response safely
      Map<String, dynamic> responseData;
      if (response.data is String) {
        responseData = json.decode(response.data);
      } else if (response.data is Map<String, dynamic>) {
        responseData = response.data;
      } else {
        throw Exception(
          'Unexpected response type: ${response.data.runtimeType}',
        );
      }

      print("Response from API: $responseData");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Failed to create subject',
        };
      }
    } on DioException catch (e) {
      print("Dio error: ${e}");
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      print("Other error: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchSubjects() async {
    try {
      final response = await _dio.get('/clerk/subject');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data['data'],
          'message': response.data['message'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to fetch subjects',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createTeacher(Map<String, dynamic> data) async {
    try {
      // Prepare request body according to API
      final requestBody = {
        "first_name": data['first_name']?.trim() ?? '',
        "last_name": data['last_name']?.trim() ?? '',
        "email": data['email']?.trim() ?? '',
        "mobile_number":
            int.tryParse(data['mobile_number']?.toString() ?? '') ?? 0,
        "department": 'BTECH',
        "subjects_assigned": data['subjects_assigned'] ?? [],
      };

      print("Request body: $requestBody");

      final response = await _dio.post('/clerk/teacher/', data: requestBody);

      // Parse response safely
      Map<String, dynamic> responseData;
      if (response.data is String) {
        responseData = json.decode(response.data);
      } else if (response.data is Map<String, dynamic>) {
        responseData = response.data;
      } else {
        throw Exception(
          'Unexpected response type: ${response.data.runtimeType}',
        );
      }

      print("Response from API: $responseData");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Failed to create teacher',
        };
      }
    } on DioException catch (e) {
      print("Dio error: $e");
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      print("Other error: $e");
      return {'success': false, 'error': e.toString()};
    }
  }
}

// Provider for ClerkRepository
final clerkRepositoryProvider = Provider<ClerkRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ClerkRepository(dio);
});
