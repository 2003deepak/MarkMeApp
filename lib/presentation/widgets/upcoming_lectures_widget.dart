import 'package:flutter/material.dart';
import 'package:markmeapp/presentation/widgets/lecture_card.dart';

class UpcomingLecturesWidget extends StatelessWidget {
  final bool isDesktop;

  const UpcomingLecturesWidget({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Lectures',
          style: TextStyle(
            fontSize: isDesktop ? 22 : 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: LectureCardWidget(
                subject: 'Mathematics',
                time: '09:00 AM - 10:30 AM',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LectureCardWidget(
                subject: 'Physics',
                time: '10:30 AM - 12:00 PM',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LectureCardWidget(
                subject: 'Chemistry',
                time: '12:00 PM - 01:30 PM',
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
