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

  bool _hasData() {
    if (subjectData == null) return false;
    final totalLectures = subjectData!['totalLectures'] ?? 0;
    final attendedLectures = subjectData!['attendedLectures'] ?? 0;
    return totalLectures > 0 || attendedLectures > 0;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasData = _hasData();
    
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
          colors: hasData 
              ? [Colors.blue.shade600, Colors.blue.shade700]
              : [Colors.grey.shade400, Colors.grey.shade500],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: hasData 
                ? Colors.blue.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
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
              hasData ? totalLectures.toString() : '--',
              Icons.school,
              hasData,
            ),
          ),
          _divider(hasData),
          Expanded(
            child: _buildStatItem(
              'Attended',
              hasData ? attendedLectures.toString() : '--',
              Icons.check_circle,
              hasData,
            ),
          ),
          _divider(hasData),
          Expanded(
            child: _buildStatItem(
              'Percentage',
              hasData ? '${percentage.toStringAsFixed(1)}%' : '--%',
              Icons.trending_up,
              hasData,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool hasData) => Container(
    width: 1,
    height: 50,
    color: (hasData ? Colors.white : Colors.white.withValues(alpha: 0.3)).withValues(alpha: 0.3),
  );

  Widget _buildStatItem(String label, String value, IconData icon, bool hasData) {
    final Color iconColor = hasData ? Colors.white : Colors.white.withValues(alpha: 0.5);
    final Color valueColor = hasData ? Colors.white : Colors.white.withValues(alpha: 0.7);
    final Color labelColor = hasData 
        ? Colors.white.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.4);

    return Column(
      children: [
        Icon(icon, color: iconColor, size: isDesktop ? 28 : 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isDesktop ? 24 : 20,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 14 : 12,
            color: labelColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}