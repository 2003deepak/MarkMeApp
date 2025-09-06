import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/schedule_bloc.dart';
import '../widgets/schedule_card.dart';
import '../widgets/mock_data_banner.dart';
import '../../data/models/schedule_model.dart';
import '../../data/services/schedule_service.dart';

/// Dynamic schedule/calendar page that displays class schedules from backend
/// This page handles the complete schedule experience including:
/// - Loading schedules from backend API with date range filtering
/// - Calendar view with monthly navigation
/// - Daily schedule view with class details
/// - Attendance marking functionality
/// - Pull-to-refresh and error handling
/// - Filter options by class type, subject, and status
/// 
/// Backend developers: This page integrates with your schedule API endpoints.
/// Ensure your backend implements the following endpoints:
/// - GET /api/schedules (with date range, filtering)
/// - POST /api/schedules/{id}/attendance (mark attendance)
/// - PUT /api/schedules/{id} (update schedule)
/// - GET /api/schedules/today (today's schedule)
/// - GET /api/schedules/week (current week's schedule)
class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  
  /// Tab controller for switching between views
  late TabController _tabController;
  
  /// Current selected date for calendar view
  DateTime _selectedDate = DateTime.now();
  
  /// Current month being displayed in calendar
  DateTime _currentMonth = DateTime.now();
  
  /// Current filter applied to schedules
  ClassType? _currentFilter;
  
  /// Current subject filter
  String? _subjectFilter;
  
  /// Current status filter
  ScheduleStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load initial schedules when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSchedulesForCurrentView();
    });
    
    // Listen to tab changes to load appropriate data
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _loadSchedulesForCurrentView();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Keep the page alive to maintain state
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      
      // App bar with title and filter options
      appBar: AppBar(
        title: const Text(
          'Schedule',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        
        // Filter and refresh actions
        actions: [
          // Filter button
          PopupMenuButton<String>(
            icon: Icon(
              Icons.filter_list,
              color: Colors.grey.shade700,
            ),
            onSelected: _handleFilterSelection,
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Classes'),
              ),
              const PopupMenuItem(
                value: 'lecture',
                child: Text('Lectures'),
              ),
              const PopupMenuItem(
                value: 'practical',
                child: Text('Practicals'),
              ),
              const PopupMenuItem(
                value: 'tutorial',
                child: Text('Tutorials'),
              ),
              const PopupMenuItem(
                value: 'exam',
                child: Text('Exams'),
              ),
              const PopupMenuItem(
                value: 'scheduled',
                child: Text('Scheduled Only'),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Text('Completed'),
              ),
            ],
          ),
          
          // Refresh button
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.grey.shade700,
            ),
            onPressed: () => _refreshCurrentView(),
            tooltip: 'Refresh',
          ),
        ],
        
        // Tab bar for different views
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue.shade600,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.blue.shade600,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Week'),
            Tab(text: 'Calendar'),
          ],
        ),
      ),
      
      // Main schedule content with tabs
      body: Column(
        children: [
          // Mock data banner
          const MockDataBanner(
            showBanner: ScheduleService.useMockData,
            message: 'Demo Mode - Using Mock Schedule Data',
          ),
          
          // Main content
          Expanded(
            child: BlocConsumer<ScheduleBloc, ScheduleState>(
        listener: (context, state) {
          // Handle error states with snackbar
          if (state is ScheduleError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade600,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => _refreshCurrentView(),
                ),
              ),
            );
          }
          
          // Handle attendance marked successfully
          if (state is AttendanceMarked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.isPresent 
                      ? 'Attendance marked as Present' 
                      : 'Attendance marked as Absent',
                ),
                backgroundColor: state.isPresent 
                    ? Colors.green.shade600 
                    : Colors.orange.shade600,
              ),
            );
          }
        },
              builder: (context, state) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Today's schedule tab
                    _buildTodayView(context, state),
                    
                    // Week view tab
                    _buildWeekView(context, state),
                    
                    // Calendar view tab
                    _buildCalendarView(context, state),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds today's schedule view
  Widget _buildTodayView(BuildContext context, ScheduleState state) {
    if (state is ScheduleInitial || state is ScheduleLoading) {
      return _buildLoadingState('Loading today\'s schedule...');
    }
    
    if (state is ScheduleError && state.currentSchedules.isEmpty) {
      return _buildErrorState(context, state.message);
    }
    
    List<ScheduleModel> todaySchedules = [];
    bool isRefreshing = false;
    
    if (state is ScheduleLoaded) {
      todaySchedules = state.todaySchedules;
    } else if (state is ScheduleRefreshing) {
      final today = DateTime.now();
      todaySchedules = state.currentSchedules.where((schedule) {
        return schedule.startTime.year == today.year &&
               schedule.startTime.month == today.month &&
               schedule.startTime.day == today.day;
      }).toList();
      isRefreshing = true;
    } else if (state is ScheduleError) {
      final today = DateTime.now();
      todaySchedules = state.currentSchedules.where((schedule) {
        return schedule.startTime.year == today.year &&
               schedule.startTime.month == today.month &&
               schedule.startTime.day == today.day;
      }).toList();
    }
    
    if (todaySchedules.isEmpty) {
      return _buildEmptyState(
        context,
        'No classes today',
        'Enjoy your free day! Pull down to refresh.',
        Icons.free_breakfast,
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ScheduleBloc>().add(const LoadTodaySchedule(isRefresh: true));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: todaySchedules.length,
        itemBuilder: (context, index) {
          final schedule = todaySchedules[index];
          return ScheduleCard(
            schedule: schedule,
            onAttendanceTap: () => _markAttendance(context, schedule),
            showDate: false, // Don't show date for today view
          );
        },
      ),
    );
  }

  /// Builds week view
  Widget _buildWeekView(BuildContext context, ScheduleState state) {
    if (state is ScheduleInitial || state is ScheduleLoading) {
      return _buildLoadingState('Loading week\'s schedule...');
    }
    
    if (state is ScheduleError && state.currentSchedules.isEmpty) {
      return _buildErrorState(context, state.message);
    }
    
    List<ScheduleModel> weekSchedules = [];
    
    if (state is ScheduleLoaded) {
      weekSchedules = state.schedules;
    } else if (state is ScheduleRefreshing) {
      weekSchedules = state.currentSchedules;
    } else if (state is ScheduleError) {
      weekSchedules = state.currentSchedules;
    }
    
    if (weekSchedules.isEmpty) {
      return _buildEmptyState(
        context,
        'No classes this week',
        'Your schedule is clear for this week. Pull down to refresh.',
        Icons.event_available,
      );
    }
    
    // Group schedules by date
    final groupedSchedules = <DateTime, List<ScheduleModel>>{};
    for (final schedule in weekSchedules) {
      final date = DateTime(
        schedule.startTime.year,
        schedule.startTime.month,
        schedule.startTime.day,
      );
      
      if (groupedSchedules[date] == null) {
        groupedSchedules[date] = [];
      }
      groupedSchedules[date]!.add(schedule);
    }
    
    // Sort dates
    final sortedDates = groupedSchedules.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ScheduleBloc>().add(const LoadWeekSchedule(isRefresh: true));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final daySchedules = groupedSchedules[date]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _formatDateHeader(date),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              
              // Schedules for this date
              ...daySchedules.map((schedule) => ScheduleCard(
                schedule: schedule,
                onAttendanceTap: () => _markAttendance(context, schedule),
                showDate: false,
              )),
              
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  /// Builds calendar view with monthly navigation
  Widget _buildCalendarView(BuildContext context, ScheduleState state) {
    if (state is ScheduleInitial || state is ScheduleLoading) {
      return _buildLoadingState('Loading calendar...');
    }
    
    List<ScheduleModel> schedules = [];
    
    if (state is ScheduleLoaded) {
      schedules = state.schedules;
    } else if (state is ScheduleRefreshing) {
      schedules = state.currentSchedules;
    } else if (state is ScheduleError) {
      schedules = state.currentSchedules;
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        _loadSchedulesForMonth(_currentMonth);
      },
      child: Column(
        children: [
          // Calendar header with month navigation
          _buildCalendarHeader(),
          
          // Calendar grid
          _buildCalendarGrid(schedules),
          
          // Selected date's schedules
          Expanded(
            child: _buildSelectedDateSchedules(schedules),
          ),
        ],
      ),
    );
  }

  /// Builds calendar header with month navigation
  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _navigateMonth(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          
          Text(
            _formatMonthYear(_currentMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          IconButton(
            onPressed: () => _navigateMonth(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  /// Builds calendar grid
  Widget _buildCalendarGrid(List<ScheduleModel> schedules) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          
          // Calendar days
          ..._buildCalendarWeeks(schedules),
        ],
      ),
    );
  }

  /// Builds calendar weeks
  List<Widget> _buildCalendarWeeks(List<ScheduleModel> schedules) {
    final weeks = <Widget>[];
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    
    // Calculate start date (Monday of the first week)
    final startDate = firstDayOfMonth.subtract(
      Duration(days: firstDayOfMonth.weekday - 1),
    );
    
    DateTime currentDate = startDate;
    
    while (currentDate.isBefore(lastDayOfMonth) || 
           currentDate.month == _currentMonth.month) {
      final weekDays = <Widget>[];
      
      for (int i = 0; i < 7; i++) {
        final daySchedules = schedules.where((schedule) {
          return schedule.startTime.year == currentDate.year &&
                 schedule.startTime.month == currentDate.month &&
                 schedule.startTime.day == currentDate.day;
        }).toList();
        
        weekDays.add(_buildCalendarDay(currentDate, daySchedules));
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
      weeks.add(Row(children: weekDays));
      
      if (currentDate.month != _currentMonth.month && 
          currentDate.day > 7) {
        break;
      }
    }
    
    return weeks;
  }

  /// Builds individual calendar day
  Widget _buildCalendarDay(DateTime date, List<ScheduleModel> daySchedules) {
    final isCurrentMonth = date.month == _currentMonth.month;
    final isSelected = date.year == _selectedDate.year &&
                      date.month == _selectedDate.month &&
                      date.day == _selectedDate.day;
    final isToday = date.year == DateTime.now().year &&
                   date.month == DateTime.now().month &&
                   date.day == DateTime.now().day;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedDate = date;
          });
        },
        child: Container(
          height: 50,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue.shade600
                : isToday
                    ? Colors.blue.shade50
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // Date number
              Center(
                child: Text(
                  date.day.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? Colors.white
                        : isCurrentMonth
                            ? isToday
                                ? Colors.blue.shade600
                                : Colors.black87
                            : Colors.grey.shade400,
                  ),
                ),
              ),
              
              // Schedule indicator dots
              if (daySchedules.isNotEmpty)
                Positioned(
                  bottom: 4,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: daySchedules.take(3).map((schedule) {
                      return Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : _getScheduleColor(schedule.classType),
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds selected date's schedules
  Widget _buildSelectedDateSchedules(List<ScheduleModel> schedules) {
    final selectedDateSchedules = schedules.where((schedule) {
      return schedule.startTime.year == _selectedDate.year &&
             schedule.startTime.month == _selectedDate.month &&
             schedule.startTime.day == _selectedDate.day;
    }).toList();
    
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected date header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Text(
              _formatSelectedDate(_selectedDate),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Schedules list
          Expanded(
            child: selectedDateSchedules.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No classes on this date',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: selectedDateSchedules.length,
                    itemBuilder: (context, index) {
                      final schedule = selectedDateSchedules[index];
                      return ScheduleCard(
                        schedule: schedule,
                        onAttendanceTap: () => _markAttendance(context, schedule),
                        showDate: false,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Builds loading state
  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds error state
  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _refreshCurrentView(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds empty state
  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String message,
    IconData icon,
  ) {
    return RefreshIndicator(
      onRefresh: () async => _refreshCurrentView(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => _refreshCurrentView(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Loads schedules based on current tab view
  void _loadSchedulesForCurrentView() {
    switch (_tabController.index) {
      case 0: // Today
        context.read<ScheduleBloc>().add(const LoadTodaySchedule());
        break;
      case 1: // Week
        context.read<ScheduleBloc>().add(const LoadWeekSchedule());
        break;
      case 2: // Calendar
        _loadSchedulesForMonth(_currentMonth);
        break;
    }
  }

  /// Refreshes current view
  void _refreshCurrentView() {
    switch (_tabController.index) {
      case 0: // Today
        context.read<ScheduleBloc>().add(const LoadTodaySchedule(isRefresh: true));
        break;
      case 1: // Week
        context.read<ScheduleBloc>().add(const LoadWeekSchedule(isRefresh: true));
        break;
      case 2: // Calendar
        _loadSchedulesForMonth(_currentMonth, isRefresh: true);
        break;
    }
  }

  /// Loads schedules for a specific month
  void _loadSchedulesForMonth(DateTime month, {bool isRefresh = false}) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    
    context.read<ScheduleBloc>().add(LoadSchedules(
      startDate: startOfMonth,
      endDate: endOfMonth,
      isRefresh: isRefresh,
      filterType: _currentFilter,
      subjectCode: _subjectFilter,
      status: _statusFilter,
    ));
  }

  /// Navigates to previous/next month
  void _navigateMonth(int direction) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + direction,
        1,
      );
    });
    
    _loadSchedulesForMonth(_currentMonth);
  }

  /// Handles filter selection
  void _handleFilterSelection(String value) {
    ClassType? classType;
    ScheduleStatus? status;
    
    switch (value) {
      case 'all':
        classType = null;
        status = null;
        break;
      case 'lecture':
        classType = ClassType.lecture;
        break;
      case 'practical':
        classType = ClassType.practical;
        break;
      case 'tutorial':
        classType = ClassType.tutorial;
        break;
      case 'exam':
        classType = ClassType.exam;
        break;
      case 'scheduled':
        status = ScheduleStatus.scheduled;
        break;
      case 'completed':
        status = ScheduleStatus.completed;
        break;
    }
    
    setState(() {
      _currentFilter = classType;
      _statusFilter = status;
    });
    
    _refreshCurrentView();
  }

  /// Marks attendance for a schedule
  /// Backend developers: This calls POST /api/schedules/{id}/attendance
  void _markAttendance(BuildContext context, ScheduleModel schedule) {
    if (schedule.attendanceMarked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance already marked for this class'),
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Mark Attendance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${schedule.subjectName} (${schedule.subjectCode})'),
              const SizedBox(height: 4),
              Text(
                schedule.formattedTimeRange,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              const Text('Mark your attendance:'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<ScheduleBloc>().add(MarkAttendance(
                  scheduleId: schedule.id,
                  isPresent: false,
                ));
              },
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Absent'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<ScheduleBloc>().add(MarkAttendance(
                  scheduleId: schedule.id,
                  isPresent: true,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Present'),
            ),
          ],
        );
      },
    );
  }

  /// Gets color for schedule type
  Color _getScheduleColor(ClassType type) {
    switch (type) {
      case ClassType.lecture:
        return Colors.blue.shade600;
      case ClassType.practical:
        return Colors.green.shade600;
      case ClassType.tutorial:
        return Colors.orange.shade600;
      case ClassType.exam:
        return Colors.red.shade600;
      case ClassType.assignment:
        return Colors.purple.shade600;
    }
  }

  /// Formats date header for week view
  String _formatDateHeader(DateTime date) {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    final day = date.day;
    
    final today = DateTime.now();
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today, $month $day';
    }
    
    final tomorrow = today.add(const Duration(days: 1));
    if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Tomorrow, $month $day';
    }
    
    return '$weekday, $month $day';
  }

  /// Formats month year for calendar header
  String _formatMonthYear(DateTime date) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                   'July', 'August', 'September', 'October', 'November', 'December'];
    
    return '${months[date.month - 1]} ${date.year}';
  }

  /// Formats selected date
  String _formatSelectedDate(DateTime date) {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                   'July', 'August', 'September', 'October', 'November', 'December'];
    
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    final day = date.day;
    
    final today = DateTime.now();
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today, $month $day';
    }
    
    return '$weekday, $month $day';
  }
}