import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/repositories/student_repository.dart';
import 'package:markmeapp/presentation/skeleton/student_dashboard_skeleton.dart';
import 'package:markmeapp/presentation/widgets/attendance_chart_widget.dart';
import 'package:markmeapp/presentation/widgets/subject_selector_widget.dart';
import 'package:markmeapp/presentation/widgets/attendance_stats_widget.dart';
import 'package:markmeapp/presentation/widgets/lectures_widget.dart';
import 'package:markmeapp/presentation/widgets/recent_activity_widget.dart';
import 'package:markmeapp/presentation/widgets/bunk_safety/tomorrow_bunk_safety_card.dart';
import 'package:markmeapp/presentation/widgets/ui/error.dart';
import 'package:markmeapp/core/utils/student_data_processor.dart';
import 'package:markmeapp/state/student_state.dart';

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

  // Bunk Safety State
  bool isLoadingBunkSafety = true;
  String bunkSafetyError = '';
  Map<String, dynamic>? bunkSafetyData;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAttendanceData();
      _fetchUpcomingSessions();
      _fetchTomorrowBunkSafety();
      _fetchProfileData();
    });
  }

  Future<void> _fetchProfileData() async {
    final state = ref.read(studentStoreProvider);

    // 🔥 If profile already exists in state → do NOT fetch again
    if (state.profile != null) {
      return;
    }

    final studentStore = ref.read(studentStoreProvider.notifier);
    await studentStore.loadProfile();
  }

  Future<void> _fetchAttendanceData() async {
    try {
      final studentRepo = ref.read(studentRepositoryProvider);
      final response = await studentRepo.fetchStudentAttendance();

      if (response['success'] == true) {
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
          upcomingSessions = response['data']['upcoming'] ?? [];
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

  Future<void> _fetchTomorrowBunkSafety() async {
    try {
      final studentRepo = ref.read(studentRepositoryProvider);
      final response = await studentRepo.fetchTomorrowBunkSafety();

      if (response['success'] == true) {
        setState(() {
          bunkSafetyData = response['data'];
          isLoadingBunkSafety = false;
        });
      } else {
        setState(() {
          bunkSafetyError =
              response['error'] ?? 'Failed to load bunk safety info';
          isLoadingBunkSafety = false;
        });
      }
    } catch (e) {
      setState(() {
        bunkSafetyError = 'An error occurred: $e';
        isLoadingBunkSafety = false;
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
    _fetchUpcomingSessions();
    _fetchTomorrowBunkSafety();
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

        TomorrowBunkSafetyCard(
          isLoading: isLoadingBunkSafety,
          errorMessage: bunkSafetyError,
          data: bunkSafetyData,
          onRetry: () {
            setState(() {
              isLoadingBunkSafety = true;
              bunkSafetyError = '';
            });
            _fetchTomorrowBunkSafety();
          },
          onViewDetails: () {
            context.push("/student/weekly-bunk-safety");
          },
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

        LecturesWidget(
          title: "Upcoming Session",
          sessions: upcomingSessions,
          isLoading: isLoadingUpcoming,
          errorMessage: upcomingErrorMessage,
          onRetry: _retryUpcomingFetch,
          isDesktop: isDesktop,
          entityType: 'student',
        ),

        const SizedBox(height: 24),

        RecentActivityWidget(isDesktop: isDesktop),
      ],
    );
  }
}
