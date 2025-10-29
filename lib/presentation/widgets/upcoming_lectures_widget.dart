import 'package:flutter/material.dart';
import 'package:markmeapp/presentation/widgets/lecture_card.dart';
import 'package:markmeapp/presentation/widgets/ui/empty_data.dart';
import 'package:markmeapp/presentation/widgets/ui/error.dart';

class UpcomingLecturesWidget extends StatelessWidget {
  final bool isDesktop;
  final List<dynamic> upcomingSessions;
  final bool isLoading;
  final String errorMessage;
  final VoidCallback onRetry;

  const UpcomingLecturesWidget({
    super.key,
    required this.isDesktop,
    required this.upcomingSessions,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });

  // Helper function to get color based on subject name
  Color _getSubjectColor(String subjectName) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    final index = subjectName.hashCode % colors.length;
    return colors[index];
  }

  // Helper function to format time range
  String _formatTimeRange(String startTime, String endTime) {
    return '$startTime - $endTime';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Upcoming Lectures',
              style: TextStyle(
                fontSize: isDesktop ? 22 : 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            if (isLoading)
              SizedBox(
                width: isDesktop ? 20 : 16,
                height: isDesktop ? 20 : 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (isLoading)
          _buildLoadingState()
        else if (errorMessage.isNotEmpty)
          CustomErrorWidget(
            errorMessage: errorMessage,
            onRetry: () {},
            isRetryEnabled: false,
            isDesktop: isDesktop,
          )
        else if (upcomingSessions.isEmpty)
          // Full width empty state container
          CustomEmptyStateWidget(
            icon: Icons.schedule,
            width: double.infinity,
            title: 'No upcoming lectures',
            subtitle: 'Check back later for scheduled sessions.',
            isDesktop: isDesktop,
          )
        else
          _buildUpcomingSessions(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Row(
      children: [
        Expanded(child: _buildSkeletonCard()),
        const SizedBox(width: 12),
        Expanded(child: _buildSkeletonCard()),
        const SizedBox(width: 12),
        Expanded(child: _buildSkeletonCard()),
      ],
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isDesktop ? 40 : 32,
            height: isDesktop ? 40 : 32,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: isDesktop ? 16 : 14,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: isDesktop ? 14 : 12,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSessions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: upcomingSessions.map((session) {
          final subjectName = session['subject_name'] ?? 'Unknown Subject';
          final startTime = session['start_time'] ?? '';
          final endTime = session['end_time'] ?? '';
          final component = session['component'] ?? 'Lecture';
          final teacherName = session['teacher_name'] ?? '';
          final timeUntilStart = session['time_until_start_display'] ?? '';

          return Container(
            width: isDesktop ? 200 : 160,
            margin: const EdgeInsets.only(right: 12),
            child: LectureCardWidget(
              subject: subjectName,
              time: _formatTimeRange(startTime, endTime),
              component: component,
              teacherName: teacherName,
              timeUntilStart: timeUntilStart,
              color: _getSubjectColor(subjectName),
              isDesktop: isDesktop,
            ),
          );
        }).toList(),
      ),
    );
  }
}
