// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationModel _$NotificationModelFromJson(Map<String, dynamic> json) =>
    NotificationModel(
      id: json['id'] as String,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['is_read'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$NotificationModelToJson(NotificationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'title': instance.title,
      'message': instance.message,
      'timestamp': instance.timestamp.toIso8601String(),
      'is_read': instance.isRead,
      'metadata': instance.metadata,
    };

const _$NotificationTypeEnumMap = {
  NotificationType.timetableUpdate: 'timetable_update',
  NotificationType.attendanceConfirmation: 'attendance_confirmation',
  NotificationType.criticalAlert: 'critical_alert',
  NotificationType.general: 'general',
};

NotificationResponse _$NotificationResponseFromJson(
  Map<String, dynamic> json,
) => NotificationResponse(
  notifications: (json['notifications'] as List<dynamic>)
      .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  pagination: PaginationInfo.fromJson(
    json['pagination'] as Map<String, dynamic>,
  ),
  success: json['success'] as bool? ?? true,
  message: json['message'] as String?,
);

Map<String, dynamic> _$NotificationResponseToJson(
  NotificationResponse instance,
) => <String, dynamic>{
  'notifications': instance.notifications,
  'pagination': instance.pagination,
  'success': instance.success,
  'message': instance.message,
};

PaginationInfo _$PaginationInfoFromJson(Map<String, dynamic> json) =>
    PaginationInfo(
      currentPage: (json['current_page'] as num).toInt(),
      totalPages: (json['total_pages'] as num).toInt(),
      totalCount: (json['total_count'] as num).toInt(),
      hasMore: json['has_more'] as bool,
    );

Map<String, dynamic> _$PaginationInfoToJson(PaginationInfo instance) =>
    <String, dynamic>{
      'current_page': instance.currentPage,
      'total_pages': instance.totalPages,
      'total_count': instance.totalCount,
      'has_more': instance.hasMore,
    };

UpdateNotificationRequest _$UpdateNotificationRequestFromJson(
  Map<String, dynamic> json,
) => UpdateNotificationRequest(
  notificationId: json['notificationId'] as String,
  isRead: json['is_read'] as bool,
  isDismissed: json['is_dismissed'] as bool?,
);

Map<String, dynamic> _$UpdateNotificationRequestToJson(
  UpdateNotificationRequest instance,
) => <String, dynamic>{
  'notificationId': instance.notificationId,
  'is_read': instance.isRead,
  'is_dismissed': instance.isDismissed,
};

GetNotificationsRequest _$GetNotificationsRequestFromJson(
  Map<String, dynamic> json,
) => GetNotificationsRequest(
  page: (json['page'] as num?)?.toInt() ?? 1,
  limit: (json['limit'] as num?)?.toInt() ?? 20,
  type: $enumDecodeNullable(_$NotificationTypeEnumMap, json['type']),
  unreadOnly: json['unread_only'] as bool? ?? false,
);

Map<String, dynamic> _$GetNotificationsRequestToJson(
  GetNotificationsRequest instance,
) => <String, dynamic>{
  'page': instance.page,
  'limit': instance.limit,
  'type': _$NotificationTypeEnumMap[instance.type],
  'unread_only': instance.unreadOnly,
};
