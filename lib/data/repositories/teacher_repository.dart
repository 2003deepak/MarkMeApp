import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/core/network/api_client.dart';

class TeacherRepository {
  final Dio _dio;

  TeacherRepository(this._dio);

  Future<Map<String, dynamic>> fetchProfile() async {
    try {
      print('🔵 [StudentRepository] Fetching student profile');

      final response = await _dio.get('/teacher/me/');
      final responseBody = response.data;

      print("The response in repo is $responseBody");

      if (response.statusCode == 200) {
        print('🟢 [StudentRepository] Profile fetched successfully');
        return {'success': true, 'data': responseBody['data']};
      } else {
        return {
          'success': false,
          'error': responseBody['message'] ?? 'Failed to fetch profile',
        };
      }
    } on DioException catch (e) {
      print('🔴 [StudentRepository] DioException: ${e.message}');

      // Handle specific error cases
      if (e.response?.statusCode == 401) {
        return {'success': false, 'error': 'Authentication required'};
      } else if (e.response?.statusCode == 404) {
        return {'success': false, 'error': 'Profile not found'};
      }

      final errorMessage =
          e.response?.data?['message'] ??
          e.message ??
          'Failed to fetch profile';
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      print('🔴 [StudentRepository] Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchTimeTable() async {
    try {
      print('🔵 [TeacherRepository] Fetching student timetable');

      final response = await _dio.get('/timetable/teacher-based');
      final responseBody = response.data;

      print("📦 [TeacherRepository] Response: $responseBody");

      if (response.statusCode == 200) {
        print('🟢 [TeacherRepository] Timetable fetched successfully');
        return {'success': true, 'data': responseBody['data']};
      } else {
        return {
          'success': false,
          'error': responseBody['message'] ?? 'Failed to fetch timetable',
        };
      }
    } on DioException catch (e) {
      print('🔴 [TeacherRepository] DioException: ${e.message}');

      if (e.response?.statusCode == 401) {
        return {'success': false, 'error': 'Authentication required'};
      } else if (e.response?.statusCode == 404) {
        return {'success': false, 'error': 'Timetable not found'};
      }

      final errorMessage =
          e.response?.data?['message'] ??
          e.message ??
          'Failed to fetch timetable';
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      print('🔴 [TeacherRepository] Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // In teacher_repository.dart
  Future<Map<String, dynamic>> fetchTodaySessions() async {
    try {
      final response = await _dio.get('/teacher/current-session');

      return {
        'success': true,
        'data': {
          'upcoming': response.data['data']['upcoming'] ?? [],
          'current': response.data['data']['current'] ?? [],
          'past': response.data['data']['past'] ?? [],
        },
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'Failed to fetch sessions',
      };
    } catch (e) {
      return {'success': false, 'error': 'An unexpected error occurred'};
    }
  }
}

// Provider for StudentRepository
final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TeacherRepository(dio);
});
