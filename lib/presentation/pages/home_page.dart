import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notification_bloc.dart';
import 'notification_page.dart';
import 'schedule_page.dart';
import '../../data/models/notification_model.dart';
import '../../data/mock/mock_schedule_data.dart';

/// Home page that serves as the main dashboard after user login
/// This page includes:
/// - App bar with notification bell icon and unread count badge
/// - Bottom navigation bar matching the design
/// - Main content area for dashboard widgets
/// 
/// Backend developers: The notification bell shows unread count from your API
/// Make sure your GET /api/notifications endpoint returns accurate unread counts
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Current selected index for bottom navigation
  int _selectedIndex = 0;
  
  /// Page controller for bottom navigation pages
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Load notifications to get unread count for badge
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationBloc>().add(const LoadNotifications());
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      
      // App bar with notification bell
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'MarkMe',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: false,
        
        actions: [
          // Notification bell with unread count badge
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              int unreadCount = 0;
              
              // Calculate unread count from current notifications
              if (state is NotificationLoaded) {
                unreadCount = state.notifications
                    .where((notification) => !notification.isRead)
                    .length;
              }
              
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: Colors.grey.shade700,
                      size: 24,
                    ),
                    onPressed: () => _navigateToNotifications(context),
                  ),
                  
                  // Unread count badge
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white,
                            width: 1,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          
          const SizedBox(width: 8),
        ],
      ),
      
      // Main content area
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          // Home/Dashboard page
          _buildDashboardPage(),
          
          // Calendar/Schedule page
          _buildCalendarPage(),
          
          // Notification page (embedded)
          const NotificationPage(),
          
          // Profile page
          _buildProfilePage(),
        ],
      ),
      
      // Bottom navigation bar matching the design
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  index: 0,
                  label: 'Home',
                ),
                _buildNavItem(
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today,
                  index: 1,
                  label: 'Schedule',
                ),
                _buildNavItem(
                  icon: Icons.notifications_outlined,
                  activeIcon: Icons.notifications,
                  index: 2,
                  label: 'Notifications',
                  showBadge: true,
                ),
                _buildNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  index: 3,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds individual navigation item for bottom bar
  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
    required String label,
    bool showBadge = false,
  }) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected 
                      ? Colors.blue.shade600 
                      : Colors.grey.shade600,
                  size: 24,
                ),
                
                // Badge for notification tab
                if (showBadge && index == 2)
                  BlocBuilder<NotificationBloc, NotificationState>(
                    builder: (context, state) {
                      int unreadCount = 0;
                      
                      if (state is NotificationLoaded) {
                        unreadCount = state.notifications
                            .where((notification) => !notification.isRead)
                            .length;
                      }
                      
                      if (unreadCount == 0) return const SizedBox.shrink();
                      
                      return Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected 
                    ? Colors.blue.shade600 
                    : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handles bottom navigation item tap
  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    // Refresh notifications when notification tab is selected
    if (index == 2) {
      context.read<NotificationBloc>().add(
        const LoadNotifications(isRefresh: true),
      );
    }
  }

  /// Navigates to notification page from app bar bell icon
  void _navigateToNotifications(BuildContext context) {
    // If already on notifications tab, just refresh
    if (_selectedIndex == 2) {
      context.read<NotificationBloc>().add(
        const LoadNotifications(isRefresh: true),
      );
      return;
    }
    
    // Navigate to notifications tab
    _onNavItemTapped(2);
  }

  /// Builds the main dashboard page content
  /// Backend developers: This is where you can add dashboard widgets
  /// that might need API data (attendance summary, upcoming classes, etc.)
  Widget _buildDashboardPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track your attendance and stay updated',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick stats section
          const Text(
            'Quick Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Stats cards
          FutureBuilder<Map<String, dynamic>>(
            future: Future.value(MockScheduleData.getAttendanceStats()),
            builder: (context, snapshot) {
              final stats = snapshot.data ?? {};
              final attendancePercentage = stats['attendance_percentage']?.toStringAsFixed(1) ?? '0.0';
              final todayClasses = MockScheduleData.getTodaySchedules().length;
              
              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Attendance',
                      value: '$attendancePercentage%',
                      icon: Icons.check_circle_outline,
                      color: _getAttendanceColor(stats['attendance_percentage'] ?? 0.0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Classes Today',
                      value: '$todayClasses',
                      icon: Icons.schedule,
                      color: Colors.orange,
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Recent notifications preview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () => _onNavItemTapped(2),
                child: const Text('View All'),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Recent notifications list
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationLoaded && state.notifications.isNotEmpty) {
                final recentNotifications = state.notifications.take(3).toList();
                
                return Column(
                  children: recentNotifications.map((notification) {
                    return _buildNotificationPreview(notification);
                  }).toList(),
                );
              }
              
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: Text(
                    'No recent notifications',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Builds a stat card for the dashboard
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a preview of notification for dashboard
  Widget _buildNotificationPreview(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Notification type icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getNotificationColor(notification.type).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: _getNotificationColor(notification.type),
              size: 16,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Notification content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  notification.formattedTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Unread indicator
          if (!notification.isRead)
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _getNotificationColor(notification.type),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  /// Gets color for notification type
  Color _getNotificationColor(NotificationType type) {
    switch (type) {
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

  /// Gets icon for notification type
  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.timetableUpdate:
        return Icons.calendar_today;
      case NotificationType.attendanceConfirmation:
        return Icons.check_circle;
      case NotificationType.criticalAlert:
        return Icons.warning_amber;
      case NotificationType.general:
      default:
        return Icons.info;
    }
  }

  /// Builds calendar/schedule page placeholder
  Widget _buildCalendarPage() {
    return const SchedulePage();
  }

  /// Builds profile page placeholder
  Widget _buildProfilePage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Profile Page',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your profile information will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Gets color for attendance percentage
  Color _getAttendanceColor(double percentage) {
    if (percentage >= 75) {
      return Colors.green.shade600;
    } else if (percentage >= 50) {
      return Colors.orange.shade600;
    } else {
      return Colors.red.shade600;
    }
  }
}