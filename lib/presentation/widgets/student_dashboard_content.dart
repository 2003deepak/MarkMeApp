import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StudentDashboardContent extends StatefulWidget {
  const StudentDashboardContent({super.key});

  @override
  State<StudentDashboardContent> createState() =>
      _StudentDashboardContentState();
}

class _StudentDashboardContentState extends State<StudentDashboardContent>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  String? selectedSubject;
  int touchedIndex = -1;

  // Mock attendance data
  final Map<String, Map<String, dynamic>> subjectData = {
    'Mathematics': {
      'totalLectures': 30,
      'attendedLectures': 28,
      'percentage': 93.3,
      'color': Colors.green,
    },
    'Physics': {
      'totalLectures': 25,
      'attendedLectures': 18,
      'percentage': 72.0,
      'color': Colors.yellow.shade700,
    },
    'Chemistry': {
      'totalLectures': 28,
      'attendedLectures': 15,
      'percentage': 53.6,
      'color': Colors.orange,
    },
    'Computer Science': {
      'totalLectures': 32,
      'attendedLectures': 12,
      'percentage': 37.5,
      'color': Colors.red,
    },
    'English': {
      'totalLectures': 20,
      'attendedLectures': 19,
      'percentage': 95.0,
      'color': Colors.green,
    },
  };

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 60) return Colors.yellow.shade700;
    if (percentage >= 45) return Colors.orange;
    return Colors.red;
  }

  List<PieChartSectionData> _getPieChartSections() {
    if (selectedSubject != null) {
      final data = subjectData[selectedSubject]!;
      final attended = data['attendedLectures'] as int;
      final total = data['totalLectures'] as int;
      final missed = total - attended;

      return [
        PieChartSectionData(
          color: _getAttendanceColor(data['percentage']),
          value: attended.toDouble(),
          title: '', // Remove title to avoid overlap
          radius: touchedIndex == 0 ? 85 : 75,
          titleStyle: const TextStyle(fontSize: 0), // Hide title
        ),
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: missed.toDouble(),
          title: '', // Remove title to avoid overlap
          radius: touchedIndex == 1 ? 85 : 75,
          titleStyle: const TextStyle(fontSize: 0), // Hide title
        ),
      ];
    } else {
      // Show overall attendance for all subjects
      int totalLectures = 0;
      int totalAttended = 0;

      for (var subject in subjectData.values) {
        totalLectures += subject['totalLectures'] as int;
        totalAttended += subject['attendedLectures'] as int;
      }

      final overallPercentage = (totalAttended / totalLectures) * 100;
      final missed = totalLectures - totalAttended;

      return [
        PieChartSectionData(
          color: _getAttendanceColor(overallPercentage),
          value: totalAttended.toDouble(),
          title: '', // Remove title to avoid overlap
          radius: touchedIndex == 0 ? 85 : 75,
          titleStyle: const TextStyle(fontSize: 0), // Hide title
        ),
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: missed.toDouble(),
          title: '', // Remove title to avoid overlap
          radius: touchedIndex == 1 ? 85 : 75,
          titleStyle: const TextStyle(fontSize: 0), // Hide title
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubjectSelector(isDesktop),
          const SizedBox(height: 24),
          _buildAttendanceChart(isDesktop),
          const SizedBox(height: 24),
          _buildAttendanceStats(isDesktop),
          const SizedBox(height: 24),
          _buildUpcomingLectures(isDesktop),
          const SizedBox(height: 24),
          _buildRecentActivity(isDesktop),
        ],
      ),
    );
  }

  Widget _buildSubjectSelector(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildSubjectChip('All Subjects', null, isDesktop),
            ...subjectData.keys.map(
              (subject) => _buildSubjectChip(subject, subject, isDesktop),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectChip(String label, String? value, bool isDesktop) {
    final isSelected = selectedSubject == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSubject = value;
          touchedIndex = -1;
        });
        // Subtle animation when subject changes
        _scaleController.reverse().then((_) {
          _scaleController.forward();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 20 : 16,
          vertical: isDesktop ? 12 : 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade600 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceChart(bool isDesktop) {
    // Get current data for display
    Map<String, dynamic> currentData;
    if (selectedSubject != null) {
      currentData = subjectData[selectedSubject]!;
    } else {
      int totalLectures = 0;
      int totalAttended = 0;

      for (var subject in subjectData.values) {
        totalLectures += subject['totalLectures'] as int;
        totalAttended += subject['attendedLectures'] as int;
      }

      currentData = {
        'totalLectures': totalLectures,
        'attendedLectures': totalAttended,
        'percentage': (totalAttended / totalLectures) * 100,
      };
    }

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.pie_chart,
                color: Colors.blue.shade600,
                size: isDesktop ? 28 : 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  selectedSubject ?? 'Overall Attendance',
                  style: TextStyle(
                    fontSize: isDesktop ? 22 : 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pie Chart with Center Info
          Center(
            child: SizedBox(
              height: isDesktop ? 240 : 200,
              width: isDesktop ? 240 : 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pie Chart
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: SizedBox(
                          height: isDesktop ? 220 : 180,
                          width: isDesktop ? 220 : 180,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeInOutCubic,
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback:
                                      (FlTouchEvent event, pieTouchResponse) {
                                        setState(() {
                                          if (!event
                                                  .isInterestedForInteractions ||
                                              pieTouchResponse == null ||
                                              pieTouchResponse.touchedSection ==
                                                  null) {
                                            touchedIndex = -1;
                                            _scaleController.reverse();
                                            return;
                                          }
                                          touchedIndex = pieTouchResponse
                                              .touchedSection!
                                              .touchedSectionIndex;
                                          _scaleController.forward();
                                        });
                                      },
                                ),
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 2,
                                centerSpaceRadius: isDesktop ? 30 : 20,
                                sections: _getPieChartSections(),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Center Information
                  Container(
                    width: isDesktop ? 110 : 90,
                    height: isDesktop ? 110 : 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${currentData['percentage'].toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: isDesktop ? 24 : 20,
                            fontWeight: FontWeight.w800,
                            color: _getAttendanceColor(
                              currentData['percentage'],
                            ),
                          ),
                        ),
                        Text(
                          'Attendance',
                          style: TextStyle(
                            fontSize: isDesktop ? 12 : 10,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Lecture Count Information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${currentData['attendedLectures']}',
                        style: TextStyle(
                          fontSize: isDesktop ? 24 : 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade600,
                        ),
                      ),
                      Text(
                        'Attended',
                        style: TextStyle(
                          fontSize: isDesktop ? 14 : 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${currentData['totalLectures'] - currentData['attendedLectures']}',
                        style: TextStyle(
                          fontSize: isDesktop ? 24 : 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade400,
                        ),
                      ),
                      Text(
                        'Missed',
                        style: TextStyle(
                          fontSize: isDesktop ? 14 : 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${currentData['totalLectures']}',
                        style: TextStyle(
                          fontSize: isDesktop ? 24 : 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: isDesktop ? 14 : 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStats(bool isDesktop) {
    Map<String, dynamic> stats;

    if (selectedSubject != null) {
      stats = subjectData[selectedSubject]!;
    } else {
      int totalLectures = 0;
      int totalAttended = 0;

      for (var subject in subjectData.values) {
        totalLectures += subject['totalLectures'] as int;
        totalAttended += subject['attendedLectures'] as int;
      }

      stats = {
        'totalLectures': totalLectures,
        'attendedLectures': totalAttended,
        'percentage': (totalAttended / totalLectures) * 100,
      };
    }

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
            color: Colors.blue.withValues(alpha: 0.3),
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
              isDesktop,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildStatItem(
              'Attended',
              stats['attendedLectures'].toString(),
              Icons.check_circle,
              isDesktop,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildStatItem(
              'Percentage',
              '${stats['percentage'].toStringAsFixed(1)}%',
              Icons.trending_up,
              isDesktop,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    bool isDesktop,
  ) {
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
            color: Colors.white.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUpcomingLectures(bool isDesktop) {
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
              child: _buildLectureCard(
                'Mathematics',
                '09:00 AM - 10:30 AM',
                Colors.blue,
                isDesktop,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLectureCard(
                'Physics',
                '10:30 AM - 12:00 PM',
                Colors.green,
                isDesktop,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLectureCard(
                'Chemistry',
                '12:00 PM - 01:30 PM',
                Colors.orange,
                isDesktop,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLectureCard(
    String subject,
    String time,
    Color color,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              color: color.withValues(alpha: 0.1),
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

  Widget _buildRecentActivity(bool isDesktop) {
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
        _buildActivityCard(
          'Tomorrows Timetable Updated',
          'Check the updated schedule for your classes tomorrow.',
          Icons.calendar_today,
          Colors.blue,
          '2 hours ago',
          isDesktop,
        ),
        const SizedBox(height: 12),
        _buildActivityCard(
          'Attendance Marked for Mathematics',
          'You have successfully marked your attendance in Mathematics.',
          Icons.check_circle,
          Colors.green,
          '4 hours ago',
          isDesktop,
        ),
        const SizedBox(height: 12),
        _buildActivityCard(
          'Critical Attendance Alert',
          'Your attendance is below 50%. Immediate action required!',
          Icons.warning,
          Colors.red,
          '1 day ago',
          isDesktop,
        ),
      ],
    );
  }

  Widget _buildActivityCard(
    String title,
    String description,
    IconData icon,
    Color color,
    String time,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: isDesktop ? 24 : 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: isDesktop ? 12 : 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
