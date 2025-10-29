// Student_Dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/data/repositories/student_repository.dart';
import 'package:markmeapp/presentation/skeleton/student_dashboard_skeleton.dart';
import 'package:markmeapp/presentation/widgets/attendance_chart_widget.dart';
import 'package:markmeapp/presentation/widgets/subject_selector_widget.dart';
import 'package:markmeapp/presentation/widgets/attendance_stats_widget.dart';
import 'package:markmeapp/presentation/widgets/ui/empty_data.dart';
import 'package:markmeapp/presentation/widgets/upcoming_lectures_widget.dart';
import 'package:markmeapp/presentation/widgets/recent_activity_widget.dart';
import 'package:markmeapp/presentation/widgets/ui/error.dart';
import 'package:markmeapp/core/utils/student_data_processor.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  String? selectedSubject;
  Map<String, Map<String, dynamic>> subjectData = {};
  Map<String, Map<String, dynamic>> componentData = {};
  bool isLoading = true;
  String errorMessage = '';
  Map<String, dynamic>? responseData;
  List<dynamic> upcomingSessions = [];
  bool isLoadingUpcoming = true;
  String upcomingErrorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
    _fetchUpcomingSessions();
  }

  Future<void> _fetchAttendanceData() async {
    try {
      final studentRepo = ref.read(studentRepositoryProvider);
      final response = await studentRepo.fetchStudentAttendance();

      if (response['success'] == true) {
        // print("The response = $response");
        final rawData = response['data'];
        final dataProcessor = StudentDataProcessor(rawData: rawData);

        setState(() {
          responseData = rawData;
          subjectData = dataProcessor.processSubjectData();
          componentData = dataProcessor.processComponentData();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              response['message'] ?? 'Failed to load attendance data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUpcomingSessions() async {
    try {
      final studentRepo = ref.read(studentRepositoryProvider);
      final response = await studentRepo.fetchUpcomingSessions();

      if (response['success'] == true) {
        setState(() {
          upcomingSessions = response['data']['upcoming_sessions'] ?? [];
          isLoadingUpcoming = false;
        });
      } else {
        setState(() {
          upcomingErrorMessage =
              response['error'] ?? 'Failed to load upcoming sessions';
          isLoadingUpcoming = false;
        });
      }
    } catch (e) {
      setState(() {
        upcomingErrorMessage = 'An error occurred: $e';
        isLoadingUpcoming = false;
      });
    }
  }

  Map<String, dynamic>? _getSelectedData() {
    final dataProcessor = StudentDataProcessor(
      subjectData: subjectData,
      componentData: componentData,
    );
    return dataProcessor.getSelectedData(selectedSubject);
  }

  void _onSubjectSelected(String? subject) {
    setState(() {
      selectedSubject = subject;
    });
  }

  void _retryFetch() {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    _fetchAttendanceData();
  }

  void _retryUpcomingFetch() {
    setState(() {
      isLoadingUpcoming = true;
      upcomingErrorMessage = '';
    });
    _fetchUpcomingSessions();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
        child: _buildDashboardContent(isDesktop),
      ),
    );
  }

  Widget _buildDashboardContent(bool isDesktop) {
    if (isLoading) {
      return DashboardSkeleton(isDesktop: isDesktop);
    }

    if (errorMessage.isNotEmpty) {
      return CustomErrorWidget(
        errorMessage: errorMessage,
        onRetry: _retryFetch,
        isDesktop: isDesktop,
      );
    }

    return _buildDashboardWidgets(isDesktop);
  }

  Widget _buildDashboardWidgets(bool isDesktop) {
    final List<Map<String, dynamic>> attendancesList = responseData != null
        ? (responseData!['attendances'] as List<dynamic>).map((item) {
            return Map<String, dynamic>.from(item);
          }).toList()
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubjectSelectorWidget(
          attendances: attendancesList,
          selectedSubject: selectedSubject,
          onSubjectSelected: _onSubjectSelected,
          isDesktop: isDesktop,
        ),

        const SizedBox(height: 24),

        AttendanceChartWidget(
          selectedData: _getSelectedData(),
          selectedSubject: selectedSubject,
          isDesktop: isDesktop,
        ),

        const SizedBox(height: 24),

        AttendanceStatsWidget(
          subjectData: _getSelectedData(),
          selectedSubject: selectedSubject,
          isDesktop: isDesktop,
        ),

        const SizedBox(height: 24),

        UpcomingLecturesWidget(
          upcomingSessions: upcomingSessions,
          isLoading: isLoadingUpcoming,
          errorMessage: upcomingErrorMessage,
          onRetry: _retryUpcomingFetch,
          isDesktop: isDesktop,
        ),

        const SizedBox(height: 24),

        RecentActivityWidget(isDesktop: isDesktop),
      ],
    );
  }
}
