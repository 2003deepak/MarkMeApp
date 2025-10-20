import 'package:flutter/material.dart';
import 'package:markmeapp/presentation/widgets/bottom_navigation.dart';
import 'package:markmeapp/presentation/widgets/ui/notification_badge.dart';

class StudentLayout extends StatelessWidget {
  final Widget child;

  const StudentLayout({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // HEADER - AppBar
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        leading: IconButton(
          icon: const Icon(Icons.school, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
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
                onPressed: () => {},
              ),
              Positioned(
                right: 6,
                top: 6,
                child: NotificationBadge(
                  count: 12,
                  backgroundColor: Colors.red.shade600,
                  borderColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),

      // MAIN CONTENT - Child (changes based on page)
      body: child,

      // FOOTER - Bottom Navigation
      bottomNavigationBar: const BottomNavigation(userRole: 'student'),
    );
  }
}
