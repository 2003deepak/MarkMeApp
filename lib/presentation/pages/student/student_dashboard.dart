import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _rotationAnimation;
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
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _rotationController.forward();
  }

  @override
  void dispose() {
    _rotationController.dispose();
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
          title: '${data['percentage'].toStringAsFixed(1)}%',
          radius: touchedIndex == 0 ? 110 : 100,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: missed.toDouble(),
          title: '${(100 - data['percentage']).toStringAsFixed(1)}%',
          radius: touchedIndex == 1 ? 110 : 100,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
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
          title: '${overallPercentage.toStringAsFixed(1)}%',
          radius: touchedIndex == 0 ? 110 : 100,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: missed.toDouble(),
          title: '${(100 - overallPercentage).toStringAsFixed(1)}%',
          radius: touchedIndex == 1 ? 110 : 100,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Dashboard',
              style: TextStyle(
                fontSize: isDesktop ? 24 : 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            Text(
              'Rahul Kumar',
              style: TextStyle(
                fontSize: isDesktop ? 14 : 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.logout,
                  size: isDesktop ? 24 : 20,
                  color: Colors.red.shade600,
                ),
              ),
              onPressed: () {
                context.go('/login');
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
            color: Colors.black.withOpacity(0.05),
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
            ...subjectData.keys.map((subject) => 
              _buildSubjectChip(subject, subject, isDesktop)),
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
        _rotationController.reset();
        _rotationController.forward();
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
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart,
                color: Colors.blue.shade600,
                size: isDesktop ?  : 24,
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
          const SizedBox(height: 24),
          Center(
            child: AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value * 2 * 3.14159,
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: SizedBox(
                          height: isDesktop ? 100 : 120,
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection == null) {
                                      touchedIndex = -1;
                                      _scaleController.reverse();
                                      return;
                                    }
                                    touchedIndex = pieTouchResponse
                                        .touchedSection!.touchedSectionIndex;
                                    _scaleController.forward();
                                  });
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 4,
                              centerSpaceRadius: isDesktop ? 60 : 50,
                              sections: _getPieChartSections(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Present', Colors.green, isDesktop),
              _buildLegendItem('Absent', Colors.grey.shade300, isDesktop),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDesktop) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isDesktop ? 16 : 12,
          height: isDesktop ? 16 : 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 16 : 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ],
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
              isDesktop,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withOpacity(0.3),
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
            color: Colors.white.withOpacity(0.3),
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

  Widget _buildStatItem(String label, String value, IconData icon, bool isDesktop) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: isDesktop ? 28 : 24,
        ),
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
            Expanded(child: _buildLectureCard('Mathematics', '09:00 AM - 10:30 AM', Colors.blue, isDesktop)),
            const SizedBox(width: 12),
            Expanded(child: _buildLectureCard('Physics', '10:30 AM - 12:00 PM', Colors.green, isDesktop)),
            const SizedBox(width: 12),
            Expanded(child: _buildLectureCard('Chemistry', '12:00 PM - 01:30 PM', Colors.orange, isDesktop)),
          ],
        ),
      ],
    );
  }

  Widget _buildLectureCard(String subject, String time, Color color, bool isDesktop) {
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
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: isDesktop ? 24 : 20,
            ),
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