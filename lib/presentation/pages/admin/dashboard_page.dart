import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/presentation/widgets/admin/dashboard_section_header.dart';
import 'package:markmeapp/presentation/widgets/admin/live_session_card.dart';
import 'package:markmeapp/presentation/widgets/admin/summary_stat_card.dart';
import 'package:markmeapp/presentation/widgets/admin/extreme_stat_card.dart';
import 'package:markmeapp/presentation/widgets/admin/trends_chart_card.dart';
import 'package:markmeapp/presentation/widgets/ui/search_bar.dart';
import 'package:markmeapp/presentation/widgets/admin/admin_filter_sheet.dart';
import 'package:markmeapp/presentation/widgets/ui/filter_chip.dart';
import 'package:markmeapp/presentation/widgets/admin/faculty_leaderboard.dart';
import 'package:markmeapp/presentation/widgets/admin/attendance_extremes_section.dart';
import 'package:markmeapp/presentation/skeleton/widgets/live_session_skeleton_card.dart';
import 'package:markmeapp/presentation/skeleton/widgets/summary_stat_skeleton_card.dart';
import 'package:markmeapp/presentation/skeleton/widgets/trends_chart_skeleton.dart';
import 'package:markmeapp/data/models/live_session_model.dart';
import 'package:markmeapp/core/utils/app_logger.dart';
import 'package:markmeapp/data/repositories/admin_repository.dart';
import 'package:markmeapp/state/refresh_state.dart';
import 'package:markmeapp/state/admin_state.dart';
import 'package:markmeapp/data/models/teacher_leaderboard_model.dart';
import 'package:markmeapp/data/models/attendance_extremes_model.dart';


