import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:markmeapp/core/network/api_client.dart';
import 'package:markmeapp/core/utils/data_filter.dart';
import '../models/notification_model.dart';
import 'package:markmeapp/core/utils/app_logger.dart';

class TeacherRepository {
  final Dio _dio;

  TeacherRepository(this._dio);

  Future<Map<String, dynamic>> fetchProfile() async {
    try {
      AppLogger.info('🔵 [TeacherRepository] Fetching teacher profile');

      final response = await _dio.get('/teacher/me');
      final responseBody = response.data;

      // AppLogger.info("The response in repo is $responseBody");

      if (response.statusCode == 200) {
        AppLogger.info('🟢 [TeacherRepository] Profile fetched successfully');
        return {'success': true, 'data': responseBody['data']};
      } else {
        return {
          'success': false,
          'error': responseBody['message'] ?? 'Failed to fetch profile',
        };
      }
    } on DioException catch (e) {
      AppLogger.error('🔴 [TeacherRepository] DioException: ${e.message}');

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
      AppLogger.error('🔴 [TeacherRepository] Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchTimeTable() async {
    try {
      AppLogger.info('🔵 [TeacherRepository] Fetching teacher timetable');

      final response = await _dio.get('/timetable/teacher-based');
      final responseBody = response.data;

      // AppLogger.info("📦 [TeacherRepository] Response: $responseBody");

      if (response.statusCode == 200) {
        AppLogger.info('🟢 [TeacherRepository] Timetable fetched successfully');
        return {'success': true, 'data': responseBody['data']};
      } else {
        return {
          'success': false,
          'error': responseBody['message'] ?? 'Failed to fetch timetable',
        };
      }
    } on DioException catch (e) {
      AppLogger.error('🔴 [TeacherRepository] DioException: ${e.message}');

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
      AppLogger.error('🔴 [TeacherRepository] Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

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

  Future<Map<String, dynamic>> pushNotification(
    AppNotification notification,
  ) async {
    try {
      AppLogger.info("🔵 Preparing notification request body…");

      // Build raw body
      final Map<String, dynamic> body = {
        "user": notification.user,
        "title": notification.title,
        "message": notification.message,
      };

      // Add selective target_ids only when not empty
      if (notification.targetIds != null &&
          notification.targetIds!.isNotEmpty) {
        body["target_ids"] = notification.targetIds;
      }

      // Add filter groups only when not empty
      if (notification.filters != null && notification.filters!.isNotEmpty) {
        body["filters"] = notification.filters!.map((f) {
          return {
            if (f.dept != null && f.dept!.isNotEmpty) "dept": f.dept,
            if (f.program != null && f.program!.isNotEmpty)
              "program": f.program,
            if (f.semester != null) "semester": f.semester,
            if (f.batchYear != null) "batch_year": f.batchYear,
          };
        }).toList();
      }

      AppLogger.info("📤 Final Request Body → $body");

      final response = await _dio.post(
        '/notification/push-notification',
        data: body,
      );

      return {
        'success': true,
        'message': "Notification sent successfully",
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? 'Failed to send notification',
      };
    } catch (e) {
      return {'success': false, 'error': 'An unexpected error occurred'};
    }
  }

  // Legacy support or alias
  Future<Map<String, dynamic>> notify(AppNotification notification) async {
    return pushNotification(notification);
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
      AppLogger.info(
        '🔵 [TeacherRepository] Fetching students for notification',
      );

      // Build raw params
      final rawParams = {
        'page': page,
        'limit': limit,
        'batch_year': batchYear,
        'program': program,
        'name': name?.trim(),
        'semester': semester,
      };

      // Auto-clean params
      final params = removeEmpty(rawParams);

      AppLogger.info("📤 Query Params Sent → $params");

      final response = await _dio.get(
        '/teacher/subject-students',
        queryParameters: params,
      );

      final responseBody = response.data;
      AppLogger.info("📦 Response: $responseBody");

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
      AppLogger.error('🔴 DioException: ${e.message}');
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message,
      };
    } catch (e) {
      AppLogger.error('🔴 Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchClassForNotification() async {
    try {
      AppLogger.info(
        '🔵 [TeacherRepository] Fetching classes for notification',
      );

      final response = await _dio.get('/teacher/teacher-class');

      final responseBody = response.data;
      AppLogger.info("📦 Response: $responseBody");

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
      AppLogger.error('🔴 DioException: ${e.message}');
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      AppLogger.error('🔴 Exception: $e');
      return {'success': false, 'error': 'An unexpected error occurred'};
    }
  }

  // In TeacherRepository
  Stream<Map<String, dynamic>> recognizeStudent(
    String attendanceId,
    List<XFile> images,
  ) async* {
    final url = "/teacher/session/recognize/$attendanceId";
    final formData = FormData();

    for (var img in images) {
      formData.files.add(
        MapEntry(
          "images",
          await MultipartFile.fromFile(img.path, filename: img.name),
        ),
      );
    }

    final response = await _dio.post(
      url,
      data: formData,
      options: Options(
        headers: {
          "Content-Type": "multipart/form-data",
          "Accept": "text/event-stream",
        },
        responseType: ResponseType.stream,
      ),
    );

    final stream = response.data.stream;

    await for (final chunk in stream) {
      final text = String.fromCharCodes(chunk);
      for (var line in text.split("\n")) {
        if (line.startsWith("data:")) {
          final jsonString = line.replaceFirst("data:", "").trim();
          if (jsonString.isNotEmpty) {
            try {
              final data = jsonDecode(jsonString);
              yield data; // Stream the data to UI
            } catch (e) {
              AppLogger.error('JSON Parse Error: $e');
            }
          }
        }
      }
    }
  }

  Future<Map<String, dynamic>> fetchStudentsForAttendance({
    required int batchYear,
    required String program,
    required int semester,
  }) async {
    try {
      AppLogger.info(
        '🔵 [TeacherRepository] Fetching students for attendance...',
      );

      final response = await _dio.get(
        '/teacher/student',
        queryParameters: {
          'batch_year': batchYear,
          'program': program.trim(),
          'semester': semester,
          'mode': 'attendance',
        },
      );

      final responseBody = response.data;
      AppLogger.info("📦 [TeacherRepository] API Response: $responseBody");

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': List<Map<String, dynamic>>.from(responseBody['data'] ?? []),
          'count': responseBody['count'] ?? responseBody['data']?.length ?? 0,
          'message': responseBody['message'] ?? 'Students fetched successfully',
        };
      }

      return {
        'success': false,
        'error': responseBody['message'] ?? 'Failed to fetch students',
      };
    } on DioException catch (e) {
      AppLogger.error('🔴 [TeacherRepository] DioException: ${e.message}');
      return {
        'success': false,
        'error':
            e.response?.data?['message'] ?? e.message ?? "Unknown Dio Error",
      };
    } catch (e) {
      AppLogger.error('🔴 [TeacherRepository] Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> saveAttendance(
    String attendanceId,
    String attendance,
  ) async {
    try {
      final url = '/teacher/attendance/mark-attendance';
      AppLogger.info('🔵 [AuthRepository] Making POST request to: $url');

      final response = await _dio.post(
        url,
        data: {'attendance_id': attendanceId, 'attendance_student': attendance},
      );

      AppLogger.info(
        '🔵 [AuthRepository] HTTP Status Code: ${response.statusCode}',
      );
      AppLogger.info('🔵 [AuthRepository] Response Body: ${response.data}');

      final responseBody = response.data;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Attendance saved successful',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Attendance saving failed',
        };
      }
    } on DioException catch (e) {
      AppLogger.error('🔴 [AuthRepository] DioException caught: $e');
      AppLogger.error(
        '🔴 [AuthRepository] Error response: ${e.response?.data}',
      );

      final errorMessage =
          e.response?.data?['message'] ?? e.message ?? 'Network error occurred';
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      AppLogger.error('🔴 [AuthRepository] Exception caught: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> raiseSessionException({
    required String sessionId,
    required String date,
    required String action,
    required String reason,
    String? newStartTime,
    String? newEndTime,
    bool confirmSwap = false,
  }) async {
    try {
      AppLogger.info('🔵 [TeacherRepository] Raising session exception...');
      const url = '/teacher/create-exception';

      final Map<String, dynamic> body = {
        'session_id': sessionId,
        'date': date,
        'action': action,
        'reason': reason,
        'confirm_swap': confirmSwap,
      };

      if (newStartTime != null) body['new_start_time'] = newStartTime;
      if (newEndTime != null) body['new_end_time'] = newEndTime;

      AppLogger.info("📤 Exception Payload: $body");

      final response = await _dio.post(url, data: body);
      final responseBody = response.data;

      AppLogger.info(
        "📦 [TeacherRepository] Exception Response: $responseBody",
      );

      if (responseBody['success'] == true) {
        return {
          'success': true,
          'message':
              responseBody['message'] ?? 'Request processed successfully',
          'data': responseBody['data'],
        };
      } else if (responseBody['code'] == 'OVERLAP_FOUND') {
        return {
          'success': false,
          'code': 'OVERLAP_FOUND',
          'message': responseBody['message'],
          'data': responseBody['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to process request',
        };
      }
    } on DioException catch (e) {
      AppLogger.error('🔴 [TeacherRepository] DioException: ${e.message}');
      final responseBody = e.response?.data;

      if (responseBody != null && responseBody['code'] == 'OVERLAP_FOUND') {
        return {
          'success': false,
          'code': 'OVERLAP_FOUND',
          'message': responseBody['message'],
          'data': responseBody['data'],
        };
      }

      final errorMessage =
          responseBody?['message'] ?? e.message ?? 'Network error';
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      AppLogger.error('🔴 [TeacherRepository] Exception: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  /// Fetches all requests for the teacher (Summary List)
  Future<Map<String, dynamic>> fetchRequests({
    int? year,
    String? requestType,
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      AppLogger.info('🔵 [TeacherRepository] Fetching requests...');
      const url = '/teacher/request';

      final Map<String, dynamic> queryParams = {'page': page, 'limit': limit};

      if (year != null) {
        queryParams['year'] = year;
      }

      if (requestType != null) {
        queryParams['request_type'] = requestType;
      }

      if (status != null) {
        queryParams['status'] = status;
      }

      AppLogger.info('📤 Query Params: $queryParams');

      final response = await _dio.get(url, queryParameters: queryParams);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to fetch requests',
        );
      }
    } on DioException catch (e) {
      AppLogger.error('❌ Error fetching requests: ${e.message}');
      if (e.response != null && e.response?.data != null) {
        return e.response?.data;
      }
      rethrow;
    }
  }

  /// Fetches a single request detail by ID
  Future<Map<String, dynamic>> fetchRequestDetail(String requestId) async {
    try {
      AppLogger.info(
        '🔵 [TeacherRepository] Fetching request detail: $requestId',
      );
      final url = '/teacher/request/$requestId';
      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to fetch request detail',
        );
      }
    } on DioException catch (e) {
      AppLogger.error('❌ Error fetching request detail: ${e.message}');
      if (e.response != null && e.response?.data != null) {
        return e.response?.data;
      }
      rethrow;
    }
  }

  /// Responds to a swap request (Approve/Reject)
  Future<Map<String, dynamic>> respondToSwap({
    required String swapId,
    required String action, // "APPROVE" or "REJECT"
  }) async {
    try {
      AppLogger.info(
        '🔵 [TeacherRepository] Responding to swap $swapId with $action...',
      );
      const url = '/teacher/swap-approval';
      final body = {'swap_id': swapId, 'action': action};

      final response = await _dio.post(url, data: body);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to respond to swap',
        );
      }
    } on DioException catch (e) {
      AppLogger.error('❌ Error responding to swap: ${e.message}');
      if (e.response != null && e.response?.data != null) {
        return e.response?.data;
      }
      rethrow;
    }
  }

  /// Updates attendance for a session
  Future<Map<String, dynamic>> updateAttendance(
    String attendanceId,
    String attendanceStudent,
  ) async {
    try {
      AppLogger.info('🔵 [TeacherRepository] Updating attendance...');

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
}

// Provider for StudentRepository
final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TeacherRepository(dio);
});
