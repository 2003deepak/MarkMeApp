import 'package:flutter/material.dart';

class AttendanceStatsWidget extends StatelessWidget {
  final Map<String, Map<String, dynamic>> subjectData;
  final String? selectedSubject;
  final bool isDesktop;

  const AttendanceStatsWidget({
    super.key,
    required this.subjectData,
    required this.selectedSubject,
    required this.isDesktop,
  });

  Map<String, dynamic> _getStats() {
    if (selectedSubject != null) {
      return subjectData[selectedSubject]!;
    } else {
      int totalLectures = 0;
      int totalAttended = 0;

      for (var subject in subjectData.values) {
        totalLectures += subject['totalLectures'] as int;
        totalAttended += subject['attendedLectures'] as int;
      }

      return {
        'totalLectures': totalLectures,
        'attendedLectures': totalAttended,
        'percentage': (totalAttended / totalLectures) * 100,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _getStats();

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
              stats['totalLectures'].toString(),
              Icons.school,
            ),
          ),
          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: _buildStatItem(
              'Attended',
              stats['attendedLectures'].toString(),
              Icons.check_circle,
            ),
          ),
          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: _buildStatItem(
              'Percentage',
              '${stats['percentage'].toStringAsFixed(1)}%',
              Icons.trending_up,
            ),
          ),
        ],
      ),
    );
  }

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
