import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/repositories/teacher_repository.dart';
import 'package:markmeapp/state/teacher_state.dart';
import 'package:markmeapp/core/utils/app_logger.dart';
import 'package:markmeapp/presentation/widgets/dashboard_action_card.dart';
import 'package:markmeapp/presentation/widgets/lectures_widget.dart';
import 'package:markmeapp/presentation/widgets/recent_activity_widget.dart';
import 'package:markmeapp/presentation/widgets/ui/error.dart';

class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});

  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard> {
  bool isLoading = true;
  String errorMessage = '';
  List<dynamic> upcomingSessions = [];
  List<dynamic> currentSessions = [];
  List<dynamic> pastSessions = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSessions();
      _fetchProfileData();
    });
  }

  Future<void> _fetchProfileData() async {
    final state = ref.read(teacherStoreProvider);

    AppLogger.info("I am inside fetching profile of teacher");

    // If profile already exists in state → do NOT fetch again
    if (state.profile != null) {
      // AppLogger.info("Profile already exists in state ${state.profile}");
      return;
    }

    AppLogger.info("Profile does not exist in state ${state.profile}");

    final teacherStore = ref.read(teacherStoreProvider.notifier);
    await teacherStore.loadProfile();
  }

  Future<void> _fetchSessions() async {
    try {
      final teacherRepo = ref.read(teacherRepositoryProvider);
      final response = await teacherRepo.fetchTodaySessions();

      if (response['success'] == true) {
        setState(() {
          upcomingSessions = response['data']['upcoming'] ?? [];
          currentSessions = response['data']['current'] ?? [];
          pastSessions = response['data']['past'] ?? [];
          isLoading = false;
          errorMessage = ''; // ✅ clear error
        });
      } else {
        // ✅ API responded but not successful
        setState(() {
          errorMessage = response['error'] ?? 'Something went wrong';
          isLoading = false;
        });
      }
    } catch (e) {
      // ✅ Actual network / server error
      setState(() {
        errorMessage = 'An error occurred while loading data.';
        isLoading = false;
      });
    }
  }

  void _retryFetch() {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    _fetchSessions();
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
    // ✅ Still loading — show skeleton
    if (isLoading) {
      // return DashboardSkeleton(isDesktop: isDesktop);
    }

    // ✅ Actual error (API failed, server error, etc.)
    if (errorMessage.isNotEmpty) {
      return CustomErrorWidget(
        errorMessage: errorMessage,
        onRetry: _retryFetch,
        isDesktop: isDesktop,
      );
    }

    // ✅ API success — show all widgets (even if empty)
    return _buildDashboardWidgets(isDesktop);
  }

  Widget _buildActionButtons() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        DashboardActionCard(
          icon: Icons.notifications_active,
          title: 'Push Notification',
          onTap: () {
            context.go('/teacher/push-notification');
          },
          color: Colors.blue.shade600,
          index: 0,
        ),
      ],
    );
  }

  Widget _buildDashboardWidgets(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildActionButtons(),
        const SizedBox(height: 32),

        // 🔹 Current Sessions
        LecturesWidget(
          title: "Current Sessions",
          sessions: currentSessions,
          isLoading: false,
          errorMessage: '',
          onRetry: _retryFetch,
          isDesktop: isDesktop,
          entityType: 'teacher',
        ),
        const SizedBox(height: 24),

        // 🔹 Upcoming Sessions
        LecturesWidget(
          title: "Upcoming Sessions",
          sessions: upcomingSessions,
          isLoading: false,
          errorMessage: '',
          onRetry: _retryFetch,
          isDesktop: isDesktop,
          entityType: 'teacher',
        ),
        const SizedBox(height: 24),

        // 🔹 Past Sessions
        LecturesWidget(
          title: "Past Sessions",
          sessions: pastSessions,
          isLoading: false,
          errorMessage: '',
          onRetry: _retryFetch,
          isDesktop: isDesktop,
          entityType: 'teacher',
        ),
        const SizedBox(height: 24),

        // 🔹 Recent Activity
        RecentActivityWidget(isDesktop: isDesktop),
      ],
    );
  }
}
