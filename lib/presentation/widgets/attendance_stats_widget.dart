import 'package:flutter/material.dart';

class AttendanceStatsWidget extends StatelessWidget {
  final Map<String, dynamic>? subjectData;
  final String? selectedSubject;
  final bool isDesktop;

  const AttendanceStatsWidget({
    super.key,
    required this.subjectData,
    required this.selectedSubject,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    // Use safe defaults
    final data =
        subjectData ??
        {'totalLectures': 0, 'attendedLectures': 0, 'percentage': 0.0};

    final totalLectures = data['totalLectures'] ?? 0;
    final attendedLectures = data['attendedLectures'] ?? 0;
    final percentage = data['percentage'] ?? 0.0;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade700],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total Lectures',
              totalLectures.toString(),
              Icons.school,
            ),
          ),
          _divider(),
          Expanded(
            child: _buildStatItem(
              'Attended',
              attendedLectures.toString(),
              Icons.check_circle,
            ),
          ),
          _divider(),
          Expanded(
            child: _buildStatItem(
              'Percentage',
              '${percentage.toStringAsFixed(1)}%',
              Icons.trending_up,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3));

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: isDesktop ? 28 : 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isDesktop ? 24 : 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 14 : 12,
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
