import 'package:flutter/material.dart';
import '../../data/models/notification_model.dart';

/// Individual notification card widget that displays notification information
/// This widget handles the visual representation of different notification types
/// and user interactions (tap to mark as read, swipe to dismiss)
/// 
/// Backend developers: The visual styling is based on the notification type
/// field in your API response. Ensure you're sending the correct type values:
/// - 'timetable_update' -> Blue calendar icon
/// - 'attendance_confirmation' -> Green checkmark icon  
/// - 'critical_alert' -> Orange/yellow warning icon
/// - 'general' -> Default gray info icon
class NotificationCard extends StatelessWidget {
  /// The notification data to display
  final NotificationModel notification;
  
  /// Callback when user taps the notification
  /// This should mark the notification as read via backend API
  final VoidCallback? onTap;
  
  /// Callback when user dismisses/deletes the notification
  /// This should delete the notification via backend API
  final VoidCallback? onDismiss;
  
  /// Whether to show a subtle animation when the card appears
  final bool animate;

  const NotificationCard({
    Key? key,
    required this.notification,
    this.onTap,
    this.onDismiss,
    this.animate = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      // Unique key for dismissible widget
      key: Key('notification_${notification.id}'),
      
      // Allow swiping from right to left to dismiss
      direction: DismissDirection.endToStart,
      
      // Background shown when swiping to dismiss
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 24,
        ),
      ),
      
      // Confirm dismiss action
      confirmDismiss: (direction) async {
        // Show confirmation dialog for critical alerts
        if (notification.type == NotificationType.criticalAlert) {
          return await _showDismissConfirmation(context);
        }
        return true;
      },
      
      // Handle dismiss action
      onDismissed: (direction) {
        if (onDismiss != null) {
          onDismiss!();
        }
      },
      
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            // Handle tap to mark as read
            onTap: () {
              if (onTap != null) {
                onTap!();
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // Background color based on notification type and read status
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getBorderColor(),
                  width: 1,
                ),
                // Add subtle shadow for unread notifications
                boxShadow: notification.isRead
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification type icon
                  _buildNotificationIcon(),
                  
                  const SizedBox(width: 12),
                  
                  // Notification content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and timestamp row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Notification title
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: notification.isRead 
                                      ? FontWeight.w500 
                                      : FontWeight.w600,
                                  color: notification.isRead
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade900,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            
                            const SizedBox(width: 8),
                            
                            // Timestamp
                            Text(
                              notification.formattedTime,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Notification message
                        Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: notification.isRead
                                ? Colors.grey.shade600
                                : Colors.grey.shade700,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        // Show metadata if available (for backend developers)
                        if (notification.metadata != null && 
                            notification.metadata!.isNotEmpty)
                          _buildMetadataSection(),
                      ],
                    ),
                  ),
                  
                  // Unread indicator dot
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 4, left: 8),
                      decoration: BoxDecoration(
                        color: _getAccentColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the notification type icon based on the type from backend
  /// Backend developers: Ensure your API returns the correct type values
  Widget _buildNotificationIcon() {
    IconData iconData;
    Color iconColor;
    Color backgroundColor;

    switch (notification.type) {
      case NotificationType.timetableUpdate:
        // Calendar icon for timetable updates
        iconData = Icons.calendar_today_outlined;
        iconColor = Colors.blue.shade600;
        backgroundColor = Colors.blue.shade50;
        break;
        
      case NotificationType.attendanceConfirmation:
        // Checkmark icon for attendance confirmations
        iconData = Icons.check_circle_outline;
        iconColor = Colors.green.shade600;
        backgroundColor = Colors.green.shade50;
        break;
        
      case NotificationType.criticalAlert:
        // Warning icon for critical alerts
        iconData = Icons.warning_amber_outlined;
        iconColor = Colors.orange.shade600;
        backgroundColor = Colors.orange.shade50;
        break;
        
      case NotificationType.general:
      default:
        // Info icon for general notifications
        iconData = Icons.info_outline;
        iconColor = Colors.grey.shade600;
        backgroundColor = Colors.grey.shade50;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  /// Builds metadata section for additional notification information
  /// Backend developers: This displays any additional data you send in the metadata field
  /// Common metadata examples:
  /// - Timetable: class_id, subject, room_number
  /// - Attendance: class_id, subject, attendance_percentage
  /// - Alerts: severity_level, action_required
  Widget _buildMetadataSection() {
    final metadata = notification.metadata!;
    
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          // Show subject if available
          if (metadata['subject'] != null)
            _buildMetadataChip(
              label: metadata['subject'].toString(),
              icon: Icons.subject,
            ),
          
          // Show attendance percentage if available
          if (metadata['attendance_percentage'] != null)
            _buildMetadataChip(
              label: '${metadata['attendance_percentage']}%',
              icon: Icons.percent,
              color: _getAttendanceColor(metadata['attendance_percentage']),
            ),
          
          // Show class ID if available
          if (metadata['class_id'] != null)
            _buildMetadataChip(
              label: metadata['class_id'].toString(),
              icon: Icons.class_,
            ),
        ],
      ),
    );
  }

  /// Builds a small chip for metadata display
  Widget _buildMetadataChip({
    required String label,
    required IconData icon,
    Color? color,
  }) {
    final chipColor = color ?? Colors.grey.shade600;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chipColor.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: chipColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Gets background color based on notification type and read status
  Color _getBackgroundColor() {
    if (notification.isRead) {
      return Colors.grey.shade50;
    }

    switch (notification.type) {
      case NotificationType.timetableUpdate:
        return Colors.blue.shade25;
      case NotificationType.attendanceConfirmation:
        return Colors.green.shade25;
      case NotificationType.criticalAlert:
        return Colors.orange.shade25;
      case NotificationType.general:
      default:
        return Colors.white;
    }
  }

  /// Gets border color based on notification type
  Color _getBorderColor() {
    if (notification.isRead) {
      return Colors.grey.shade200;
    }

    switch (notification.type) {
      case NotificationType.timetableUpdate:
        return Colors.blue.shade200;
      case NotificationType.attendanceConfirmation:
        return Colors.green.shade200;
      case NotificationType.criticalAlert:
        return Colors.orange.shade200;
      case NotificationType.general:
      default:
        return Colors.grey.shade200;
    }
  }

  /// Gets accent color for unread indicator
  Color _getAccentColor() {
    switch (notification.type) {
      case NotificationType.timetableUpdate:
        return Colors.blue.shade600;
      case NotificationType.attendanceConfirmation:
        return Colors.green.shade600;
      case NotificationType.criticalAlert:
        return Colors.orange.shade600;
      case NotificationType.general:
      default:
        return Colors.grey.shade600;
    }
  }

  /// Gets color for attendance percentage display
  /// Backend developers: This provides visual feedback for attendance data
  Color _getAttendanceColor(dynamic percentage) {
    final percent = double.tryParse(percentage.toString()) ?? 0;
    
    if (percent >= 75) {
      return Colors.green.shade600; // Good attendance
    } else if (percent >= 50) {
      return Colors.orange.shade600; // Warning attendance
    } else {
      return Colors.red.shade600; // Critical attendance
    }
  }

  /// Shows confirmation dialog for dismissing critical alerts
  Future<bool?> _showDismissConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Dismiss Alert'),
          content: const Text(
            'Are you sure you want to dismiss this critical alert? '
            'You may not receive this important information again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Dismiss'),
            ),
          ],
        );
      },
    );
  }
}

/// Extension to add color shade 25 for very light backgrounds
extension ColorShades on Color {
  Color get shade25 => Color.lerp(this, Colors.white, 0.95)!;
}