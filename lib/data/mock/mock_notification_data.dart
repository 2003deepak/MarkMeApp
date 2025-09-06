import '../models/notification_model.dart';

/// Mock notification data for UI testing when backend is not available
/// Backend developers: This shows the expected data structure for your API
class MockNotificationData {
  /// Mock notifications list with different types and statuses
  /// This demonstrates the variety of notifications your backend should support
  static List<NotificationModel> getMockNotifications() {
    return [
      // Timetable update notification (recent)
      NotificationModel(
        id: 'notif_001',
        type: NotificationType.timetableUpdate,
        title: 'Tomorrow\'s Timetable Updated',
        message: 'Check the updated schedule for your classes tomorrow. Room changes for Computer Science lecture.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
        metadata: {
          'class_id': 'CS101',
          'subject': 'Computer Science',
          'room_change': 'Room 101 → Room 205',
          'affected_classes': 2,
        },
      ),
      
      // Attendance confirmation (recent)
      NotificationModel(
        id: 'notif_002',
        type: NotificationType.attendanceConfirmation,
        title: 'Attendance Marked for DevOps',
        message: 'You have successfully marked your attendance in DevOps class. Keep up the good work!',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        isRead: false,
        metadata: {
          'class_id': 'CS201',
          'subject': 'DevOps',
          'attendance_percentage': 87.5,
          'instructor': 'Dr. Smith',
        },
      ),
      
      // Critical attendance alert (1 day ago)
      NotificationModel(
        id: 'notif_003',
        type: NotificationType.criticalAlert,
        title: 'Critical Attendance Alert',
        message: 'Your attendance is below 50%. Immediate action required! Contact your academic advisor.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: false,
        metadata: {
          'attendance_percentage': 45.0,
          'required_percentage': 75.0,
          'classes_missed': 8,
          'total_classes': 16,
          'action_required': true,
          'deadline': '2024-02-15',
        },
      ),
      
      // Assignment reminder (2 days ago, read)
      NotificationModel(
        id: 'notif_004',
        type: NotificationType.general,
        title: 'Assignment Due Tomorrow',
        message: 'Don\'t forget to submit your Data Structures assignment by 11:59 PM tomorrow.',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
        metadata: {
          'assignment_id': 'DS_ASG_001',
          'subject': 'Data Structures',
          'due_date': '2024-01-20T23:59:00Z',
          'submission_type': 'online',
        },
      ),
      
      // Exam schedule notification (3 days ago, read)
      NotificationModel(
        id: 'notif_005',
        type: NotificationType.timetableUpdate,
        title: 'Mid-term Exam Schedule Released',
        message: 'Your mid-term examination schedule has been published. Check the dates and venues.',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
        metadata: {
          'exam_type': 'mid-term',
          'total_subjects': 5,
          'start_date': '2024-02-01',
          'end_date': '2024-02-10',
        },
      ),
      
      // Library book reminder (4 days ago, read)
      NotificationModel(
        id: 'notif_006',
        type: NotificationType.general,
        title: 'Library Book Due Soon',
        message: 'Your borrowed book "Advanced Algorithms" is due in 3 days. Please return or renew.',
        timestamp: DateTime.now().subtract(const Duration(days: 4)),
        isRead: true,
        metadata: {
          'book_title': 'Advanced Algorithms',
          'due_date': '2024-01-25',
          'fine_amount': 0,
          'renewal_possible': true,
        },
      ),
      
      // Fee payment reminder (5 days ago, read)
      NotificationModel(
        id: 'notif_007',
        type: NotificationType.criticalAlert,
        title: 'Fee Payment Reminder',
        message: 'Your semester fee payment is pending. Please complete the payment to avoid late charges.',
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        isRead: true,
        metadata: {
          'amount_due': 15000.0,
          'currency': 'INR',
          'due_date': '2024-01-30',
          'late_fee': 500.0,
        },
      ),
      
      // Class cancellation (1 week ago, read)
      NotificationModel(
        id: 'notif_008',
        type: NotificationType.timetableUpdate,
        title: 'Class Cancelled - Mathematics',
        message: 'Today\'s Mathematics class has been cancelled due to faculty unavailability. Make-up class scheduled.',
        timestamp: DateTime.now().subtract(const Duration(days: 7)),
        isRead: true,
        metadata: {
          'class_id': 'MATH101',
          'subject': 'Mathematics',
          'reason': 'Faculty unavailable',
          'makeup_date': '2024-01-28T10:00:00Z',
        },
      ),
      
      // Achievement notification (1 week ago, read)
      NotificationModel(
        id: 'notif_009',
        type: NotificationType.attendanceConfirmation,
        title: 'Perfect Attendance Achievement',
        message: 'Congratulations! You have maintained 100% attendance this month. Keep it up!',
        timestamp: DateTime.now().subtract(const Duration(days: 8)),
        isRead: true,
        metadata: {
          'achievement_type': 'perfect_attendance',
          'period': 'January 2024',
          'attendance_percentage': 100.0,
          'reward_points': 50,
        },
      ),
      
      // System maintenance (2 weeks ago, read)
      NotificationModel(
        id: 'notif_010',
        type: NotificationType.general,
        title: 'System Maintenance Notice',
        message: 'The student portal will be under maintenance on Sunday from 2 AM to 6 AM. Plan accordingly.',
        timestamp: DateTime.now().subtract(const Duration(days: 14)),
        isRead: true,
        metadata: {
          'maintenance_start': '2024-01-07T02:00:00Z',
          'maintenance_end': '2024-01-07T06:00:00Z',
          'affected_services': ['portal', 'attendance', 'grades'],
        },
      ),
    ];
  }

  /// Mock notification response with pagination
  /// Backend developers: This shows the expected API response structure
  static NotificationResponse getMockNotificationResponse({
    int page = 1,
    int limit = 20,
    NotificationType? type,
    bool unreadOnly = false,
  }) {
    var allNotifications = getMockNotifications();
    
    // Apply filters
    if (type != null) {
      allNotifications = allNotifications
          .where((notification) => notification.type == type)
          .toList();
    }
    
    if (unreadOnly) {
      allNotifications = allNotifications
          .where((notification) => !notification.isRead)
          .toList();
    }
    
    // Apply pagination
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;
    final paginatedNotifications = allNotifications.length > startIndex
        ? allNotifications.sublist(
            startIndex,
            endIndex > allNotifications.length ? allNotifications.length : endIndex,
          )
        : <NotificationModel>[];
    
    final totalPages = (allNotifications.length / limit).ceil();
    final hasMore = page < totalPages;
    
    return NotificationResponse(
      notifications: paginatedNotifications,
      pagination: PaginationInfo(
        currentPage: page,
        totalPages: totalPages,
        totalCount: allNotifications.length,
        hasMore: hasMore,
      ),
      success: true,
      message: 'Mock notifications loaded successfully',
    );
  }

  /// Get unread notification count for badge display
  static int getUnreadCount() {
    return getMockNotifications()
        .where((notification) => !notification.isRead)
        .length;
  }

  /// Simulate marking notification as read
  static bool markAsRead(String notificationId) {
    // In real implementation, this would call the backend API
    // For mock, we just return success
    return true;
  }

  /// Simulate deleting notification
  static bool deleteNotification(String notificationId) {
    // In real implementation, this would call the backend API
    // For mock, we just return success
    return true;
  }

  /// Simulate marking all notifications as read
  static bool markAllAsRead() {
    // In real implementation, this would call the backend API
    // For mock, we just return success
    return true;
  }
}