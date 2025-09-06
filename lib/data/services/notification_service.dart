import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../mock/mock_notification_data.dart';

/// Service class for handling all notification-related API calls
/// This class provides methods for backend communication with detailed error handling
/// 
/// Backend developers should implement the following endpoints:
/// - GET /api/notifications - Fetch paginated notifications
/// - PUT /api/notifications/{id}/status - Update notification read status
/// - DELETE /api/notifications/{id} - Delete/dismiss notification
/// - POST /api/notifications/mark-all-read - Mark all notifications as read
class NotificationService {
  /// Base URL for the API
  /// Backend developers should replace this with their actual API base URL
  static const String _baseUrl = 'https://your-api-domain.com/api';
  
  /// Flag to use mock data when backend is not available
  /// Set this to false when backend is ready
  static const bool useMockData = true;
  
  /// HTTP client instance for making requests
  final http.Client _client;
  
  /// Authentication token for API requests
  /// This should be obtained from your authentication service
  String? _authToken;

  NotificationService({http.Client? client}) : _client = client ?? http.Client();

  /// Sets the authentication token for API requests
  /// Call this method after user login to authenticate API calls
  /// 
  /// Backend developers: All API endpoints should validate this JWT token
  /// Expected header format: "Authorization: Bearer {token}"
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Gets common headers for API requests
  /// Backend developers: Expect these headers in all API calls
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  /// Fetches notifications from the backend with pagination and filtering
  /// 
  /// Backend API Endpoint: GET /api/notifications
  /// 
  /// Query Parameters:
  /// - page: int (1-based pagination)
  /// - limit: int (notifications per page, recommended: 20)
  /// - type: string (optional filter: 'timetable_update', 'attendance_confirmation', 'critical_alert', 'general')
  /// - unread_only: boolean (filter for unread notifications only)
  /// 
  /// Expected Backend Response (200 OK):
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "notifications": [
  ///       {
  ///         "id": "notification_id",
  ///         "type": "timetable_update",
  ///         "title": "Tomorrow's Timetable Updated",
  ///         "message": "Check the updated schedule for your classes tomorrow.",
  ///         "timestamp": "2024-01-01T10:00:00Z",
  ///         "is_read": false,
  ///         "metadata": {
  ///           "class_id": "CS101",
  ///           "subject": "Computer Science"
  ///         }
  ///       }
  ///     ],
  ///     "pagination": {
  ///       "current_page": 1,
  ///       "total_pages": 5,
  ///       "total_count": 100,
  ///       "has_more": true
  ///     }
  ///   }
  /// }
  /// 
  /// Backend Error Responses:
  /// - 401 Unauthorized: Invalid or expired token
  /// - 403 Forbidden: User doesn't have permission
  /// - 500 Internal Server Error: Server-side error
  Future<NotificationResponse> getNotifications({
    int page = 1,
    int limit = 20,
    NotificationType? type,
    bool unreadOnly = false,
  }) async {
    // Use mock data if backend is not available
    if (useMockData) {
      print('🔄 Using mock notification data (backend not connected)');
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      return MockNotificationData.getMockNotificationResponse(
        page: page,
        limit: limit,
        type: type,
        unreadOnly: unreadOnly,
      );
    }
    
    try {
      // Construct query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'unread_only': unreadOnly.toString(),
      };
      
      if (type != null) {
        queryParams['type'] = _getTypeString(type);
      }
      
      // Build URL with query parameters
      final uri = Uri.parse('$_baseUrl/notifications').replace(
        queryParameters: queryParams,
      );
      
      print('🌐 API Call: GET $uri'); // Debug log for backend developers
      print('📋 Headers: $_headers'); // Debug log for backend developers
      
      // Make HTTP GET request
      final response = await _client.get(uri, headers: _headers);
      
      print('📥 Response Status: ${response.statusCode}'); // Debug log
      print('📥 Response Body: ${response.body}'); // Debug log
      
      // Handle different HTTP status codes
      switch (response.statusCode) {
        case 200:
          // Success - parse response
          final jsonData = json.decode(response.body) as Map<String, dynamic>;
          
          // Backend developers: Ensure your API returns data in this structure
          if (jsonData['success'] == true && jsonData['data'] != null) {
            final data = jsonData['data'] as Map<String, dynamic>;
            
            // Parse notifications array
            final notificationsJson = data['notifications'] as List<dynamic>;
            final notifications = notificationsJson
                .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
                .toList();
            
            // Parse pagination info
            final paginationJson = data['pagination'] as Map<String, dynamic>;
            final pagination = PaginationInfo.fromJson(paginationJson);
            
            return NotificationResponse(
              notifications: notifications,
              pagination: pagination,
              success: true,
              message: jsonData['message'] as String?,
            );
          } else {
            throw Exception('Invalid response format from server');
          }
          
        case 401:
          // Unauthorized - token invalid or expired
          throw UnauthorizedException('Authentication token is invalid or expired');
          
        case 403:
          // Forbidden - user doesn't have permission
          throw ForbiddenException('You don\'t have permission to access notifications');
          
        case 404:
          // Not found - endpoint doesn't exist
          throw NotFoundException('Notifications endpoint not found');
          
        case 429:
          // Rate limited
          throw RateLimitException('Too many requests. Please try again later');
          
        case 500:
        case 502:
        case 503:
          // Server errors
          throw ServerException('Server error occurred. Please try again later');
          
        default:
          throw Exception('Unexpected error: ${response.statusCode} - ${response.body}');
      }
      
    } on SocketException {
      // Network connectivity issues
      throw NetworkException('No internet connection. Please check your network and try again');
    } on FormatException {
      // JSON parsing errors
      throw DataException('Invalid data received from server');
    } catch (e) {
      // Re-throw custom exceptions, wrap others
      if (e is NotificationException) {
        rethrow;
      }
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  /// Updates the read status of a specific notification
  /// 
  /// Backend API Endpoint: PUT /api/notifications/{id}/status
  /// 
  /// Request Body:
  /// {
  ///   "is_read": true,
  ///   "is_dismissed": false // optional
  /// }
  /// 
  /// Expected Backend Response (200 OK):
  /// {
  ///   "success": true,
  ///   "message": "Notification status updated successfully"
  /// }
  /// 
  /// Backend developers should:
  /// 1. Validate the notification ID exists and belongs to the authenticated user
  /// 2. Update the notification's read status in the database
  /// 3. Return success confirmation
  Future<bool> updateNotificationStatus({
    required String notificationId,
    required bool isRead,
    bool? isDismissed,
  }) async {
    // Use mock data if backend is not available
    if (useMockData) {
      print('🔄 Using mock notification update (backend not connected)');
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));
      
      return MockNotificationData.markAsRead(notificationId);
    }
    
    try {
      final url = '$_baseUrl/notifications/$notificationId/status';
      final requestBody = {
        'is_read': isRead,
        if (isDismissed != null) 'is_dismissed': isDismissed,
      };
      
      print('🌐 API Call: PUT $url'); // Debug log
      print('📤 Request Body: ${json.encode(requestBody)}'); // Debug log
      
      final response = await _client.put(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      );
      
      print('📥 Response Status: ${response.statusCode}'); // Debug log
      print('📥 Response Body: ${response.body}'); // Debug log
      
      switch (response.statusCode) {
        case 200:
          final jsonData = json.decode(response.body) as Map<String, dynamic>;
          return jsonData['success'] == true;
          
        case 401:
          throw UnauthorizedException('Authentication required');
          
        case 403:
          throw ForbiddenException('You don\'t have permission to update this notification');
          
        case 404:
          throw NotFoundException('Notification not found');
          
        default:
          throw Exception('Failed to update notification status: ${response.statusCode}');
      }
      
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is NotificationException) {
        rethrow;
      }
      throw Exception('Failed to update notification status: $e');
    }
  }

  /// Deletes/dismisses a notification
  /// 
  /// Backend API Endpoint: DELETE /api/notifications/{id}
  /// 
  /// Expected Backend Response (204 No Content or 200 OK):
  /// {
  ///   "success": true,
  ///   "message": "Notification deleted successfully"
  /// }
  /// 
  /// Backend developers should:
  /// 1. Validate the notification ID exists and belongs to the authenticated user
  /// 2. Soft delete or hard delete the notification based on business logic
  /// 3. Return success confirmation
  Future<bool> deleteNotification(String notificationId) async {
    // Use mock data if backend is not available
    if (useMockData) {
      print('🔄 Using mock notification deletion (backend not connected)');
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));
      
      return MockNotificationData.deleteNotification(notificationId);
    }
    
    try {
      final url = '$_baseUrl/notifications/$notificationId';
      
      print('🌐 API Call: DELETE $url'); // Debug log
      
      final response = await _client.delete(
        Uri.parse(url),
        headers: _headers,
      );
      
      print('📥 Response Status: ${response.statusCode}'); // Debug log
      
      switch (response.statusCode) {
        case 200:
        case 204:
          return true;
          
        case 401:
          throw UnauthorizedException('Authentication required');
          
        case 403:
          throw ForbiddenException('You don\'t have permission to delete this notification');
          
        case 404:
          throw NotFoundException('Notification not found');
          
        default:
          throw Exception('Failed to delete notification: ${response.statusCode}');
      }
      
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is NotificationException) {
        rethrow;
      }
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Marks all notifications as read for the current user
  /// 
  /// Backend API Endpoint: POST /api/notifications/mark-all-read
  /// 
  /// Expected Backend Response (200 OK):
  /// {
  ///   "success": true,
  ///   "message": "All notifications marked as read",
  ///   "updated_count": 15
  /// }
  Future<bool> markAllAsRead() async {
    // Use mock data if backend is not available
    if (useMockData) {
      print('🔄 Using mock mark all as read (backend not connected)');
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      return MockNotificationData.markAllAsRead();
    }
    
    try {
      final url = '$_baseUrl/notifications/mark-all-read';
      
      print('🌐 API Call: POST $url'); // Debug log
      
      final response = await _client.post(
        Uri.parse(url),
        headers: _headers,
      );
      
      print('📥 Response Status: ${response.statusCode}'); // Debug log
      print('📥 Response Body: ${response.body}'); // Debug log
      
      switch (response.statusCode) {
        case 200:
          final jsonData = json.decode(response.body) as Map<String, dynamic>;
          return jsonData['success'] == true;
          
        case 401:
          throw UnauthorizedException('Authentication required');
          
        default:
          throw Exception('Failed to mark all notifications as read: ${response.statusCode}');
      }
      
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is NotificationException) {
        rethrow;
      }
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Helper method to convert NotificationType enum to string for API calls
  /// Backend developers should use these exact string values
  String _getTypeString(NotificationType type) {
    switch (type) {
      case NotificationType.timetableUpdate:
        return 'timetable_update';
      case NotificationType.attendanceConfirmation:
        return 'attendance_confirmation';
      case NotificationType.criticalAlert:
        return 'critical_alert';
      case NotificationType.general:
        return 'general';
    }
  }

  /// Disposes the HTTP client
  void dispose() {
    _client.close();
  }
}

/// Base class for notification-related exceptions
abstract class NotificationException implements Exception {
  final String message;
  const NotificationException(this.message);
  
  @override
  String toString() => message;
}

/// Exception for network connectivity issues
class NetworkException extends NotificationException {
  const NetworkException(String message) : super(message);
}

/// Exception for authentication failures (401)
class UnauthorizedException extends NotificationException {
  const UnauthorizedException(String message) : super(message);
}

/// Exception for permission issues (403)
class ForbiddenException extends NotificationException {
  const ForbiddenException(String message) : super(message);
}

/// Exception for resource not found (404)
class NotFoundException extends NotificationException {
  const NotFoundException(String message) : super(message);
}

/// Exception for rate limiting (429)
class RateLimitException extends NotificationException {
  const RateLimitException(String message) : super(message);
}

/// Exception for server errors (5xx)
class ServerException extends NotificationException {
  const ServerException(String message) : super(message);
}

/// Exception for data parsing issues
class DataException extends NotificationException {
  const DataException(String message) : super(message);
}