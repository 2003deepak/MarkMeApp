import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/core/network/api_client.dart';
import 'package:markmeapp/core/utils/app_logger.dart';
import 'package:markmeapp/data/models/live_session_model.dart';
import 'package:markmeapp/data/models/teacher_leaderboard_model.dart';
import 'package:markmeapp/data/models/attendance_extremes_model.dart';
import 'package:markmeapp/data/models/attendance_trends_model.dart';
import 'package:markmeapp/data/models/attendance_heatmap_model.dart';

class AdminRepository {
  final Dio _dio;

  AdminRepository(this._dio);

  Future<Map<String, dynamic>> fetchProfile() async {
    try {
      final response = await _dio.get('/admin/me');

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

  Future<Map<String, dynamic>> updateProfile(FormData formData) async {
    try {
      AppLogger.info('🔵 [AdminRepository] Updating admin profile...');

      final response = await _dio.put(
        '/admin/me/',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {'Accept': 'application/json'},
        ),
      );

      final responseBody = response.data;

      if (response.statusCode == 200) {
        AppLogger.info('🟢 [AdminRepository] Profile updated successfully');
        return {'success': true, 'data': responseBody['data'], 'message': responseBody['message']};
      } else {
        return {
          'success': false,
          'error': responseBody['message'] ?? 'Failed to update profile',
        };
      }
    } on DioException catch (e) {
      AppLogger.error('🔴 [AdminRepository] DioException: ${e.message}');
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      AppLogger.error('🔴 [AdminRepository] Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  Future<Map<String, dynamic>> fetchDefaulterTeachers({
    double? rescheduleThreshold,
    double? cancellationThreshold,
    String? program,
    String? department,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'page': page,
        'limit': limit,
      };
 
      if (rescheduleThreshold != null) {
        params['reschedule_threshold'] = rescheduleThreshold;
      }
      if (cancellationThreshold != null) {
        params['cancellation_threshold'] = cancellationThreshold;
      }
      if (program != null) params['program'] = program;
      if (department != null) params['department'] = department;

      AppLogger.info('🔍 [AdminRepository] Fetching defaulter teachers: $params');

      final response = await _dio.get(
        '/admin/teacher/defaulters', 
        queryParameters: params,
      );

      final body = response.data;
      
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
          'message': body['message'] ?? "Fetched successfully",
        };
      } else {
        return {
          'success': false,
          'error': body['message'] ?? 'Failed to fetch defaulter teachers',
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

  Future<Map<String, dynamic>> fetchLiveClasses({
    String? program,
    String? department,
    String? semester,
  }) async {
    try {
      AppLogger.info('🚀 [AdminRepository] Fetching live classes...');
      final Map<String, dynamic> params = {};
      if (program != null) params['program'] = program;
      if (department != null) params['department'] = department;
      if (semester != null) params['semester'] = semester;

      final response = await _dio.get('/admin/live-classes', queryParameters: params);

      final body = response.data;

      if (response.statusCode == 200) {
        AppLogger.info('✅ [AdminRepository] Live classes fetched successfully');
        return {
          'success': true,
          'data': (body['data'] as List)
              .map((json) => LiveSession.fromJson(json))
              .toList(),
          'message': body['message'] ?? 'Fetched successfully',
        };
      } else {
        return {
          'success': false,
          'error': body['message'] ?? 'Failed to fetch live classes',
        };
      }
    } on DioException catch (e) {
      AppLogger.error('🔴 [AdminRepository] DioException: ${e.message}');
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      AppLogger.error('🔴 [AdminRepository] Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchAttendanceTrends(
    String range, {
    String? program,
    String? department,
    String? semester,
    String? subjectId,
    String? teacherId,
  }) async {
    try {
      final Map<String, dynamic> params = {'range': range};

      if (program != null) params['program'] = program;
      if (department != null) params['department'] = department;
      if (semester != null) params['semester'] = semester;
      if (subjectId != null) params['subject_id'] = subjectId;
      if (teacherId != null) params['teacher_id'] = teacherId;

      AppLogger.info('🚀 [AdminRepository] Fetching attendance trends: $params');
      final response = await _dio.get(
        '/admin/analytics/attendance-trends',
        queryParameters: params,
      );

      final body = response.data;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': AttendanceTrendsResponse.fromJson(body),
        };
      } else {
        return {
          'success': false,
          'error': body['message'] ?? 'Failed to fetch attendance trends',
        };
      }
    } on DioException catch (e) {
      AppLogger.error('🔴 [AdminRepository] DioException: ${e.message}');
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      AppLogger.error('🔴 [AdminRepository] Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }


  Future<Map<String, dynamic>> fetchTeacherLeaderboard(
    String period, {
    String? program,
    String? department,
    String? semester,
  }) async {
    try {
      AppLogger.info('🚀 [AdminRepository] Fetching teacher leaderboard for period: $period');
      final Map<String, dynamic> params = {'period': period};
      if (program != null) params['program'] = program;
      if (department != null) params['department'] = department;
      if (semester != null) params['semester'] = semester;

      final response = await _dio.get(
        '/admin/teacher-leaderboard',
        queryParameters: params,
      );

      final body = response.data;

      if (response.statusCode == 200) {
        AppLogger.info('✅ [AdminRepository] Leaderboard fetched successfully');
        return {
          'success': true,
          'data': TeacherLeaderboardResponse.fromJson(body),
        };
      } else {
        return {
          'success': false,
          'error': body['message'] ?? 'Failed to fetch leaderboard',
        };
      }
    } on DioException catch (e) {
      AppLogger.error('🔴 [AdminRepository] DioException: ${e.message}');
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      AppLogger.error('🔴 [AdminRepository] Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchAttendanceExtremes(
    String period, {
    String? program,
    String? department,
    String? semester,
  }) async {
    try {
      AppLogger.info('🚀 [AdminRepository] Fetching attendance extremes for: $period');
      final Map<String, dynamic> params = {'period': period};
      if (program != null) params['program'] = program;
      if (department != null) params['department'] = department;
      if (semester != null) params['semester'] = semester;

      final response = await _dio.get(
        '/admin/extremes',
        queryParameters: params,
      );

      final body = response.data;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': AttendanceExtremesResponse.fromJson(body),
        };
      } else {
        return {
          'success': false,
          'error': body['message'] ?? 'Failed to fetch extremes',
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

  Future<Map<String, dynamic>> downloadClassReport({
    required String program,
    required String department,
    required String semester,
    required String year,
    required String type,
  }) async {
    try {
      final String path = '/admin/download-class-report/$department/$program/$semester/$year/$type';
      AppLogger.info('🚀 [AdminRepository] Downloading class report: $path');
      
      final response = await _dio.get(path);
      final body = response.data;

      if (response.statusCode == 200 && body['success'] == true) {
        AppLogger.info('✅ [AdminRepository] Report generated successfully: ${body['file_url']}');
        return {
          'success': true,
          'message': body['message'] ?? 'Report generated successfully',
          'file_url': body['file_url'],
          'file_id': body['file_id'],
        };
      } else {
        return {
          'success': false,
          'error': body['message'] ?? 'Failed to generate report',
        };
      }
    } on DioException catch (e) {
      AppLogger.error('🔴 [AdminRepository] DioException: ${e.message}');
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      AppLogger.error('🔴 [AdminRepository] Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // --- Department and Program Management ---

  Future<Map<String, dynamic>> fetchDepartments() async {
    try {
      AppLogger.info('🚀 [AdminRepository] Fetching all departments...');
      final response = await _dio.get('/admin/departments/all');
      final body = response.data;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': body['data'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': body['message'] ?? 'Failed to fetch departments',
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

  Future<Map<String, dynamic>> fetchPrograms() async {
    try {
      AppLogger.info('🚀 [AdminRepository] Fetching all programs...');
      final response = await _dio.get('/admin/programs/all');
      final body = response.data;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': body['data'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': body['message'] ?? 'Failed to fetch programs',
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

  Future<Map<String, dynamic>> createDepartment({
    required String fullName,
    required String departmentCode,
    required String programCode,
  }) async {
    try {
      AppLogger.info('🚀 [AdminRepository] Creating department: $departmentCode');
      final response = await _dio.post(
        '/admin/department',
        data: {
          'full_name': fullName,
          'department_code': departmentCode,
          'program_code': programCode,
        },
      );
      final body = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': body['message'] ?? 'Department created successfully',
          'data': body['data'],
        };
      } else {
        return {
          'success': false,
          'error': body['message'] ?? 'Failed to create department',
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

  Future<Map<String, dynamic>> createProgram({
    required String fullName,
    required String programCode,
    required int durationYears,
  }) async {
    try {
      AppLogger.info('🚀 [AdminRepository] Creating program: $programCode');
      final response = await _dio.post(
        '/admin/program',
        data: {
          'full_name': fullName,
          'program_code': programCode,
          'duration_years': durationYears,
        },
      );
      final body = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': body['message'] ?? 'Program created successfully',
          'data': body['data'],
        };
      } else {
        return {
          'success': false,
          'error': body['message'] ?? 'Failed to create program',
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

  Future<Map<String, dynamic>> fetchHierarchicalMetadata() async {
    try {
      AppLogger.info('🚀 [AdminRepository] Fetching hierarchical metadata...');
      final response = await _dio.get('/admin/metadata/all');
      final body = response.data;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': body['data'] ?? {},
        };
      } else {
        return {
          'success': false,
          'error': body['message'] ?? 'Failed to fetch hierarchical metadata',
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

  Future<Map<String, dynamic>> createClerk({
    required String firstName,
    required String middleName,
    required String lastName,
    required String email,
    required int mobileNumber,
    required List<Map<String, String>> academicScopes,
  }) async {
    try {
      AppLogger.info('🚀 [AdminRepository] Creating clerk: $email');
      final response = await _dio.post(
        '/admin/clerk',
        data: {
          'first_name': firstName,
          'middle_name': middleName,
          'last_name': lastName,
          'email': email,
          'mobile_number': mobileNumber,
          'academic_scopes': academicScopes,
        },
      );
      final body = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': body['message'] ?? 'Clerk created successfully',
          'data': body['data'],
        };
      } else {
        return {
          'success': false,
          'error': body['message'] ?? 'Failed to create clerk',
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

  Future<Map<String, dynamic>> fetchClerks({
    String? program,
    String? department,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'page': page,
        'limit': limit,
      };
      
      if (program != null && program.isNotEmpty && program != 'All Programs') params['program'] = program;
      if (department != null && department.isNotEmpty && department != 'All Departments') params['department'] = department;
      if (search != null && search.isNotEmpty) params['search'] = search;

      AppLogger.info('🔍 [AdminRepository] Fetching clerks: $params');

      final response = await _dio.get(
        '/admin/clerk', 
        queryParameters: params,
      );

      final body = response.data;
      
      if (response.statusCode == 200 && body['success'] == true) {
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
          'message': body['message'] ?? "Fetched successfully",
        };
      } else {
        return {
          'success': false,
          'error': body['message'] ?? 'Failed to fetch clerks',
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

  Future<Map<String, dynamic>> fetchClerkDetails(String clerkId) async {
    try {
      AppLogger.info('🚀 [AdminRepository] Fetching clerk details for $clerkId...');
      final response = await _dio.get('/admin/clerk/$clerkId');
      final body = response.data;

      if (response.statusCode == 200 && body['success'] == true) {
        return {
          'success': true,
          'data': body['data'],
        };
      } else {
        return {
          'success': false,
          'error': body['message'] ?? 'Failed to fetch clerk details',
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

  Future<Map<String, dynamic>> updateClerkScopes(String clerkId, List<Map<String, String>> scopes) async {
    try {
      AppLogger.info('🚀 [AdminRepository] Updating scopes for clerk $clerkId...');
      final response = await _dio.patch(
        '/admin/clerk/$clerkId',
        data: {
          'academic_scopes': scopes,
        },
      );
      final body = response.data;

      if (response.statusCode == 200 && body['success'] == true) {
        return {
          'success': true,
          'message': body['message'] ?? 'Academic scopes updated successfully',
        };
      } else {
        return {
          'success': false,
          'error': body['message'] ?? 'Failed to update academic scopes',
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

  Future<Map<String, dynamic>> fetchAttendanceHeatmap({
    String? department,
    int? month,
    String? program,
    int? year,
    int? semester,
    int? batchYear,
  }) async {
    try {
      final Map<String, dynamic> params = {};
      if (department != null) params['department'] = department;
      if (month != null) params['month'] = month;
      if (program != null) params['program'] = program;
      if (year != null) params['year'] = year;
      if (semester != null) params['semester'] = semester;
      if (batchYear != null) params['batch_year'] = batchYear;

      AppLogger.info('🚀 [AdminRepository] Fetching attendance heatmap: $params');
      final response = await _dio.get(
        '/attendance/heatmap',
        queryParameters: params,
      );

      final body = response.data;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': AttendanceHeatmapResponse.fromJson(body).data,
        };
      } else {
        return {
          'success': false,
          'error': body['message'] ?? 'Failed to fetch attendance heatmap',
        };
      }
    } on DioException catch (e) {
      AppLogger.error('🔴 [AdminRepository] DioException: ${e.message}');
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      AppLogger.error('🔴 [AdminRepository] Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}


// Provider for AdminRepository
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AdminRepository(dio);
});
