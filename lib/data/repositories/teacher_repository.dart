import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:markmeapp/core/network/api_client.dart';
import 'package:markmeapp/core/utils/data_filter.dart';
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
      print("🔵 Preparing notification request body…");

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

      print("📤 Final Request Body → $body");

      final response = await _dio.post('/notification/notify', data: body);

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
              print('JSON Parse Error: $e');
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
      print('🔵 [TeacherRepository] Fetching students for attendance...');

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
      print("📦 [TeacherRepository] API Response: $responseBody");

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
      print('🔴 [TeacherRepository] DioException: ${e.message}');
      return {
        'success': false,
        'error':
            e.response?.data?['message'] ?? e.message ?? "Unknown Dio Error",
      };
    } catch (e) {
      print('🔴 [TeacherRepository] Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> saveAttendance(
    String attendanceId,
    String attendance,
    List<dynamic> presentStudents,
    List<dynamic> absentStudents,
  ) async {
    try {
      final url = '/teacher/attendance/mark-attendance';
      print('🔵 [AuthRepository] Making POST request to: $url');

      final response = await _dio.post(
        url,
        data: {
          'attendance_id': attendanceId,
          'attendance_student': attendance,
          'present_students': presentStudents,
          'absent_students': absentStudents,
        },
      );

      print('🔵 [AuthRepository] HTTP Status Code: ${response.statusCode}');
      print('🔵 [AuthRepository] Response Body: ${response.data}');

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
      print('🔴 [AuthRepository] DioException caught: $e');
      print('🔴 [AuthRepository] Error response: ${e.response?.data}');

      final errorMessage =
          e.response?.data?['message'] ?? e.message ?? 'Network error occurred';
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      print('🔴 [AuthRepository] Exception caught: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}

// Provider for StudentRepository
final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TeacherRepository(dio);
});
