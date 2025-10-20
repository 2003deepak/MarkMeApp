import 'package:flutter/material.dart';

Widget buildRecentActivitySection() {
  return Column(
    children: [
      buildActivityCard(
        icon: Icons.calendar_today_outlined,
        iconColor: Colors.blue.shade600,
        title: 'Tomorrows Timetable Updated',
        description: 'Check the updated schedule for your classes tomorrow.',
        time: '2 hours ago',
      ),
      const SizedBox(height: 12),
      buildActivityCard(
        icon: Icons.check_circle_outline,
        iconColor: Colors.green.shade600,
        title: 'Attendance Marked for DevOps',
        description: 'You have successfully marked your attendance in DevOps.',
        time: '4 hours ago',
      ),
      const SizedBox(height: 12),
      buildActivityCard(
        icon: Icons.warning_amber_outlined,
        iconColor: Colors.orange.shade600,
        title: 'Critical Attendance Alert',
        description: 'Your attendance is below 50%, Immediate action required!',
        time: '1 day ago',
      ),
    ],
  );
}

Widget buildActivityCard({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String description,
  required String time,
}) {
  return Card(
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    ),
  );
}
