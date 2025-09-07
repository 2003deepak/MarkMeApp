import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/mock/mock_schedule_data.dart';
import '../../../data/models/schedule_model.dart';
import '../notification_page.dart';
import 'send_notification_page.dart';
import 'attendance_management_page.dart';
import 'teacher_reports_page.dart';
import 'teacher_analytics_page.dart';

/// Teacher Dashboard Page - Main dashboard for staff members
/// This page provides teachers with:
/// - Quick action cards for common tasks
/// - Today's lecture schedule
/// - Recent activity feed
/// - Navigation to detailed sections
/// 
/// Backend developers: This page will need teacher-specific API integration
/// Expected endpoints:
/// - GET /api/teacher/dashboard - Get teacher dashboard data
/// - GET /api/teacher/lectures/today - Get today's lectures for teacher
/// - GET /api/teacher/activities - Get recent teacher activities
/// - POST /api/notifications/send - Send notifications to students
class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({Key? key}) : super(key: key);

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _selectedIndex = 0;
  late PageController _pageController;

  // Mock teacher data - will be replaced with backend data
  final Map<String, dynamic> _teacherData = {
    'teacher_id': 'TCH2024001',
    'name': 'Dr. Sarah Johnson',
    'department': 'Computer Science',
    'designation': 'Associate Professor',
    'employee_id': 'EMP001',
    'subjects': ['Data Structures', 'Algorithms', 'Database Systems'],
    'profile_image': null,
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          children: [
            // Dashboard Page
            _buildDashboardContent(),
            
            // Schedule Page
            _buildSchedulePage(),
            
            // Notifications Page
            const NotificationPage(),
            
            // Profile Page
            _buildProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  /// Builds the main dashboard content
  Widget _buildDashboardContent() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with teacher info
                  _buildHeader(),
                  
                  const SizedBox(height: 24),
                  
                  // Quick Action Cards
                  _buildQuickActionCards(),
                  
                  const SizedBox(height: 32),
                  
                  // Today's Lectures Section
                  _buildTodaysLecturesSection(),
                  
                  const SizedBox(height: 32),
                  
                  // Recent Activity Section
                  _buildRecentActivitySection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the header with teacher information
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: _teacherData['profile_image'] != null
                  ? ClipOval(
                      child: Image.network(
                        _teacherData['profile_image'],
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 32,
                      color: Colors.blue.shade600,
                    ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Teacher Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _teacherData['name'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _teacherData['designation'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _teacherData['department'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          
          // Notification Bell
          IconButton(
            onPressed: () => _onNavItemTapped(2),
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds quick action cards
  Widget _buildQuickActionCards() {
    final actions = [
      {
        'title': 'Push Notification',
        'icon': Icons.notifications_active,
        'color': Colors.blue.shade600,
        'onTap': () => _showNotificationDialog(),
      },
      {
        'title': 'View Reports',
        'icon': Icons.assessment_outlined,
        'color': Colors.green.shade600,
        'onTap': () => _navigateToReports(),
      },
      {
        'title': 'Mark Attendance',
        'icon': Icons.how_to_reg_outlined,
        'color': Colors.purple.shade600,
        'onTap': () => _navigateToAttendance(),
      },
      {
        'title': 'Student Analytics',
        'icon': Icons.analytics_outlined,
        'color': Colors.orange.shade600,
        'onTap': () => _navigateToAnalytics(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, animationValue, child) {
            return Transform.scale(
              scale: animationValue,
              child: GestureDetector(
                onTap: action['onTap'] as VoidCallback,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (action['color'] as Color).withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: (action['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          action['icon'] as IconData,
                          color: action['color'] as Color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        action['title'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Builds today's lectures section
  Widget _buildTodaysLecturesSection() {
    final todayLectures = MockScheduleData.getTodaySchedules();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Lectures",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 16),
        
        if (todayLectures.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No lectures scheduled for today',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...todayLectures.take(3).map((lecture) => 
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutBack,
              builder: (context, animationValue, child) {
                return Transform.translate(
                  offset: Offset(50 * (1 - animationValue), 0),
                  child: Opacity(
                    opacity: animationValue,
                    child: _buildLectureCard(lecture),
                  ),
                );
              },
            ),
          ).toList(),
      ],
    );
  }

  /// Builds individual lecture card
  Widget _buildLectureCard(ScheduleModel lecture) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Time and Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(lecture.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatTime(lecture.startTime),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(lecture.status),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${lecture.durationMinutes} min',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Subject Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lecture.subjectName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      lecture.roomNumber,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action Button
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.chevron_right,
              color: Colors.blue.shade600,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds recent activity section
  Widget _buildRecentActivitySection() {
    final activities = [
      {
        'title': 'Tomorrows Timetable Updated',
        'description': 'Check the updated schedule for your classes tomorrow.',
        'time': '2 hours ago',
        'icon': Icons.schedule,
        'color': Colors.blue.shade600,
      },
      {
        'title': 'Attendance Marked for DevOps',
        'description': 'You have successfully marked your attendance in DevOps.',
        'time': '4 hours ago',
        'icon': Icons.check_circle,
        'color': Colors.green.shade600,
      },
      {
        'title': 'Critical Attendance Alert',
        'description': 'Your attendance is below 50%. Immediate action required!',
        'time': '1 day ago',
        'icon': Icons.warning_amber,
        'color': Colors.orange.shade600,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 16),
        
        ...activities.map((activity) => 
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOut,
            builder: (context, animationValue, child) {
              return Transform.translate(
                offset: Offset(30 * (1 - animationValue), 0),
                child: Opacity(
                  opacity: animationValue,
                  child: _buildActivityCard(activity),
                ),
              );
            },
          ),
        ).toList(),
      ],
    );
  }

  /// Builds individual activity card
  Widget _buildActivityCard(Map<String, dynamic> activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (activity['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              activity['icon'] as IconData,
              color: activity['color'] as Color,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['description'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          Text(
            activity['time'] as String,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds bottom navigation
  Widget _buildBottomNavigation() {
    return Container(
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
                label: 'Dashboard',
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
    );
  }

  /// Builds individual navigation item
  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected 
                  ? Colors.blue.shade600 
                  : Colors.grey.shade600,
              size: 24,
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

  /// Placeholder for schedule page
  Widget _buildSchedulePage() {
    return const Center(
      child: Text(
        'Teacher Schedule Page\n(To be implemented)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  /// Placeholder for profile page
  Widget _buildProfilePage() {
    return const Center(
      child: Text(
        'Teacher Profile Page\n(To be implemented)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  /// Handles navigation item tap
  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Shows notification page
  void _showNotificationDialog() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            const SendNotificationPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// Navigate to reports
  void _navigateToReports() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            const TeacherReportsPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// Navigate to attendance
  void _navigateToAttendance() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            const AttendanceManagementPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// Navigate to analytics
  void _navigateToAnalytics() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            const TeacherAnalyticsPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// Gets status color for schedule
  Color _getStatusColor(ScheduleStatus status) {
    switch (status) {
      case ScheduleStatus.ongoing:
        return Colors.green.shade600;
      case ScheduleStatus.scheduled:
        return Colors.blue.shade600;
      case ScheduleStatus.completed:
        return Colors.grey.shade600;
      case ScheduleStatus.cancelled:
        return Colors.red.shade600;
      case ScheduleStatus.rescheduled:
        return Colors.orange.shade600;
    }
  }

  /// Formats time for display
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}