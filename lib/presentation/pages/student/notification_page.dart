import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:markmeapp/data/models/notification_model.dart';
import 'package:markmeapp/data/repositories/notification_repository.dart';
import 'package:go_router/go_router.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationRepository _repository = NotificationRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light backgroundd
      body: ValueListenableBuilder(
        valueListenable: Hive.box<NotificationModel>(
          NotificationRepository.boxName,
        ).listenable(),
        builder: (context, Box<NotificationModel> box, _) {
          // Filter for today's notifications and sort by latest
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          final notifications = box.values.where((n) {
            final date = n.timestamp;
            return date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
          }).toList();

          notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: Colors.blue.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up for today!',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    // Infer type and style based on content/type
    final isUnread = !notification.isRead;

    // Determine style based on 'type' field or title keywords if type is missing
    Color iconColor;
    IconData iconData;
    Color borderColor = Colors.transparent;
    Color backgroundColor = Colors.white;

    final type = notification.type?.toLowerCase() ?? '';
    final title = notification.title.toLowerCase();

    if (type == 'attendance' || title.contains('attendance')) {
      if (title.contains('alert') ||
          title.contains('critical') ||
          title.contains('warning')) {
        iconColor = Colors.orange;
        iconData = Icons.error_outline;
        backgroundColor = const Color(0xFFF8F9FA); // Greyscale/Off-white
      } else {
        iconColor = Colors.green; // Success
        iconData = Icons.check_circle_outline;
        backgroundColor = const Color(0xFFF8F9FA);
      }
    } else if (type == 'timetable' || title.contains('timetable')) {
      iconColor = Colors.blue;
      iconData = Icons.calendar_today;
      // Highlighting "Important" or "Unread" timetable updates
      if (isUnread) {
        borderColor = Colors.blue.shade200;
        backgroundColor = Colors.white;
      } else {
        backgroundColor = const Color(0xFFF8F9FA);
      }
    } else {
      // Default info
      iconColor = Colors.blue;
      iconData = Icons.info_outline;
      backgroundColor = const Color(0xFFF8F9FA);
    }

    // Force blue border if unread (as per design interpretation)
    if (isUnread) {
      borderColor = Colors.blue.shade400;
      backgroundColor = Colors.white;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _repository.deleteNotification(notification.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () async {
          if (!notification.isRead) {
            await _repository.markAsRead(notification.id);
          }
          // Handle navigation if data exists
          if (notification.data != null &&
              notification.data!['screen'] != null) {
            if (mounted) context.push(notification.data!['screen']);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        _formatTime(notification.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }
}
