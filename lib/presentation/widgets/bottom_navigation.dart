import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/core/utils/app_logger.dart';

/// Custom Bottom Navigation Bar for GoRouter-based navigation
class BottomNavigation extends StatefulWidget {
  final String userRole; // 'student', 'clerk', 'teacher', 'admin'

  const BottomNavigation({super.key, required this.userRole});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  /// Navigation items for different roles
  List<NavigationDestination> get _destinations {
    final role = widget.userRole.toLowerCase();
    final baseRoute = '/$role';

    switch (role) {
      case 'student':
        return [
          NavigationDestination(
            route: '$baseRoute/',
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          NavigationDestination(
            route: '$baseRoute/timetable',
            icon: Icons.calendar_today_outlined,
            activeIcon: Icons.calendar_today,
            label: 'Schedule',
          ),
          NavigationDestination(
            route: '$baseRoute/attendance-history',
            icon: Icons.calendar_month_outlined,
            activeIcon: Icons.calendar_month,
            label: 'Attendance',
          ),

          NavigationDestination(
            route: '$baseRoute/profile',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ];

      case 'clerk':
        return [
          NavigationDestination(
            route: '$baseRoute/',
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          NavigationDestination(
            route: '$baseRoute/student-list',
            icon: Icons.people_outlined,
            activeIcon: Icons.people,
            label: 'Students',
          ),
          NavigationDestination(
            route: '$baseRoute/teacher-list',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Teachers',
          ),
          NavigationDestination(
            route: '$baseRoute/profile',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ];

      case 'teacher':
        return [
          NavigationDestination(
            route: '$baseRoute/',
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          NavigationDestination(
            route: '$baseRoute/timetable',
            icon: Icons.calendar_today_outlined,
            activeIcon: Icons.calendar_today,
            label: 'Schedule',
          ),
          NavigationDestination(
            route: '$baseRoute/attendance-history',
            icon: Icons.calendar_month_outlined,
            activeIcon: Icons.calendar_month,
            label: 'Attendance',
          ),
          NavigationDestination(
            route: '$baseRoute/profile',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ];

      case 'admin':
        return [
          NavigationDestination(
            route: '$baseRoute/dashboard',
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          NavigationDestination(
            route: '$baseRoute/analytics',
            icon: Icons.analytics_outlined,
            activeIcon: Icons.analytics,
            label: 'Analytics',
          ),
          NavigationDestination(
            route: '$baseRoute/management',
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: 'Management',
          ),
          NavigationDestination(
            route: '$baseRoute/profile',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ];

      default:
        // Fallback for unknown roles
        return [
          NavigationDestination(
            route: '/dashboard',
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          NavigationDestination(
            route: '/profile',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current route using GoRouter
    final String location = GoRouterState.of(context).uri.toString();
    final int currentIndex = _getSelectedIndex(location);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26), // 0.1
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < _destinations.length; i++)
                _buildNavItem(context, _destinations[i], i, currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns the selected index based on the current location
  int _getSelectedIndex(String location) {
    // Normalize location by removing trailing slash
    final normalizedLocation = location.endsWith('/')
        ? location.substring(0, location.length - 1)
        : location;

    // Find the destination with the longest matching prefix
    int selectedIndex = 0;
    int longestMatch = -1;

    for (int i = 0; i < _destinations.length; i++) {
      final route = _destinations[i].route;
      final normalizedRoute = route.endsWith('/')
          ? route.substring(0, route.length - 1)
          : route;

      // Check for exact match or location starts with route + '/'
      if (normalizedLocation == normalizedRoute ||
          normalizedLocation.startsWith('$normalizedRoute/')) {
        if (normalizedRoute.length > longestMatch) {
          longestMatch = normalizedRoute.length;
          selectedIndex = i;
        }
      }
    }

    return selectedIndex;
  }

  /// Build individual navigation item
  Widget _buildNavItem(
    BuildContext context,
    NavigationDestination destination,
    int index,
    int currentIndex,
  ) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        final route = destination.route;
        final currentLocation = GoRouterState.of(context).uri.toString();

        AppLogger.info(
          'BottomNavigation: Navigating to: $route, current: $currentLocation, role: ${widget.userRole}',
        );

        if (currentLocation != route) {
          context.push(route);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB).withAlpha(26) // 0.1
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  isSelected ? destination.activeIcon : destination.icon,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : Colors.grey.shade600,
                  size: 24,
                ),
                if (destination.route.contains('notifications'))
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red.shade500,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              destination.label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigation item model
class NavigationDestination {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavigationDestination({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
