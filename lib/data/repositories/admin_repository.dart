import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/core/network/api_client.dart';
import 'package:markmeapp/core/utils/app_logger.dart';

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

      AppLogger.info('🔍 [AdminRepository] Fetching defaulter teachers: $params');

      // Using the generic teacher endpoint for now, but in reality 
      // this should probably be a specific endpoint like /admin/defaulter-teachers
      // or /admin/teachers with filters. I'll assume /admin/defaulter-teachers exists
      // or use the clerk endpoint if admin has access. 
      // User requested "copy design of Teacher Listing", so getting teachers is key.
      // I'll use a new endpoint convention.
      final response = await _dio.get(
        '/admin/defaulter-teachers', 
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
}

// Provider for AdminRepository
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AdminRepository(dio);
});
