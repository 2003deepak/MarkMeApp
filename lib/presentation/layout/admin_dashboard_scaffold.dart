import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/presentation/widgets/ui/notification_badge.dart';
class AdminDashboardScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const AdminDashboardScaffold({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('AdminDashboardScaffold'));
  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        leading: IconButton(
          icon: const Icon(Icons.school, color: Colors.white, size: 28),
          onPressed: () {},
        ),
        title: const Text(
          'Mark Me',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 6,
                top: 6,
                child: NotificationBadge(
                  count: 12, // Keeping static as per original layout
                  backgroundColor: Colors.red.shade600,
                  borderColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => _onTap(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF2563EB)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics, color: Color(0xFF2563EB)),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: Color(0xFF2563EB)),
            label: 'Management',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF2563EB)),
            label: 'Profile',
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: const Color(0xFF2563EB).withOpacity(0.1),
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
