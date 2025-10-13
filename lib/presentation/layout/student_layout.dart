import 'package:flutter/material.dart';
import 'package:markmeapp/presentation/widgets/bottom_navigation.dart';

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
          'Student Dashboard',
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
                child: _NotificationBadge(
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
      bottomNavigationBar: const BottomNavigation(),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  final int count;
  final Color backgroundColor;
  final Color borderColor;

  const _NotificationBadge({
    required this.count,
    required this.backgroundColor,
    required this.borderColor,
  });

  String _formatCount(int c) {
    if (c <= 0) return '';
    if (c > 99) return '99+';
    return '$c';
  }

  @override
  Widget build(BuildContext context) {
    final String label = _formatCount(count);
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: 'Notifications: $label unread',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        decoration: ShapeDecoration(
          color: backgroundColor,
          shape: StadiumBorder(
            side: BorderSide(color: borderColor, width: 1.5),
          ),
          shadows: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
