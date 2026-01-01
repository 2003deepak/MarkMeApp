import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/core/theme/app_theme.dart';
import 'package:markmeapp/data/models/attendance_history_model.dart';
import 'package:markmeapp/data/repositories/clerk_repository.dart';
import 'package:markmeapp/data/repositories/student_repository.dart';
import 'package:markmeapp/presentation/widgets/calendar/attendance_calendar.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';
import 'package:markmeapp/presentation/widgets/ui/filter_chip.dart';
import 'package:markmeapp/state/auth_state.dart';
import 'package:markmeapp/data/repositories/teacher_repository.dart';
import 'package:intl/intl.dart';
import 'package:markmeapp/presentation/widgets/ui/custom_bottom_sheet_layout.dart';
import 'package:markmeapp/presentation/widgets/ui/multi_select_dropdown.dart';

class AttendanceHistoryPage extends ConsumerStatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  ConsumerState<AttendanceHistoryPage> createState() =>
      _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends ConsumerState<AttendanceHistoryPage> {
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, List<AttendanceHistoryRecord>> _groupedRecords = {};
  Map<int, AttendanceDayStatus> _dayStatusMap = {};
  List<Map<String, String>> _subjects = [];
  List<String> _selectedSubjectIds = [];

  // Filter State
  List<String> _selectedPrograms = [];
  List<String> _selectedSemesters = [];
  List<String> _selectedDepartments = [];

  // Available Metadata (for dropdowns)
  final List<String> _availablePrograms = ['MCA', "AI"]; // Default
  final List<String> _availableSemesters = List.generate(
    8,
    (index) => (index + 1).toString(),
  );
  final List<String> _availableDepartments = [
    'CSE',
    'ECE',
    'MECH',
    'CIVIL',
    'EEE',
  ];
  List<Map<String, String>> _availableTeacherSubjects = [];
  List<Map<String, String>> _availableClerkSubjects = [];

  int _safeMinutes(String? time) {
    if (time == null || time.isEmpty || !time.contains(':')) {
      return 0;
    }

    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    return hour * 60 + minute;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePage();
    });
  }

  Future<void> _initializePage() async {
    final role = ref.read(authStoreProvider).role;

    if (role == 'student') {
      await _fetchSubjects();
      await _fetchAttendanceData();
    } else if (role == 'teacher') {
      await _fetchTeacherSubjects();
      await _fetchAttendanceData();
    } else if (role == 'clerk') {
      await _fetchClerkSubjects();
      await _fetchAttendanceData();
    } else {
      await _fetchAttendanceData();
    }
  }

  Future<void> _fetchTeacherSubjects() async {
    try {
      final teacherRepo = ref.read(teacherRepositoryProvider);
      final response = await teacherRepo.fetchClassForNotification();

      if (response['success'] == true) {
        final classes = response['data'] as List<dynamic>;

        final List<Map<String, String>> subjects = [];
        final Set<String> uniqueKeys = {};

        for (final cls in classes) {
          final subjectList = cls['subjects'] as List<dynamic>? ?? [];

          for (final sub in subjectList) {
            final subjectId = sub['subject_id']?.toString();
            final subjectName = sub['subject_name']?.toString();
            final component = sub['component']?.toString();

            if (subjectId == null ||
                subjectId.isEmpty ||
                subjectName == null ||
                component == null) {
              continue;
            }

            // Unique key to avoid duplicates
            final uniqueKey = '$subjectId-$component';

            if (!uniqueKeys.contains(uniqueKey)) {
              uniqueKeys.add(uniqueKey);

              subjects.add({
                'id': subjectId,
                'name': '$subjectName ($component)',
              });
            }
          }
        }

        if (mounted) {
          setState(() {
            _availableTeacherSubjects = subjects;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching teacher subjects: $e');
    }
  }

  Future<void> _fetchClerkSubjects() async {
    try {
      final clerkRepo = ref.read(clerkRepositoryProvider);

      final response = await clerkRepo.fetchSubjects(mode: "subject_listing");

      if (response['success'] == true) {
        final List data = response['data'] ?? [];

        final subjects = data.map<Map<String, String>>((e) {
          return {
            'id': e['subject_id'],
            'name': '${e['subject_name']} (${e['component']})',
          };
        }).toList();

        setState(() {
          _availableClerkSubjects = subjects;
        });
      }
    } catch (e) {
      debugPrint('Error fetching clerk subjects: $e');
    }
  }

  Future<void> _fetchSubjects() async {
    try {
      final repository = ref.read(studentRepositoryProvider);
      final response = await repository.fetchStudentAttendance();

      if (response['success'] == true && response['data'] != null) {
        final attendances =
            response['data']['attendances'] as List<dynamic>? ?? [];
        final Map<String, String> uniqueSubjects = {};

        for (var item in attendances) {
          final subjectName = item['subject_name'] as String?;
          // Try to find subject_id, assuming it's available in the response
          final subjectId =
              item['subject_id'] as String? ?? item['_id'] as String?;

          if (subjectName != null && subjectId != null) {
            uniqueSubjects[subjectId] = subjectName;
          }
        }

        setState(() {
          _subjects = uniqueSubjects.entries
              .map((e) => {'id': e.key, 'name': e.value})
              .toList();
          // Sort alphabetically
          _subjects.sort(
            (a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''),
          );
        });
      }
    } catch (e) {
      debugPrint('Error fetching subjects: $e');
    }
  }

  Future<void> _fetchAttendanceData() async {
    if (_groupedRecords.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final repository = ref.read(studentRepositoryProvider);
      final response = await repository.fetchAttendanceHistory(
        month: _selectedMonth.month,
        year: _selectedMonth.year,
        subjectId: _selectedSubjectIds.isNotEmpty
            ? _selectedSubjectIds.join(',')
            : null,
        program: _selectedPrograms.isNotEmpty
            ? _selectedPrograms.join(',')
            : null,
        semester: _selectedSemesters.isNotEmpty
            ? _selectedSemesters.join(',')
            : null,
        department: _selectedDepartments.isNotEmpty
            ? _selectedDepartments.join(',')
            : null,
      );

      final attendanceResponse = AttendanceHistoryResponse.fromJson(response);

      if (attendanceResponse.success) {
        final records = attendanceResponse.records;

        // Group records by date
        final Map<String, List<AttendanceHistoryRecord>> grouped = {};
        final Map<int, AttendanceDayStatus> dayMap = {};

        for (var record in records) {
          final dateString = record.date;

          // Group by date
          if (!grouped.containsKey(dateString)) {
            grouped[dateString] = [];
          }
          grouped[dateString]!.add(record);
        }

        // Calculate day status for each unique day
        for (var entry in grouped.entries) {
          final date = DateTime.parse(entry.key);
          final dayRecords = entry.value;
          final day = date.day;

          final totalClasses = dayRecords.length;
          final presentClasses = dayRecords.where((r) => r.present).length;
          final absentClasses = totalClasses - presentClasses;
          final percentage = totalClasses > 0
              ? (presentClasses / totalClasses * 100).round()
              : 0;

          dayMap[day] = AttendanceDayStatus(
            date: date,
            totalClasses: totalClasses,
            presentClasses: presentClasses,
            absentClasses: absentClasses,
            percentage: percentage,
          );
        }

        setState(() {
          _groupedRecords = grouped;
          _dayStatusMap = dayMap;

          // Set initial selected day to today if it has records
          final today = DateTime.now();
          if (_groupedRecords.containsKey(_formatDate(today))) {
            _selectedDay = today;
          }

          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = attendanceResponse.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load attendance: $e';
        _isLoading = false;
      });
    }
  }

  void _handlePreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      _selectedDay = null;
      _dayStatusMap.clear();
    });
    _fetchAttendanceData();
  }

  void _handleNextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      _selectedDay = null;
      _dayStatusMap.clear();
    });
    _fetchAttendanceData();
  }

  void _handleDaySelected(int day) {
    final selectedDate = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      day,
    );
    final dateString = _formatDate(selectedDate);

    setState(() {
      if (_groupedRecords.containsKey(dateString)) {
        _selectedDay = selectedDate;
      } else {
        // If no records for this day, still select it but show message
        _selectedDay = selectedDate;
      }
    });
  }

  List<AttendanceHistoryRecord> _getSelectedDayRecords() {
    if (_selectedDay == null) return [];
    final dateString = _formatDate(_selectedDay!);
    return _groupedRecords[dateString] ?? [];
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  final _statusCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authStoreProvider.select((s) => s.role));
    final isStudent = role == 'student';

    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        // If Role is Admin or Clerk , show App Bar
        appBar: role == 'clerk'
            ? MarkMeAppBar(title: "Attendance History")
            : null,
        backgroundColor: const Color(0xFFF1F5F9),
        floatingActionButton: !isStudent
            ? FloatingActionButton.extended(
                onPressed: _showFilterBottomSheet,
                icon: Icon(
                  Icons.tune,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
                label: const Text(
                  'Filter',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: const Color(0xFF2563EB),
              )
            : null,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _fetchAttendanceData,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(
                            20,
                            8,
                            20,
                            80,
                          ), // Added bottom padding for FAB
                          children: _buildContent(),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent() {
    if (_errorMessage != null) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            onPressed: _fetchAttendanceData,
            child: const Text('Retry'),
          ),
        ),
      ];
    }

    final role = ref.read(authStoreProvider).role;

    return [
      if (role == 'student')
        _buildSubjectFilter()
      else
        _buildActiveFilterSummary(),
      const SizedBox(height: 16),
      AttendanceCalendar(
        selectedMonth: _selectedMonth,
        selectedDay: _selectedDay,
        dayStatusMap: _dayStatusMap,
        onPrevMonth: _handlePreviousMonth,
        onNextMonth: _handleNextMonth,
        onDaySelected: _handleDaySelected,
      ),

      const SizedBox(height: 24),
      _buildAttendanceRecordsSection(),
    ];
  }

  Widget _buildActiveFilterSummary() {
    final role = ref.read(authStoreProvider).role;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Widget> chips = [];

    if (_selectedDepartments.isNotEmpty) {
      chips.add(
        FilterChipWidget(
          label:
              'Dept: ${_selectedDepartments.length > 1 ? "${_selectedDepartments.length} selected" : _selectedDepartments.first}',
          onRemove: () {
            setState(() {
              _selectedDepartments = [];
            });
            _fetchAttendanceData();
          },
          isDark: isDark,
        ),
      );
    }
    if (_selectedPrograms.isNotEmpty) {
      chips.add(
        FilterChipWidget(
          label:
              'Program: ${_selectedPrograms.length > 1 ? "${_selectedPrograms.length} selected" : _selectedPrograms.first}',
          onRemove: () {
            setState(() {
              _selectedPrograms = [];
            });
            _fetchAttendanceData();
          },
          isDark: isDark,
        ),
      );
    }
    if (_selectedSemesters.isNotEmpty) {
      chips.add(
        FilterChipWidget(
          label:
              'Sem: ${_selectedSemesters.length > 1 ? "${_selectedSemesters.length} selected" : _selectedSemesters.first}',
          onRemove: () {
            setState(() {
              _selectedSemesters = [];
            });
            _fetchAttendanceData();
          },
          isDark: isDark,
        ),
      );
    }

    // For Teacher/Clerk, show selected subject
    if ((role == 'teacher' || role == 'clerk') &&
        _selectedSubjectIds.isNotEmpty) {
      final List<Map<String, String>> source = role == 'teacher'
          ? _availableTeacherSubjects
          : _availableClerkSubjects;

      final names = _selectedSubjectIds.map((id) {
        final sub = source.firstWhere(
          (s) => s['id'] == id,
          orElse: () => {'name': 'Unknown'},
        );
        return sub['name']!;
      }).toList();

      chips.add(
        FilterChipWidget(
          label: names.length > 1
              ? "${names.length} subjects selected"
              : names.first,
          onRemove: () {
            setState(() {
              _selectedSubjectIds = [];
            });
            _fetchAttendanceData();
          },
          isDark: isDark,
        ),
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  void _showFilterBottomSheet() {
    final role = ref.read(authStoreProvider).role;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        role: role ?? 'student',
        initialPrograms: _selectedPrograms,
        initialSemesters: _selectedSemesters,
        initialDepartments: _selectedDepartments,
        initialSubjectIds: _selectedSubjectIds,
        availablePrograms: _availablePrograms,
        availableSemesters: _availableSemesters,
        availableDepartments: _availableDepartments,
        availableTeacherSubjects: _availableTeacherSubjects,
        availableClerkSubjects: _availableClerkSubjects,

        onApply: (progs, sems, depts, subs) {
          setState(() {
            _selectedPrograms = progs;
            _selectedSemesters = sems;
            _selectedDepartments = depts;
            _selectedSubjectIds = subs;
            _selectedDay = null;
            _dayStatusMap.clear();
          });
          _fetchAttendanceData();
        },
      ),
    );
  }

  Widget _buildSubjectFilter() {
    if (_subjects.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildSelectionChip(
            label: 'All Subjects',
            isSelected: _selectedSubjectIds.isEmpty,
            onTap: () {
              setState(() {
                _selectedSubjectIds = [];
                _selectedDay = null; // Reset selection to refresh view properly
                _dayStatusMap.clear();
              });
              _fetchAttendanceData();
            },
          ),
          ..._subjects.map((subject) {
            final isSelected = _selectedSubjectIds.contains(subject['id']);
            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: _buildSelectionChip(
                label: subject['name'] ?? 'Unknown',
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedSubjectIds.remove(subject['id']);
                    } else {
                      _selectedSubjectIds.add(subject['id']!);
                    }
                    _selectedDay = null;
                    _dayStatusMap.clear();
                  });
                  _fetchAttendanceData();
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSelectionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B82F6)
              : isDark
              ? const Color(0xFF1E293B)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : isDark
                ? const Color(0xFF334155)
                : const Color(0xFFCBD5E1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : isDark
                ? const Color(0xFFF1F5F9)
                : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceRecordsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dayRecords = _getSelectedDayRecords();

    if (_selectedDay == null) {
      return _buildEmptyState(
        icon: Icons.calendar_today_outlined,
        title: 'Select a Day',
        message: 'Tap on any date in the calendar to view attendance records',
        isDark: isDark,
      );
    }

    if (dayRecords.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_busy_outlined,
        title: 'No Attendance Records',
        message:
            'No attendance was marked on ${DateFormat('MMMM d, yyyy').format(_selectedDay!)}',
        isDark: isDark,
      );
    }

    // Sort records by start time if available, otherwise by date/id
    final sortedRecords = List<AttendanceHistoryRecord>.from(dayRecords);

    sortedRecords.sort((a, b) {
      if (a.startTime != null && b.startTime != null) {
        return _safeMinutes(a.startTime).compareTo(_safeMinutes(b.startTime));
      }
      return 0; // Maintain original order or sort by another field if needed
    });

    final role = ref.read(authStoreProvider).role;
    final isStudent = role == 'student';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...sortedRecords.map((record) {
          if (isStudent) {
            return _buildAttendanceRecordCard(record);
          } else {
            return _buildTeacherAttendanceCard(record);
          }
        }),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRecordCard(AttendanceHistoryRecord record) {
    final status = record.present
        ? AttendanceStatus.present
        : AttendanceStatus.absent;
    final statusColor = _getStatusColor(status);
    final backgroundColor = _getStatusBackgroundColor(status);
    final statusText = record.present ? 'Present' : 'Absent';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _statusCardDecoration.copyWith(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: statusColor, width: 6)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      record.subject,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (record.isExceptionSession)
                Tooltip(
                  message:
                      "This session is either rescheduled or an extra class or cancelled",
                  triggerMode: TooltipTriggerMode.tap,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 12,
                          color: const Color.fromARGB(255, 0, 0, 0),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Special Session',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${record.startTime ?? "N/A"} - ${record.endTime ?? "N/A"}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherAttendanceCard(AttendanceHistoryRecord record) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentage = record.attendancePercentage ?? 0.0;

    final Color statusColor = percentage < 75
        ? const Color(0xFFEF4444)
        : const Color(0xFF10B981);

    final Color backgroundColor = isDark
        ? statusColor.withOpacity(0.2)
        : statusColor.withOpacity(0.1);

    return GestureDetector(
      onTap: () {
        // 🚀 NAVIGATION HERE
        final role = ref.read(authStoreProvider).role;
        context.push('/$role/attendance-detail/${record.attendanceId}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: _statusCardDecoration.copyWith(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: statusColor, width: 6)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.subject,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFF8FAFC)
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          if (record.componentType != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                record.componentType!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        label: 'Present',
                        value: '${record.presentCount ?? 0}',
                        color: const Color(0xFF10B981),
                        icon: Icons.check_circle_outline,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        label: 'Absent',
                        value: '${record.absentCount ?? 0}',
                        color: const Color(0xFFEF4444),
                        icon: Icons.cancel_outlined,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods for colors
  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return const Color.fromARGB(255, 80, 177, 16);
      case AttendanceStatus.absent:
        return const Color.fromARGB(255, 202, 11, 11);
      default:
        return Colors.transparent;
    }
  }

  Color _getStatusBackgroundColor(AttendanceStatus status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (status) {
      case AttendanceStatus.present:
        return isDark
            ? const Color(0xFF064E3B).withOpacity(0.3)
            : const Color(0xFFECFDF5);
      case AttendanceStatus.absent:
        return isDark
            ? const Color(0xFF7F1D1D).withOpacity(0.3)
            : const Color(0xFFFEF2F2);
      case AttendanceStatus.late:
        return isDark
            ? const Color(0xFF78350F).withOpacity(0.3)
            : const Color(0xFFFFFBEB);
      default:
        return isDark ? const Color(0xFF1E293B) : Colors.white;
    }
  }
}

// New data model for day status
class AttendanceDayStatus {
  final DateTime date;
  final int totalClasses;
  final int presentClasses;
  final int absentClasses;
  final int percentage;

  AttendanceDayStatus({
    required this.date,
    required this.totalClasses,
    required this.presentClasses,
    required this.absentClasses,
    required this.percentage,
  });
}

enum AttendanceStatus { present, absent, late, none, current }

class FilterBottomSheet extends StatefulWidget {
  final String role;
  final List<String> initialPrograms;
  final List<String> initialSemesters;
  final List<String> initialDepartments;
  final List<String> initialSubjectIds;
  final List<String> availablePrograms;
  final List<String> availableSemesters;
  final List<String> availableDepartments;
  final List<Map<String, String>> availableTeacherSubjects;
  final List<Map<String, String>> availableClerkSubjects;
  final Function(List<String>, List<String>, List<String>, List<String>)
  onApply;

  const FilterBottomSheet({
    super.key,
    required this.role,
    required this.initialPrograms,
    required this.initialSemesters,
    required this.initialDepartments,
    required this.initialSubjectIds,
    required this.availablePrograms,
    required this.availableSemesters,
    required this.availableDepartments,
    required this.availableTeacherSubjects,
    required this.availableClerkSubjects,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  List<String> _programs = [];
  List<String> _semesters = [];
  List<String> _departments = [];
  List<String> _subjectIds = [];

  @override
  void initState() {
    super.initState();
    _programs = List.from(widget.initialPrograms);
    _semesters = List.from(widget.initialSemesters);
    _departments = List.from(widget.initialDepartments);
    _subjectIds = List.from(widget.initialSubjectIds);
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheetLayout(
      title: 'Filter Attendance',
      onReset: () {
        setState(() {
          _programs = [];
          _semesters = [];
          _departments = [];
          _subjectIds = [];
        });
        widget.onApply([], [], [], []);
        Navigator.pop(context);
      },
      onApply: () {
        widget.onApply(_programs, _semesters, _departments, _subjectIds);
        Navigator.pop(context);
      },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.role == 'teacher') ...[
            MultiSelectDropdown<String>(
              label: 'Subject',
              hint: 'Select Subject',
              items: widget.availableTeacherSubjects
                  .map((e) => e['id']!)
                  .toList(),
              selectedValues: _subjectIds,
              onChanged: (v) => setState(() => _subjectIds = v),
              displayText: (id) =>
                  widget.availableTeacherSubjects.firstWhere(
                    (e) => e['id'] == id,
                    orElse: () => {'name': id},
                  )['name'] ??
                  id,
            ),
            const SizedBox(height: 20),
          ],

          if (widget.role == 'admin' || widget.role == 'clerk') ...[
            if (widget.role == 'admin') ...[
              MultiSelectDropdown<String>(
                label: 'Department',
                hint: 'Select Department',
                items: widget.availableDepartments,
                selectedValues: _departments,
                onChanged: (v) => setState(() => _departments = v),
              ),
              const SizedBox(height: 20),
            ],

            MultiSelectDropdown<String>(
              label: 'Program',
              hint: 'Select Program',
              items: widget.availablePrograms,
              selectedValues: _programs,
              onChanged: (v) => setState(() => _programs = v),
            ),
            const SizedBox(height: 20),

            MultiSelectDropdown<String>(
              label: 'Semester',
              hint: 'Select Semester',
              items: widget.availableSemesters,
              selectedValues: _semesters,
              onChanged: (v) => setState(() => _semesters = v),
            ),
            const SizedBox(height: 20),

            if (widget.role == 'clerk') ...[
              MultiSelectDropdown<String>(
                label: 'Subject',
                hint: 'Select Subject',
                items: widget.availableClerkSubjects
                    .map((e) => e['id']!)
                    .toList(),
                selectedValues: _subjectIds,
                onChanged: (v) => setState(() => _subjectIds = v),
                displayText: (id) =>
                    widget.availableClerkSubjects.firstWhere(
                      (e) => e['id'] == id,
                      orElse: () => {'name': id},
                    )['name'] ??
                    id,
              ),
              const SizedBox(height: 20),
            ],
          ],
        ],
      ),
    );
  }
}
