import 'package:flutter/material.dart';
import 'package:markmeapp/presentation/widgets/attendance_chart_widget.dart';
import 'package:markmeapp/presentation/widgets/subject_selector_widget.dart';
import 'package:markmeapp/presentation/widgets/attendance_stats_widget.dart';
import 'package:markmeapp/presentation/widgets/upcoming_lectures_widget.dart';
import 'package:markmeapp/presentation/widgets/recent_activity_widget.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  String? selectedSubject;

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

  void _onSubjectSelected(String? subject) {
    setState(() {
      selectedSubject = subject;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(

        padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            SubjectSelectorWidget(
              subjectData: subjectData,
              selectedSubject: selectedSubject,
              onSubjectSelected: _onSubjectSelected,
              isDesktop: isDesktop,
            ),
            const SizedBox(height: 24),

            AttendanceChartWidget(
              subjectData: subjectData,
              selectedSubject: selectedSubject,
              isDesktop: isDesktop,
            ),

            const SizedBox(height: 24),
            AttendanceStatsWidget(
              subjectData: subjectData,
              selectedSubject: selectedSubject,
              isDesktop: isDesktop,
            ),

            const SizedBox(height: 24),
            
            UpcomingLecturesWidget(isDesktop: isDesktop),
            const SizedBox(height: 24),
            RecentActivityWidget(isDesktop: isDesktop),
          ],
        ),
      ),
    );
  }
}
