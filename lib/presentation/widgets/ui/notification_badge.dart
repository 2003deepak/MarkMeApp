import 'package:flutter/material.dart';

class NotificationBadge extends StatelessWidget {
  final int count;
  final Color backgroundColor;
  final Color borderColor;

  const NotificationBadge({
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