class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  late TextEditingController _searchController;
  Map<String, String?> _activeFilters = {
    'Department': null,
    'Subject': null,
    'Teacher': null,
  };
  List<LiveSession>? _liveSessions;
  bool _isLoadingLiveSessions = false;
  String? _liveSessionsError;

  // Leaderboard state
  List<LeaderboardEntry>? _leaderboardEntries;
  bool _isLoadingLeaderboard = false;
  String? _leaderboardError;
  String _selectedLeaderboardPeriod = 'weekly';

  // Extremes state
  AttendanceExtremesResponse? _extremesData;
  bool _isLoadingExtremes = false;
  String? _extremesError;
  String _selectedExtremesPeriod = 'weekly';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _fetchLiveSessions();
    _fetchLeaderboard();
    _fetchExtremes();
  }


  Future<void> _fetchLiveSessions() async {
    try {
      setState(() {
        _isLoadingLiveSessions = true;
        _liveSessionsError = null;
      });

      final result = await ref.read(adminRepositoryProvider).fetchLiveClasses();

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _liveSessions = result['data'] as List<LiveSession>;
            _isLoadingLiveSessions = false;
          });
        } else {
          setState(() {
            _liveSessionsError = result['error'];
            _isLoadingLiveSessions = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _liveSessionsError = e.toString();
          _isLoadingLiveSessions = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdminFilterSheet(
        initialFilters: _activeFilters,
        onApply: (newFilters) {
          setState(() {
            _activeFilters = newFilters;
          });
        },
      ),
    );
  }

  Future<void> _fetchLeaderboard() async {
    try {
      setState(() {
        _isLoadingLeaderboard = true;
        _leaderboardError = null;
      });

      final result = await ref.read(adminRepositoryProvider).fetchTeacherLeaderboard(_selectedLeaderboardPeriod);

      if (mounted) {
        if (result['success'] == true) {
          final response = result['data'] as TeacherLeaderboardResponse;
          setState(() {
            _leaderboardEntries = response.data;
            _isLoadingLeaderboard = false;
          });
        } else {
          setState(() {
            _leaderboardError = result['error'];
            _isLoadingLeaderboard = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _leaderboardError = e.toString();
          _isLoadingLeaderboard = false;
        });
      }
    }
  }

  Future<void> _fetchExtremes() async {
    try {
      setState(() {
        _isLoadingExtremes = true;
        _extremesError = null;
      });

      final result = await ref.read(adminRepositoryProvider).fetchAttendanceExtremes(_selectedExtremesPeriod);

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _extremesData = result['data'] as AttendanceExtremesResponse;
            _isLoadingExtremes = false;
          });
        } else {
          setState(() {
            _extremesError = result['error'];
            _isLoadingExtremes = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _extremesError = e.toString();
          _isLoadingExtremes = false;
        });
      }
    }
  }

  Future<void> _refreshAllData() async {
    await Future.wait([
      _fetchLiveSessions(),
      _fetchLeaderboard(),
      _fetchExtremes(),
      ref.read(adminStoreProvider.notifier).loadProfile(),
    ]);
  }


  @override
  Widget build(BuildContext context) {
    ref.listen(dashboardRefreshProvider, (previous, next) {
      if (next > 0) {
        _refreshAllData();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _refreshAllData,
        color: const Color(0xFF2563EB),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search and Filter Bar
           AppSearchBar(
            controller: _searchController,
            hintText: "Search sessions...",
            onFilterTap: _showFilterSheet,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            activeFilterCount: _activeFilters.values.where((v) => v != null).length,
          ),
          
          
          // Filter Chips
          if (_activeFilters.values.any((v) => v != null))
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _activeFilters.entries
                    .where((e) => e.value != null)
                    .map<Widget>((e) => FilterChipWidget(
                          label: "${e.key}: ${e.value!}",
                          onRemove: () {
                            setState(() {
                              _activeFilters[e.key] = null;
                            });
                          },
                          isDark: Theme.of(context).brightness == Brightness.dark,
                        ))
                    .toList(),
              ),
            ),

          const SizedBox(height: 12),

          // 2. Live Now Section
          const DashboardSectionHeader(title: "Live Now"),
          SizedBox(
            height: 200,
            child: _buildLiveSessionsList(),
          ),

          // 3. Summary Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _isLoadingLiveSessions // Using this as a proxy for now or add a new global loading
                ? Row(
                    children: const [
                      Expanded(child: SummaryStatSkeletonCard()),
                      SizedBox(width: 16),
                      Expanded(child: SummaryStatSkeletonCard()),
                    ],
                  )
                : Row(
                    children: const [
                      Expanded(
                        child: SummaryStatCard(
                          icon: "class",
                          label: "Classes in Session",
                          value: "42",
                          badgeText: "Active",
                          badgeColor: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SummaryStatCard(
                          icon: "turnout",
                          label: "Real-time Turnout",
                          value: "92%",
                          badgeText: "Avg",
                          badgeColor: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 24),

          // 4. Faculty Leaderboard
          _buildLeaderboard(),

          const SizedBox(height: 24),

          // 5. Past Attendance Trends
          const DashboardSectionHeader(
            title: "Past Attendance Trends",
            actionText: "View Report",
          ),
          _isLoadingLiveSessions // Proxying
              ? const TrendsChartSkeleton()
              : const TrendsChartCard(),

          const SizedBox(height: 24),

          // 6. Attendance Extremes
          AttendanceExtremesSection(
            extremes: _extremesData,
            isLoading: _isLoadingExtremes,
            selectedPeriod: _selectedExtremesPeriod,
            onPeriodChanged: (period) {
              setState(() {
                _selectedExtremesPeriod = period;
              });
              _fetchExtremes();
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }




  Widget _buildLeaderboard() {
    return FacultyLeaderboardCard(
      performers: _leaderboardEntries ?? [],
      isLoading: _isLoadingLeaderboard,
      selectedPeriod: _selectedLeaderboardPeriod,
      onPeriodChanged: (period) {
        setState(() {
          _selectedLeaderboardPeriod = period;
        });
        _fetchLeaderboard();
      },
      onViewFullLeaderboard: () {
        // Handle navigation
      },
    );
  }


  Widget _buildLiveSessionsList() {
    if (_isLoadingLiveSessions) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 20),
        itemCount: 3,
        itemBuilder: (context, index) => const LiveSessionSkeletonCard(),
      );
    }

    if (_liveSessionsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Oops! ${_liveSessionsError!}",
              style: const TextStyle(color: Colors.red),
            ),
            TextButton(
              onPressed: _fetchLiveSessions,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (_liveSessions == null || _liveSessions!.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                color: Color(0xFF94A3B8),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "No Active Sessions",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              "There are no live classes right now",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _fetchLiveSessions,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text("Check Again"),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 20),
      itemCount: _liveSessions!.length,
      itemBuilder: (context, index) {
        final session = _liveSessions![index];
        return LiveSessionCard(
          sessionType: session.sessionType,
          subject: session.subjectName,
          teacher: session.teacherName,
          active: session.presentStudents,
          total: session.totalStudents,
          isLab: session.isLab,
        );
      },
    );
  }

  String _getInitials(String name) {
    List<String> nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return nameParts[0][0] + nameParts[1][0];
    }
    return nameParts[0][0];
  }

  String _abbreviateDept(String dept) {
    if (dept.contains(' ')) {
      return dept.split(' ').map((word) => word[0]).join('');
    }
    return dept.substring(0, 3).toUpperCase();
  }
}
