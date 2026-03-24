import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:markmeapp/data/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/core/network/api_client.dart';
import 'package:markmeapp/core/utils/app_logger.dart';

class ClerkRepository {
  final Dio _dio;

  ClerkRepository(this._dio);

  

  Future<Map<String, dynamic>> registerUser(
    User user, {
    String? program,
    String? department,
    int? semester,
  }) async {
    AppLogger.info(
      '🔵 [AuthRepository] registerUser called with email: ${user.email}',
    );

    try {
      final url = '/clerk/student';
      AppLogger.info('🔵 [AuthRepository] Making POST request to: $url');

      final response = await _dio.post(
        url,
        data: {
          'first_name': user.firstName,
          'last_name': user.lastName,
          'email': user.email,
          'password': user.password,
          if (program != null) 'program': program,
          if (department != null) 'department': department,
          if (semester != null) 'semester': semester,
        },
      );

      AppLogger.info(
        '🔵 [AuthRepository] HTTP Status Code: ${response.statusCode}',
      );
      AppLogger.info('🔵 [AuthRepository] Response Body: ${response.data}');

      final responseBody = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseBody['success'] == true) {
          AppLogger.info('🟢 [AuthRepository] Registration successful');
          return {'success': true, 'data': responseBody['data']};
        } else {
          return {
            'success': false,
            'message': responseBody['message'] ?? 'Registration failed',
            'error': responseBody['error'] ?? 'Failed to register student',
          };
        }
      } else {
        return {
          'success': false,
          'message':
              responseBody['message'] ?? 'Server error: ${response.statusCode}',
          'error': responseBody['error'] ?? 'Failed to register student',
        };
      }
    } on DioException catch (e) {
      AppLogger.error('🔴 [AuthRepository] DioException caught: $e');
      AppLogger.error(
        '🔴 [AuthRepository] Error response: ${e.response?.data}',

      );

      final errorMessage =
          e.response?.data?['message'] ?? e.message ?? 'Network error occurred';
      return {'success': false, 'message': errorMessage, 'error': e.response?.data?['error'] ?? 'Failed to register student'};
    } catch (e) {
      AppLogger.error('🔴 [AuthRepository] Exception caught: $e');
      return {'success': false, 'message': e.toString(), 'error': 'Failed to register student'};
    }
  }

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

  Future<Map<String, dynamic>> updateProfile(FormData formData) async {
    try {
      AppLogger.info('🔵 [ClerkRepository] Updating clerk profile...');

      final response = await _dio.put(
        '/clerk/me',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {'Accept': 'application/json'},
        ),
      );

      final responseBody = response.data;

      if (response.statusCode == 200) {
        AppLogger.info('🟢 [ClerkRepository] Profile updated successfully');
        return {'success': true, 'data': responseBody['data'], 'message': responseBody['message']};
      } else {
        return {
          'success': false,
          'error': responseBody['message'] ?? 'Failed to update profile',
        };
      }
    } on DioException catch (e) {
      AppLogger.error('🔴 [ClerkRepository] DioException: ${e.message}');
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      AppLogger.error('🔴 [ClerkRepository] Exception: $e');
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
          'message': responseData['message'] ?? 'Subject Created Successfully',
          'error': responseData['error'] ?? 'Failed to create subject',
        };
      }
    } on DioException catch (e) {
      AppLogger.error("Dio error: $e");
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Subject Creation Failed',
        'error': e.response?.data?['error'] ?? 'Failed to create subject',
      };
    } catch (e) {
      AppLogger.error("Other error: $e");
      return {'success': false, 'message': 'Subject Creation Failed', 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchSubjects({
    String? department,
    String? program,
    String? semester,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (program != null && program.isNotEmpty) queryParams['program'] = program;
      if (department != null && department.isNotEmpty) queryParams['department'] = department;
      if (semester != null && semester.isNotEmpty) queryParams['semester'] = semester;

      final response = await _dio.get(
        '/timetable/subject',
        queryParameters: queryParams,
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

  Future<Map<String, dynamic>> fetchAssignableSubjects() async {
    try {
      
      final response = await _dio.get(
        '/clerk/subject/assignable',
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
          'error': response.data['message'] ?? 'Failed to fetch assignable subjects',
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
        // For non-success status codes, return the error details
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create teacher',
          'error': responseData['error'], 
        };
      }
    } on DioException catch (e) {
      AppLogger.error("Dio error: $e");
      
      // Extract error details from DioException
      Map<String, dynamic> errorResponse = {};
      if (e.response?.data != null) {
        if (e.response!.data is String) {
          try {
            errorResponse = json.decode(e.response!.data);
          } catch (_) {
            errorResponse = {'message': e.response!.data};
          }
        } else if (e.response!.data is Map<String, dynamic>) {
          errorResponse = e.response!.data;
        }
      }
      
      return {
        'success': false,
        'message': errorResponse['message'] ?? e.message ?? 'Network error',
        'error': errorResponse['error'], 
        'statusCode': e.response?.statusCode,
      };
    } catch (e) {
      AppLogger.error("Other error: $e");
      return {
        'success': false, 
        'message': e.toString(),
        'error': e.toString(),
      };
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
    String? program,
    String? department,
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
      if (program != null) params['program'] = program;
      if (department != null) params['department'] = department;
 
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

  Future<Map<String, dynamic>> fetchTimeTable({
    required String program,
    required String department,
    required int semester,
    required String academicYear,
  }) async {
    try {
      final p = program.trim();
      final d = department.trim();
      final s = semester.toString();
      final ay = academicYear.trim();

      AppLogger.info('🔍 [ClerkRepository] Fetching timetable: /$p/$d/$s/$ay');

      final response = await _dio.get(
        '/timetable/$p/$d/$s/$ay',
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
          'error': response.data['message'] ?? 'Failed to fetch timetable',
        };
      }
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


  Future<Map<String, dynamic>> updateTimeTable(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info("🔵 [ClerkRepository] Updating timetable $id...");
      final response = await _dio.put('/timetable/$id/', data: data);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Timetable updated successfully',
          'data': response.data['data'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to update timetable',
        };
      }
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

  Future<Map<String, dynamic>> updateAttendance(
    String attendanceId,
    String attendanceStudent,
  ) async {
    try {
      AppLogger.info('🔵 [ClerkRepository] Updating attendance...');

      // Reuse the teacher endpoint for now as per plan, or a generic one if available.
      // Assuming backend supports this endpoint for Clerks/Admins too or valid RBAC.
      const url = '/teacher/attendance';
      final body = {
        'attendance_id': attendanceId,
        'attendance_student': attendanceStudent,
      };

      final response = await _dio.patch(url, data: body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              response.data['message'] ?? 'Attendance updated successfully',
          'data': response.data,
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to update attendance',
        };
      }
    } on DioException catch (e) {
      AppLogger.error('❌ Error updating attendance: ${e.message}');
      if (e.response != null && e.response?.data != null) {
        return e.response?.data;
      }
      return {
        'success': false,
        'message': e.message ?? 'An unexpected error occurred',
      };
    }
  }

  Future<Map<String, dynamic>> getDefaulters({
    String? search,
    String? subjectId,
    int page = 1,
    int limit = 10,
    String? program,
    int? semester,
    int? threshold,
  }) async {
    try {
      final Map<String, dynamic> params = {};

      if (search != null && search.trim().isNotEmpty) params['search'] = search;
      if (subjectId != null) params['subject_id'] = subjectId;
      if (program != null) params['program'] = program;
      if (semester != null) params['semester'] = semester;
      if (threshold != null) params['threshold'] = threshold;

      params['page'] = page;
      params['limit'] = limit;

      AppLogger.info('🔍 [ClerkRepository] Fetching defaulters: $params');

      final response = await _dio.get(
        '/clerk/defaulters',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        return response.data; // Raw JSON matching DefaultResponse structure
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to fetch defaulters',
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
