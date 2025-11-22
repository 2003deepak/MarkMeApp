import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/core/network/api_client.dart';
import '../models/notification_model.dart';

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

  Future<Map<String, dynamic>> notify(AppNotification notification) async {
    try {
      final response = await _dio.post(
        '/notification/notify',

        data: {
          'user': notification.user,
          'title': notification.title,
          'dept': notification.dept,
          'program': notification.program,
          "message": notification.message,
        },
      );

      return {'success': true, 'message': "Notification Send Successfully"};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'Failed to send notification',
      };
    } catch (e) {
      return {'success': false, 'error': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> fetchStudentsForNotification(
    int page,
    int limit,
    int? batchYear,
    String? program,
    String? name,
    int? semester,
  ) async {
    try {
      print('🔵 [TeacherRepository] Fetching students for notification');

      // Build params only when they are not null or not "All"
      final Map<String, dynamic> params = {'page': page, 'limit': limit};

      if (batchYear != null) params['batch_year'] = batchYear;
      if (program != null && program.isNotEmpty && program != 'All') {
        params['program'] = program;
      }
      if (name != null && name.trim().isNotEmpty) {
        params['name'] = name;
      }
      if (semester != null) params['semester'] = semester;

      print("📤 Query Params Sent → $params");

      final response = await _dio.get(
        '/teacher/subject-students',
        queryParameters: params,
      );

      final responseBody = response.data;
      print("📦 Response: $responseBody");

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseBody['data'],
          'total': responseBody['total'] ?? 0,
          'message': responseBody['message'] ?? 'Students fetched successfully',
        };
      } else {
        return {
          'success': false,
          'error': responseBody['message'] ?? 'Failed to fetch students',
        };
      }
    } on DioException catch (e) {
      print('🔴 DioException: ${e.message}');
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message,
      };
    } catch (e) {
      print('🔴 Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchClassForNotification() async {
    try {
      print('🔵 [TeacherRepository] Fetching classes for notification');

      final response = await _dio.get('/teacher/teacher-class');

      final responseBody = response.data;
      print("📦 Response: $responseBody");

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseBody['data'] ?? [],
          'total': responseBody['total_classes'] ?? 0,
          'message': responseBody['message'] ?? 'Classes fetched successfully',
        };
      } else {
        return {
          'success': false,
          'error': responseBody['message'] ?? 'Failed to fetch classes',
        };
      }
    } on DioException catch (e) {
      print('🔴 DioException: ${e.message}');
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      print('🔴 Exception: $e');
      return {'success': false, 'error': 'An unexpected error occurred'};
    }
  }
}

// Provider for StudentRepository
final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TeacherRepository(dio);
});
