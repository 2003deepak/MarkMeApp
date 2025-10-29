import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/core/network/api_client.dart';

class StudentRepository {
  final Dio _dio;

  StudentRepository(this._dio);

  Future<Map<String, dynamic>> fetchProfile() async {
    try {
      print('🔵 [StudentRepository] Fetching student profile');

      final response = await _dio.get('/student/me/');
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

  Future<Map<String, dynamic>> updateProfile(FormData formData) async {
    try {
      print('🔵 [StudentRepository] Updating student profile with FormData');

      // Log form data for debugging
      print('📦 FormData fields:');
      for (final field in formData.fields) {
        print('  ${field.key}: ${field.value}');
      }
      print('📦 FormData files:');
      for (final file in formData.files) {
        print('  ${file.key}: ${file.value.filename}');
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
      print('🟢 [StudentRepository] Profile update response: $responseBody');

      if (response.statusCode == 200) {
        print('🟢 [StudentRepository] Profile updated successfully');

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
      print('🔴 [StudentRepository] DioException: ${e.message}');
      print('🔴 [StudentRepository] Error type: ${e.type}');

      // Handle different DioException types
      if (e.response != null) {
        // Server responded with error status code
        final errorData = e.response!.data;
        final statusCode = e.response!.statusCode;

        print('🔴 [StudentRepository] Error response: $errorData');
        print('🔴 [StudentRepository] Status code: $statusCode');

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
      print('🔴 [StudentRepository] Unexpected Exception: $e');
      print('🔴 [StudentRepository] Stack trace: $stackTrace');
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
      // print('🟢 [StudentRepository] API Response: $responseBody');

      // ✅ Handle 200 OK response
      if (response.statusCode == 200) {
        final success = responseBody['success'] ?? false;

        if (success) {
          print('✅ [StudentRepository] Attendance fetched successfully');
          return {
            'success': true,
            'message': responseBody['message'] ?? 'Fetched successfully',
            'data': responseBody['data'],
            'source': responseBody['source'] ?? 'unknown',
          };
        } else {
          print(
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
      print('🔴 [StudentRepository] DioException: ${e.message}');
      print('🔴 [StudentRepository] Error type: ${e.type}');

      if (e.response != null) {
        final errorData = e.response!.data;
        final statusCode = e.response!.statusCode;
        print('🔴 [StudentRepository] Error response: $errorData');
        print('🔴 [StudentRepository] Status code: $statusCode');

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
      print('💥 [StudentRepository] Unexpected Exception: $e');
      print('🧠 Stack trace: $stackTrace');
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
      print('🔵 [StudentRepository] Fetching student timetable');
      print('➡️ Params: program=$program, dept=$dept, sem=$sem, batch=$batch');

      final response = await _dio.get('/timetable/$program/$dept/$sem/$batch');
      final responseBody = response.data;

      // print("📦 [StudentRepository] Response: $responseBody");

      if (response.statusCode == 200) {
        print('🟢 [StudentRepository] Timetable fetched successfully');
        return {'success': true, 'data': responseBody['data']};
      } else {
        return {
          'success': false,
          'error': responseBody['message'] ?? 'Failed to fetch timetable',
        };
      }
    } on DioException catch (e) {
      print('🔴 [StudentRepository] DioException: ${e.message}');

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
      print('🔴 [StudentRepository] Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchUpcomingSessions() async {
    try {
      final response = await _dio.get('/student/current-session');
      final responseBody = response.data;

      // print("📦 [StudentRepository] Response: $responseBody");

      if (response.statusCode == 200) {
        print('🟢 [StudentRepository] Current fetched successfully');
        return {'success': true, 'data': responseBody['data']};
      } else {
        return {
          'success': false,
          'error': responseBody['message'] ?? 'Failed to fetch timetable',
        };
      }
    } on DioException catch (e) {
      print('🔴 [StudentRepository] DioException: ${e.message}');

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
      print('🔴 [StudentRepository] Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}

// Provider for StudentRepository
final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return StudentRepository(dio);
});
