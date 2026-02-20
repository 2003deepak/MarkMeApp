import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:markmeapp/data/models/notification_model.dart';
import 'package:markmeapp/data/repositories/notification_repository.dart';
import 'package:markmeapp/state/refresh_state.dart';
class ClerkDashboardScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const ClerkDashboardScaffold({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('ClerkDashboardScaffold'));
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
          ValueListenableBuilder(
            valueListenable: Hive.box<NotificationModel>(
              NotificationRepository.boxName,
            ).listenable(),
            builder: (context, Box<NotificationModel> box, widget) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final unreadCount = box.values.where((notification) {
                final date = notification.timestamp;
                return date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day &&
                    !notification.isRead;
              }).length;
              return IconButton(
                onPressed: () => context.push('/notifications'),
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(unreadCount > 9 ? '9+' : unreadCount.toString()),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(dashboardRefreshProvider.notifier).state++;
          await Future.delayed(const Duration(milliseconds: 1000));
        },
        child: navigationShell,
      ),
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
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people, color: Color(0xFF2563EB)),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF2563EB)),
            label: 'Teachers',
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
