import 'package:flutter/material.dart';
import 'package:markmeapp/presentation/widgets/notification_card.dart';

class RecentActivityWidget extends StatelessWidget {
  final bool isDesktop;

  const RecentActivityWidget({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: isDesktop ? 22 : 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        NotificationCardWidget(
          title: 'Tomorrows Timetable Updated',
          description: 'Check the updated schedule for your classes tomorrow.',
          icon: Icons.calendar_today,
          color: Colors.blue,
          time: '2 hours ago',
          isDesktop: isDesktop,
        ),
        const SizedBox(height: 12),
        NotificationCardWidget(
          title: 'Attendance Marked for Mathematics',
          description:
              'You have successfully marked your attendance in Mathematics.',
          icon: Icons.check_circle,
          color: Colors.green,
          time: '4 hours ago',
          isDesktop: isDesktop,
        ),
        const SizedBox(height: 12),
        NotificationCardWidget(
          title: 'Critical Attendance Alert',
          description:
              'Your attendance is below 50%. Immediate action required!',
          icon: Icons.warning,
          color: Colors.red,
          time: '1 day ago',
          isDesktop: isDesktop,
        ),
      ],
    );
  }
}
