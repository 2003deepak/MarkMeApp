import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notification_bloc.dart';
import 'notification_page.dart';
import 'schedule_page.dart';
import 'profile_page.dart';
import '../widgets/student_dashboard_content.dart';

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
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: Colors.grey.shade700,
                        size: 28, // Increased size
                      ),
                      onPressed: () => _navigateToNotifications(context),
                    ),
                  ),
                  
                  // Unread count badge
                  if (unreadCount > 0)
                    Positioned(
                      right: 12, // Adjusted for larger icon
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
          // Home/Dashboard page - Using new StudentDashboardContent
          const StudentDashboardContent(),
          
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



  /// Builds calendar/schedule page placeholder
  Widget _buildCalendarPage() {
    return const SchedulePage();
  }

  /// Builds profile page
  Widget _buildProfilePage() {
    return const ProfilePage();
  }


}