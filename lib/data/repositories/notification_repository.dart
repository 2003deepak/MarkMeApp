import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:markmeapp/core/network/api_client.dart';
import '../models/notification_model.dart';
import 'package:markmeapp/core/utils/app_logger.dart';

class NotificationRepository {
  static const String boxName = 'notifications';

  final Dio? _dio;

  NotificationRepository([this._dio]);

  Future<Box<NotificationModel>> _openBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<NotificationModel>(boxName);
    }
    return Hive.box<NotificationModel>(boxName);
  }

  // Save a new notification
  Future<void> saveNotification(NotificationModel notification) async {
    try {
      final box = await _openBox();
      await box.put(notification.id, notification);
      AppLogger.info('💾 Notification saved: ${notification.title}');
    } catch (e) {
      AppLogger.error('⚠️ Failed to save notification: $e');
    }
  }

  // Get all notifications for today
  ValueListenable<Box<NotificationModel>> getListenable() {
    return Hive.box<NotificationModel>(boxName).listenable();
  }

  // Get unread count for today
  int getUnreadCount() {
    if (!Hive.isBoxOpen(boxName)) return 0;

    final box = Hive.box<NotificationModel>(boxName);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return box.values.where((n) {
      final date = n.timestamp;
      final isToday =
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      return isToday && !n.isRead;
    }).length;
  }

  // Mark a notification as read
  Future<void> markAsRead(String id) async {
    try {
      final box = await _openBox();
      final notification = box.get(id);
      if (notification != null) {
        notification.isRead = true;
        await notification.save(); // Efficient update using HiveObject
        AppLogger.info('✅ Notification marked as read: $id');
      }
    } catch (e) {
      AppLogger.error('⚠️ Failed to mark notification as read: $e');
    }
  }

  // Delete/Clear old notifications (keep only today's)
  Future<void> clearOldNotifications() async {
    try {
      final box = await _openBox();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final keysToDelete = box.values
          .where((n) {
            final date = n.timestamp;
            final isToday =
                date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
            return !isToday; // Delete if NOT today
          })
          .map((n) => n.id)
          .toList();

      if (keysToDelete.isNotEmpty) {
        await box.deleteAll(keysToDelete);
        AppLogger.info('🧹 Cleared ${keysToDelete.length} old notifications');
      }
    } catch (e) {
      AppLogger.error('⚠️ Failed to clear old notifications: $e');
    }
  }

  // Delete specific notification
  Future<void> deleteNotification(String id) async {
    try {
      final box = await _openBox();
      await box.delete(id);
      AppLogger.info('🗑️ Notification deleted: $id');
    } catch (e) {
      AppLogger.error('⚠️ Failed to delete notification: $e');
    }
  }
  
  Future<Map<String, dynamic>> pushNotification(
      AppNotification notification,
      ) async {
    if (_dio == null) {
      return {'success': false, 'error': 'Network client not initialized'};
    }
    
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

      final response = await _dio!.post(
        '/notification/notify',
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
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationRepository(dio);
});
