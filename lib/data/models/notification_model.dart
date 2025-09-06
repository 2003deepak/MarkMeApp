import 'package:json_annotation/json_annotation.dart';

part 'notification_model.g.dart';

/// Enum representing different types of notifications
/// Backend developers should use these exact string values in API responses
enum NotificationType {
  @JsonValue('timetable_update')
  timetableUpdate,
  
  @JsonValue('attendance_confirmation')
  attendanceConfirmation,
  
  @JsonValue('critical_alert')
  criticalAlert,
  
  @JsonValue('general')
  general,
}

/// Main notification data model
/// This model represents the structure expected from the backend API
/// 
/// Backend API Response Format:
/// {
///   "id": "unique_notification_id",
///   "type": "timetable_update|attendance_confirmation|critical_alert|general",
///   "title": "Notification Title",
///   "message": "Detailed notification message",
///   "timestamp": "2024-01-01T10:00:00Z", // ISO 8601 format
///   "is_read": false,
///   "metadata": {
///     "class_id": "optional_class_identifier",
///     "subject": "optional_subject_name",
///     "attendance_percentage": 75.5 // for attendance related notifications
///   }
/// }
@JsonSerializable()
class NotificationModel {
  /// Unique identifier for the notification (provided by backend)
  /// Backend should ensure this ID is unique across all notifications
  final String id;
  
  /// Type of notification - determines icon and styling
  /// Backend should use exact enum values: 'timetable_update', 'attendance_confirmation', 'critical_alert', 'general'
  final NotificationType type;
  
  /// Main title/heading of the notification
  /// Backend should keep this concise (recommended max 50 characters)
  final String title;
  
  /// Detailed message content
  /// Backend can include longer descriptions here (recommended max 200 characters for mobile display)
  final String message;
  
  /// When the notification was created/sent
  /// Backend should provide in ISO 8601 format (e.g., "2024-01-01T10:00:00Z")
  final DateTime timestamp;
  
  /// Whether the user has read this notification
  /// Backend should track and update this field when user marks as read
  @JsonKey(name: 'is_read')
  final bool isRead;
  
  /// Optional additional data specific to notification type
  /// Backend can include context-specific information here:
  /// - For timetable_update: class_id, subject, room_number, time_change
  /// - For attendance_confirmation: class_id, subject, attendance_percentage
  /// - For critical_alert: severity_level, action_required, deadline
  final Map<String, dynamic>? metadata;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  /// Factory constructor for creating NotificationModel from JSON
  /// Backend developers: This handles the JSON deserialization automatically
  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  /// Converts NotificationModel to JSON
  /// Used when sending data back to backend (e.g., for read status updates)
  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);

  /// Creates a copy of the notification with updated fields
  /// Useful for updating read status or other fields locally
  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Helper method to get formatted time string for display
  /// Returns user-friendly time format (e.g., "2 hours ago", "1 day ago")
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Response model for paginated notification API calls
/// Backend API should return notifications in this format for pagination support
/// 
/// Expected Backend Response Format:
/// {
///   "success": true,
///   "data": {
///     "notifications": [...], // Array of NotificationModel objects
///     "pagination": {
///       "current_page": 1,
///       "total_pages": 10,
///       "total_count": 200,
///       "has_more": true
///     }
///   },
///   "message": "Success" // Optional success message
/// }
@JsonSerializable()
class NotificationResponse {
  /// List of notifications for the current page
  final List<NotificationModel> notifications;
  
  /// Pagination information
  final PaginationInfo pagination;
  
  /// Success status from backend
  final bool success;
  
  /// Optional message from backend
  final String? message;

  const NotificationResponse({
    required this.notifications,
    required this.pagination,
    this.success = true,
    this.message,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationResponseToJson(this);
}

/// Pagination information model
/// Backend should provide these fields for proper pagination handling
@JsonSerializable()
class PaginationInfo {
  /// Current page number (1-based indexing)
  @JsonKey(name: 'current_page')
  final int currentPage;
  
  /// Total number of pages available
  @JsonKey(name: 'total_pages')
  final int totalPages;
  
  /// Total count of all notifications
  @JsonKey(name: 'total_count')
  final int totalCount;
  
  /// Whether more pages are available
  @JsonKey(name: 'has_more')
  final bool hasMore;

  const PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasMore,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) =>
      _$PaginationInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationInfoToJson(this);
}

/// Request model for updating notification status
/// Used when sending read/unread status updates to backend
/// 
/// Backend API Endpoint: PUT /api/notifications/{id}/status
/// Request Body Format:
/// {
///   "is_read": true,
///   "is_dismissed": false // optional field for dismissing notifications
/// }
@JsonSerializable()
class UpdateNotificationRequest {
  /// The notification ID to update
  final String notificationId;
  
  /// New read status
  @JsonKey(name: 'is_read')
  final bool isRead;
  
  /// Optional: whether to dismiss/delete the notification
  @JsonKey(name: 'is_dismissed')
  final bool? isDismissed;

  const UpdateNotificationRequest({
    required this.notificationId,
    required this.isRead,
    this.isDismissed,
  });

  factory UpdateNotificationRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateNotificationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateNotificationRequestToJson(this);
}

/// Request model for fetching notifications with filters
/// Used for API calls to get notifications with pagination and filtering
/// 
/// Backend API Endpoint: GET /api/notifications
/// Query Parameters:
/// - page: int (default: 1)
/// - limit: int (default: 20)
/// - type: string (optional) - filter by notification type
/// - unread_only: boolean (default: false)
@JsonSerializable()
class GetNotificationsRequest {
  /// Page number for pagination (1-based)
  final int page;
  
  /// Number of notifications per page
  final int limit;
  
  /// Optional filter by notification type
  final NotificationType? type;
  
  /// Whether to fetch only unread notifications
  @JsonKey(name: 'unread_only')
  final bool unreadOnly;

  const GetNotificationsRequest({
    this.page = 1,
    this.limit = 20,
    this.type,
    this.unreadOnly = false,
  });

  factory GetNotificationsRequest.fromJson(Map<String, dynamic> json) =>
      _$GetNotificationsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GetNotificationsRequestToJson(this);

  /// Converts to query parameters for HTTP GET request
  /// Backend developers can use these parameter names in their API
  Map<String, String> toQueryParameters() {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'unread_only': unreadOnly.toString(),
    };
    
    if (type != null) {
      params['type'] = type!.name;
    }
    
    return params;
  }
}