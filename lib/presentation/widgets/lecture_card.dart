import 'package:flutter/material.dart';

class LectureCardWidget extends StatelessWidget {
  final String subject;
  final String time;
  final Color color;
  final bool isDesktop;

  const LectureCardWidget({
    Key? key,
    required this.subject,
    required this.time,
    required this.color,
    this.isDesktop = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.access_time,
              color: color,
              size: isDesktop ? 20 : 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subject,
            style: TextStyle(
              fontSize: isDesktop ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: isDesktop ? 14 : 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
