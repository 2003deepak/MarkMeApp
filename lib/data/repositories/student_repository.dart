import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/core/network/api_client.dart';
import 'package:markmeapp/core/utils/app_logger.dart';

class StudentRepository {
  final Dio _dio;

  StudentRepository(this._dio);

  Future<Map<String, dynamic>> fetchProfile() async {
    try {
      AppLogger.info('🔵 [StudentRepository] Fetching student profile');

      final response = await _dio.get('/student/me');
      final responseBody = response.data;

      // AppLogger.info("The response in repo is $responseBody");

      if (response.statusCode == 200) {
        AppLogger.info('🟢 [StudentRepository] Profile fetched successfully');
        return {'success': true, 'data': responseBody['data']};
      } else {
        return {
          'success': false,
          'error': responseBody['message'] ?? 'Failed to fetch profile',
        };
      }
    } on DioException catch (e) {
      AppLogger.error('🔴 [StudentRepository] DioException: ${e.message}');

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
      AppLogger.error('🔴 [StudentRepository] Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateProfile(FormData formData) async {
    try {
      AppLogger.info(
        '🔵 [StudentRepository] Updating student profile with FormData',
      );

      // Log form data for debugging
      AppLogger.info('📦 FormData fields:');
      for (final field in formData.fields) {
        AppLogger.info('  ${field.key}: ${field.value}');
      }
      AppLogger.info('📦 FormData files:');
      for (final file in formData.files) {
        AppLogger.info('  ${file.key}: ${file.value.filename}');
      }

      // Send PUT request to the correct endpoint
      final response = await _dio.put(
        '/student/me/update-profile',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {'Accept': 'application/json'},
        ),
      );

      final responseBody = response.data;
      AppLogger.info(
        '🟢 [StudentRepository] Profile update response: $responseBody',
      );

      if (response.statusCode == 200) {
        AppLogger.info('🟢 [StudentRepository] Profile updated successfully');

        // Handle success response based on backend structure
        if (responseBody['status'] == 'success') {
          return responseBody;
        } else {
          return responseBody;
        }
      } else if (response.statusCode == 400) {
        // Handle 400 - Bad Request (email already in use, etc.)
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Bad request',
        };
      } else if (response.statusCode == 403) {
        // Handle 403 - Forbidden (not a student)
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Access forbidden',
        };
      } else if (response.statusCode == 404) {
        // Handle 404 - Student not found
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Student not found',
        };
      } else if (response.statusCode == 422) {
        // Handle 422 - Validation error
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Validation failed',
        };
      } else {
        // Handle other error status codes
        return {
          'success': false,
          'message':
              responseBody['message'] ??
              'Failed to update profile. Status: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      AppLogger.error('🔴 [StudentRepository] DioException: ${e.message}');
      AppLogger.error('🔴 [StudentRepository] Error type: ${e.type}');

      // Handle different DioException types
      if (e.response != null) {
        // Server responded with error status code
        final errorData = e.response!.data;
        final statusCode = e.response!.statusCode;

        AppLogger.error('🔴 [StudentRepository] Error response: $errorData');
        AppLogger.error('🔴 [StudentRepository] Status code: $statusCode');

        String errorMessage;

        switch (statusCode) {
          case 400:
            errorMessage =
                errorData?['message'] ?? 'Bad request - invalid data';
            break;
          case 403:
            errorMessage =
                errorData?['message'] ??
                'Access forbidden - only students can update profile';
            break;
          case 404:
            errorMessage = errorData?['message'] ?? 'Student profile not found';
            break;
          case 422:
            errorMessage =
                errorData?['message'] ??
                'Validation failed - check your input data';
            break;
          case 500:
            errorMessage =
                errorData?['message'] ??
                'Server error - please try again later';
            break;
          default:
            errorMessage =
                errorData?['message'] ??
                e.message ??
                'Failed to update profile';
        }

        return {
          'status': 'fail',
          'message': errorMessage,
          'errorCode': statusCode,
        };
      } else {
        // No response from server (network error, etc.)
        String errorMessage;

        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            errorMessage = 'Request timeout - please check your connection';
            break;
          case DioExceptionType.connectionError:
            errorMessage =
                'Connection error - please check your internet connection';
            break;
          case DioExceptionType.badCertificate:
            errorMessage = 'Security error - invalid certificate';
            break;
          case DioExceptionType.cancel:
            errorMessage = 'Request cancelled';
            break;
          default:
            errorMessage = e.message ?? 'Network error occurred';
        }

        return {'status': 'fail', 'message': errorMessage, 'errorCode': null};
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '🔴 [StudentRepository] Unexpected Exception: $e',
        e,
        stackTrace,
      );
      return {
        'status': 'fail',
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> fetchStudentAttendance() async {
    try {
      // ✅ Correct API endpoint
      final response = await _dio.get('/attendance/student/summary');

      final responseBody = response.data;
      

      // ✅ Handle 200 OK response
      if (response.statusCode == 200) {
        final success = responseBody['success'] ?? false;

        if (success) {
        
          return {
            'success': true,
            'message': responseBody['message'] ?? 'Fetched successfully',
            'data': responseBody['data'],
            'source': responseBody['source'] ?? 'unknown',
          };
        } else {
          AppLogger.warning(
            '⚠️ [StudentRepository] Attendance fetch failed (API returned success=false)',
          );
          return {
            'success': false,
            'message': responseBody['message'] ?? 'Something went wrong',
            'data': responseBody['data'] ?? {},
          };
        }
      }

      // ✅ Handle other non-200 status codes
      final message = responseBody['message'] ?? 'Unexpected error';
      return {
        'success': false,
        'message':
            'Request failed. Status: ${response.statusCode}, Message: $message',
        'data': responseBody['data'] ?? {},
      };
    } on DioException catch (e) {
      AppLogger.error('🔴 [StudentRepository] DioException: ${e.message}');
      AppLogger.error('🔴 [StudentRepository] Error type: ${e.type}');

      if (e.response != null) {
        final errorData = e.response!.data;
        final statusCode = e.response!.statusCode;
        AppLogger.error('🔴 [StudentRepository] Error response: $errorData');
        AppLogger.error('🔴 [StudentRepository] Status code: $statusCode');

        return {
          'success': false,
          'message': errorData?['message'] ?? 'Server returned error',
          'errorCode': statusCode,
        };
      } else {
        // Network or timeout issue
        String errorMessage;
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            errorMessage =
                '⏳ Request timeout. Please check your internet connection.';
            break;
          case DioExceptionType.connectionError:
            errorMessage = '⚠️ Connection error. Please check your network.';
            break;
          case DioExceptionType.badCertificate:
            errorMessage = '🚫 Security error - invalid SSL certificate.';
            break;
          case DioExceptionType.cancel:
            errorMessage = '❌ Request cancelled.';
            break;
          default:
            errorMessage = e.message ?? 'Network error occurred.';
        }

        return {'success': false, 'message': errorMessage, 'errorCode': null};
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '💥 [StudentRepository] Unexpected Exception: $e',
        e,
        stackTrace,
      );
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> fetchTimeTable({
    required String program,
    required String dept,
    required String sem,
    required String batch,
  }) async {
    try {
      AppLogger.info('🔵 [StudentRepository] Fetching student timetable');
      AppLogger.info(
        '➡️ Params: program=$program, dept=$dept, sem=$sem, batch=$batch',
      );

      final response = await _dio.get('/timetable/$program/$dept/$sem/$batch');
      final responseBody = response.data;

      // AppLogger.info("📦 [StudentRepository] Response: $responseBody");

      if (response.statusCode == 200) {
        AppLogger.info('🟢 [StudentRepository] Timetable fetched successfully');
        return {'success': true, 'data': responseBody['data']};
      } else {
        return {
          'success': false,
          'error': responseBody['message'] ?? 'Failed to fetch timetable',
        };
      }
    } on DioException catch (e) {
      AppLogger.error('🔴 [StudentRepository] DioException: ${e.message}');

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
      AppLogger.error('🔴 [StudentRepository] Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchUpcomingSessions() async {
    try {
      final response = await _dio.get('/student/current-session');
      final responseBody = response.data;

      // AppLogger.info("📦 [StudentRepository] Response: $responseBody");

      if (response.statusCode == 200) {
        AppLogger.info('🟢 [StudentRepository] Current fetched successfully');
        return {'success': true, 'data': responseBody['data']};
      } else {
        return {
          'success': false,
          'error': responseBody['message'] ?? 'Failed to fetch timetable',
        };
      }
    } on DioException catch (e) {
      // 🔥 Handle 400 Bad Request (e.g., Incomplete Profile)
      if (e.response != null && e.response!.statusCode == 400) {
        final errorData = e.response!.data;
        return {
          'success': false,
          'message': errorData['message'] ?? 'Bad Request',
          'missing_fields': errorData['missing_fields'], // Pass this through
          'error': errorData['message'], // For backward compat
        };
      }
      
      AppLogger.error('🔴 [StudentRepository] DioException: ${e.message}');

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
      AppLogger.error('🔴 [StudentRepository] Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchTomorrowBunkSafety() async {
    try {
      final response = await _dio.get('/student/tomorrow-bunk-safety');
      final responseBody = response.data;

      if (response.statusCode == 200) {
        AppLogger.info(
          '🟢 [StudentRepository] Tomorrow bunk safety fetched successfully',
        );
        return {'success': true, 'data': responseBody['data']};
      } else {
        return {
          'success': false,
          'error':
              responseBody['message'] ?? 'Failed to fetch bunk safety data',
        };
      }
    } on DioException catch (e) {
      
      if (e.response != null && e.response!.statusCode == 400) {
        final errorData = e.response!.data;
        return {
          'success': false,
          'message': errorData['message'] ?? 'Bad Request',
          'missing_fields': errorData['missing_fields'], // Pass this through
          'error': errorData['message'], // For backward compat
        };
      }
      
      AppLogger.error('🔴 [StudentRepository] DioException: ${e.message}');
      return {'success': false, 'error': e.message ?? 'Network error'};
    } catch (e) {
      AppLogger.error('🔴 [StudentRepository] Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchWeeklyBunkSafety() async {
    try {
      final response = await _dio.get('/student/weekly-bunk-safety');
      final responseBody = response.data;

      if (response.statusCode == 200) {
        AppLogger.info(
          '🟢 [StudentRepository] Weekly bunk safety fetched successfully',
        );
        return {'success': true, 'data': responseBody['data']};
      } else {
        return {
          'success': false,
          'error':
              responseBody['message'] ??
              'Failed to fetch weekly bunk safety data',
        };
      }
    } on DioException catch (e) {
      AppLogger.error('🔴 [StudentRepository] DioException: ${e.message}');
      return {'success': false, 'error': e.message ?? 'Network error'};
    } catch (e) {
      AppLogger.error('🔴 [StudentRepository] Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchAttendanceHistory({
    required int month,
    required int year,
    String? subjectId,
    String? program,
    String? semester,
    String? department,
  }) async {
    try {
      AppLogger.info(
        '🔵 [StudentRepository] Fetching attendance history for $month/$year${subjectId != null ? ' with subject $subjectId' : ''}',
      );

      final Map<String, dynamic> queryParams = {'month': month, 'year': year};

      if (subjectId != null) queryParams['subject'] = subjectId;
      if (program != null) queryParams['program'] = program;
      if (semester != null) queryParams['semester'] = semester;
      if (department != null) queryParams['department'] = department;

      final response = await _dio.get(
        '/attendance/history',
        queryParameters: queryParams,
      );
      final responseBody = response.data;

      if (response.statusCode == 200) {
        AppLogger.info(
          '🟢 [StudentRepository] Attendance history fetched successfully',
        );
        // The API returns the whole object as the response body
        return responseBody;
      } else {
        return {
          'success': false,
          'message':
              responseBody['message'] ?? 'Failed to fetch attendance history',
          'records': [],
        };
      }
    } on DioException catch (e) {
      AppLogger.error('🔴 [StudentRepository] DioException: ${e.message}');
      return {
        'success': false,
        'message': e.message ?? 'Network error',
        'records': [],
      };
    } catch (e) {
      AppLogger.error('🔴 [StudentRepository] Exception: $e');
      return {'success': false, 'message': e.toString(), 'records': []};
    }
  }
}

// Provider for StudentRepository
final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return StudentRepository(dio);
});
