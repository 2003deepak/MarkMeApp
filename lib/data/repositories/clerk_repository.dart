import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/core/network/api_client.dart';
import 'package:markmeapp/core/utils/app_logger.dart';

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

      AppLogger.info("Request body: $requestBody");

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

      AppLogger.info("Response from API: $responseData");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Failed to create subject',
        };
      }
    } on DioException catch (e) {
      AppLogger.error("Dio error: $e");
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      AppLogger.error("Other error: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchSubjects({
    String? program,
    int? semester,
    String? mode = 'subject_teacher_listing',
  }) async {
    try {
      final Map<String, dynamic> query = {};

      if (program != null && program.trim().isNotEmpty) {
        query['program'] = program.trim();
      }

      if (semester != null) {
        query['semester'] = semester;
      }

      if (mode != null && mode.trim().isNotEmpty) {
        query['mode'] = mode.trim();
      }

      final response = await _dio.get(
        '/clerk/subject',
        queryParameters: query.isNotEmpty ? query : null,
      );

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

      AppLogger.info("Request body: $requestBody");

      final response = await _dio.post('/clerk/teacher', data: requestBody);

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

      AppLogger.info("Response from API: $responseData");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Failed to create teacher',
        };
      }
    } on DioException catch (e) {
      AppLogger.error("Dio error: $e");
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      AppLogger.error("Other error: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchStudents({
    int? batchYear,
    String? program,
    int? semester,
    String mode = 'student_listing',
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      AppLogger.info('🔵 [ClerkRepository] Fetching students...');

      // -------------------------------
      // Build query params safely
      // -------------------------------
      final Map<String, dynamic> params = {};

      if (batchYear != null) params['batch_year'] = batchYear;
      if (program != null && program.trim().isNotEmpty) {
        params['program'] = program.trim();
      }
      if (semester != null) params['semester'] = semester;

      // mode is always required
      params['mode'] = mode;

      // Optional search
      if (search != null && search.trim().isNotEmpty) {
        params['search'] = search.trim();
      }

      // Always include pagination defaults
      params['page'] = page;
      params['limit'] = limit;

      AppLogger.info("🔍 Final Query Params → $params");

      // -------------------------------
      // API Request
      // -------------------------------
      final response = await _dio.get(
        '/clerk/students',
        queryParameters: params,
      );

      final body = response.data;
      AppLogger.info("📦 API Response → $body");

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': List<Map<String, dynamic>>.from(body['data'] ?? []),
          'count': body['count'] ?? 0,
          'total': body['total'],
          'page': body['page'],
          'limit': body['limit'],
          'total_pages': body['total_pages'],
          'has_next': body['has_next'],
          'has_prev': body['has_prev'],
          'cached': body['cached'] ?? false,
          'message': body['message'] ?? "Fetched successfully",
        };
      }

      return {
        'success': false,
        'error': body['message'] ?? 'Unknown error occurred',
      };
    } on DioException catch (e) {
      AppLogger.error('🔴 DioException → ${e.message}');
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? "Network Error",
      };
    } catch (e) {
      AppLogger.error('🔴 Exception → $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchTeachers({
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      AppLogger.info('🔵 [ClerkRepository] Fetching teachers...');

      // -------------------------------
      // Build query params safely
      // -------------------------------
      final Map<String, dynamic> params = {};

      // Optional search
      if (search != null && search.trim().isNotEmpty) {
        params['search'] = search.trim();
      }

      // Always include pagination defaults
      params['page'] = page;
      params['limit'] = limit;

      AppLogger.info("🔍 Final Query Params → $params");

      // -------------------------------
      // API Request
      // -------------------------------
      final response = await _dio.get(
        '/clerk/teacher',
        queryParameters: params,
      );

      final body = response.data;
      AppLogger.info("📦 API Response → $body");

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': List<Map<String, dynamic>>.from(body['data'] ?? []),
          'count': body['count'] ?? 0,
          'total': body['total'],
          'page': body['page'],
          'limit': body['limit'],
          'total_pages': body['total_pages'],
          'has_next': body['has_next'],
          'has_prev': body['has_prev'],
          'cached': body['cached'] ?? false,
          'message': body['message'] ?? "Fetched successfully",
        };
      }

      return {
        'success': false,
        'error': body['message'] ?? 'Unknown error occurred',
      };
    } on DioException catch (e) {
      AppLogger.error('🔴 DioException → ${e.message}');
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? "Network Error",
      };
    } catch (e) {
      AppLogger.error('🔴 Exception → $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchAttendanceDetail(
    String attendanceId,
  ) async {
    try {
      final response = await _dio.get('/attendance/$attendanceId');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': response.data['message'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to fetch details',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false, // Ensure success is boolean false
        'error': e.response?.data?['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createTimeTable(
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info("Request body: $data");

      final response = await _dio.post('/timetable/', data: data);

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

      AppLogger.info("Response from API: $responseData");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Failed to create subject',
        };
      }
    } on DioException catch (e) {
      AppLogger.error("Dio error: $e");
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      AppLogger.error("Other error: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  // --- Analytics Methods ---

  Future<Map<String, dynamic>> fetchTeacherSubjectPerformance(
    String teacherId,
  ) async {
    try {
      final response = await _dio.get(
        '/clerk/teacher/$teacherId/subject-performance',
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {
          'success': false,
          'error':
              response.data['message'] ?? 'Failed to fetch performance data',
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

  Future<Map<String, dynamic>> fetchSubjectPerformanceDetail(
    String teacherId,
    String subjectId,
  ) async {
    try {
      final response = await _dio.get(
        '/clerk/teacher/$teacherId/subjects/$subjectId/performance',
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {
          'success': false,
          'error':
              response.data['message'] ?? 'Failed to fetch subject details',
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

  Future<Map<String, dynamic>> fetchSubjectInsights(
    String teacherId,
    String subjectId,
  ) async {
    try {
      final response = await _dio.get(
        '/clerk/teacher/$teacherId/subjects/$subjectId/insights',
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to fetch insights',
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
}

// Provider for ClerkRepository
final clerkRepositoryProvider = Provider<ClerkRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ClerkRepository(dio);
});
