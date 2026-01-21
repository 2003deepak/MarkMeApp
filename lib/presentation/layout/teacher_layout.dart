import 'package:flutter/material.dart';
import 'package:markmeapp/presentation/widgets/bottom_navigation.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:markmeapp/data/models/notification_model.dart';
import 'package:markmeapp/data/repositories/notification_repository.dart';

class TeacherLayout extends StatelessWidget {
  final Widget child;
  const TeacherLayout({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // HEADER - AppBar
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        leading: IconButton(
          icon: const Icon(Icons.school, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
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
                final isToday =
                    date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                return isToday && !notification.isRead;
              }).length;

              return IconButton(
                onPressed: () {
                  context.push('/notifications');
                },
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

      // BODY
      body: SafeArea(child: child),

      // FOOTER - Bottom Navigation
      bottomNavigationBar: const BottomNavigation(userRole: 'teacher'),
    );
  }
}
