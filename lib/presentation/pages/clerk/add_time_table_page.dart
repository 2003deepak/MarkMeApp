import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/repositories/clerk_repository.dart';
import 'package:markmeapp/presentation/widgets/ui/dropdown.dart';
import 'package:markmeapp/presentation/widgets/ui/snackbar.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';

class AddTimeTablePage extends ConsumerStatefulWidget {
  const AddTimeTablePage({super.key});

  @override
  ConsumerState<AddTimeTablePage> createState() => _AddTimeTableState();
}

class _AddTimeTableState extends ConsumerState<AddTimeTablePage> {
  int selectedDayIndex = 0;
  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  // Track subjects added for each day
  Map<int, List<Map<String, dynamic>>> addedSubjectsByDay = {
    0: [], // Monday
    1: [], // Tuesday
    2: [], // Wednesday
    3: [], // Thursday
    4: [], // Friday
    5: [], // Saturday
  };

  bool _isLoading = false;

  List<Map<String, dynamic>> _subjects = [];
  bool _isFetchingSubjects = true;
  String? _subjectsError;

  // Subject form fields
  Map<String, dynamic>? selectedSubject;
  String? selectedSubjectId;
  String selectedSubjectName = '';
  String selectedComponent = 'Lecture';
  String startTime = '10:10 AM';
  String endTime = '11:00 AM';

  // Color scheme for different components
  final Map<String, Color> componentColors = {
    'Lecture': const Color(0xFFEFF6FF), // Blue 50
    'Lab': const Color(0xFFFFF7ED), // Orange 50
  };

  final Map<String, Color> componentBorderColors = {
    'Lecture': const Color(0xFFBFDBFE), // Blue 200
    'Lab': const Color(0xFFFED7AA), // Orange 200
  };

  final Map<String, Color> componentTextColors = {
    'Lecture': const Color(0xFF1E40AF), // Blue 800
    'Lab': const Color(0xFF9A3412), // Orange 800
  };

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    setState(() {
      _isFetchingSubjects = true;
      _subjectsError = null;
    });

    try {
      final clerkRepo = ref.read(clerkRepositoryProvider);

      final result = await clerkRepo.fetchSubjects(
        program: 'MCA',
        semester: 2,
        mode: "subject_listing",
      );

      if (result['success'] == true) {
        final subjectsData = result['data'] as List<dynamic>;

        // List to store every subject (Lecture + Lab separately)
        final List<Map<String, dynamic>> subjectsList = [];

        for (var subject in subjectsData) {
          final subjectId = subject['subject_id']?.toString() ?? '';
          final subjectName = subject['subject_name']?.toString() ?? '';
          final component = subject['component']?.toString() ?? '';

          if (subjectId.isNotEmpty) {
            subjectsList.add({
              'id': subjectId,
              'name': '$subjectName ($component)',
              'raw': subject,
            });
          }
        }

        setState(() {
          _subjects = subjectsList;

          // Set default selected subject
          if (_subjects.isNotEmpty) {
            selectedSubject = _subjects.first;
            selectedSubjectId = _subjects.first['id'];
            selectedSubjectName = _subjects.first['name'];
            selectedComponent = _subjects.first['raw']['component'];
          }
        });
      } else {
        setState(() {
          _subjectsError = result['error'] ?? 'Failed to fetch subjects';
        });
      }
    } catch (error) {
      setState(() {
        _subjectsError = error.toString();
      });
    } finally {
      setState(() {
        _isFetchingSubjects = false;
      });
    }
  }

  // Convert 12-hour time to 24-hour format
  String _convertTo24HourFormat(String time12Hour) {
    try {
      final parts = time12Hour.split(' ');
      final timePart = parts[0];
      final period = parts[1].toUpperCase();

      final timeComponents = timePart.split(':');
      int hour = int.parse(timeComponents[0]);
      final minute = timeComponents[1];

      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return '${hour.toString().padLeft(2, '0')}:$minute';
    } catch (e) {
      return '00:00';
    }
  }

  // Parse time string to minutes since midnight
  int _timeToMinutes(String time24Hour) {
    try {
      final parts = time24Hour.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return hour * 60 + minute;
    } catch (e) {
      return 0;
    }
  }

  // Check if new time slot overlaps with existing slots
  bool _hasTimeOverlap(
    String newStartTime,
    String newEndTime,
    List<Map<String, dynamic>> existingSubjects,
  ) {
    final newStartMinutes = _timeToMinutes(newStartTime);
    final newEndMinutes = _timeToMinutes(newEndTime);

    // Validate that start time is before end time
    if (newStartMinutes >= newEndMinutes) {
      return true; // Invalid time range
    }

    for (final subject in existingSubjects) {
      final existingStartTime = subject['start_time_24'];
      final existingEndTime = subject['end_time_24'];

      final existingStartMinutes = _timeToMinutes(existingStartTime);
      final existingEndMinutes = _timeToMinutes(existingEndTime);

      // Check for overlap: new slot starts before existing ends AND new slot ends after existing starts
      if (newStartMinutes < existingEndMinutes &&
          newEndMinutes > existingStartMinutes) {
        return true;
      }
    }

    return false;
  }

  void _addSubject() {
    if (selectedSubjectId == null || selectedSubjectName.isEmpty) return;

    // Convert times to 24-hour format for validation
    final start24 = _convertTo24HourFormat(startTime);
    final end24 = _convertTo24HourFormat(endTime);

    // Check for time overlap
    if (_hasTimeOverlap(
      start24,
      end24,
      addedSubjectsByDay[selectedDayIndex]!,
    )) {
      showErrorSnackBar(
        context,
        'Time overlap detected! Please choose a different time slot.',
      );
      return;
    }

    setState(() {
      addedSubjectsByDay[selectedDayIndex]!.add({
        'subject': selectedSubjectName,
        'subject_id': selectedSubjectId!,
        'time': '$startTime - $endTime',
        'start_time_12': startTime,
        'end_time_12': endTime,
        'start_time_24': start24,
        'end_time_24': end24,
        'type': selectedComponent,
      });

      // Reset form to first subject
      if (_subjects.isNotEmpty) {
        selectedSubject = _subjects.first;
        selectedSubjectId = _subjects.first['id'];
        selectedSubjectName = _subjects.first['name'];
        selectedComponent = _subjects.first['raw']['component'];
      }

      // Reset time to default
      startTime = '10:10 AM';
      endTime = '11:00 AM';
    });
  }

  void _removeSubject(int dayIndex, int subjectIndex) {
    setState(() {
      addedSubjectsByDay[dayIndex]!.removeAt(subjectIndex);
    });
  }

  // Check if all days have at least one subject
  bool get _allDaysHaveSubjects {
    for (var daySubjects in addedSubjectsByDay.values) {
      if (daySubjects.isEmpty) {
        return false;
      }
    }
    return true;
  }

  // Check if current day has subjects
  bool get _currentDayHasSubjects {
    return addedSubjectsByDay[selectedDayIndex]!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: MarkMeAppBar(
        title: 'Edit Time Table',
        onBackPressed: _isLoading ? null : () => context.go("/clerk"),
        isLoading: _isLoading,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  children: [
                    // Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFEFF6FF), Color(0xFFF0F9FF)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE0F2FE),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x0A3B82F6),
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.calendar_month_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Time Table',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Schedule classes for MCA Semester 2',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: const Color(0xFF64748B),
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
                    const SizedBox(height: 24),

                    // Day Selector
                    SizedBox(
                      height: 48,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: days.length,
                        itemBuilder: (context, index) {
                          bool isSelected = index == selectedDayIndex;
                          final hasSubjects =
                              addedSubjectsByDay[index]!.isNotEmpty;

                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () =>
                                    setState(() => selectedDayIndex = index),
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
                                        : (hasSubjects
                                              ? const Color(0x1A2563EB)
                                              : Colors.white),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : (hasSubjects
                                                ? const Color(0xFF2563EB)
                                                : const Color(0xFFE2E8F0)),
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF2563EB,
                                              ).withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Row(
                                      children: [
                                        Text(
                                          days[index],
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : (hasSubjects
                                                      ? const Color(0xFF2563EB)
                                                      : const Color(
                                                          0xFF64748B,
                                                        )),
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (hasSubjects && !isSelected) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF2563EB),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Form Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  children: [
                    // Form Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 20,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // Loading/Error state for subjects
                          if (_isFetchingSubjects) ...[
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ] else if (_subjectsError != null) ...[
                            _buildErrorWidget(),
                          ] else ...[
                            // Subject Dropdown
                            Dropdown<Map<String, dynamic>>(
                              label: "Subject",
                              hint: "Select Subject",
                              items: _subjects,
                              value:
                                  selectedSubject ??
                                  (_subjects.isNotEmpty
                                      ? _subjects.first
                                      : null),
                              displayText: (item) => item["name"],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedSubject = value;
                                    selectedSubjectId = value['id'];
                                    selectedSubjectName = value['name'];
                                    selectedComponent =
                                        value['raw']['component'];
                                  });
                                }
                              },
                            ),

                            const SizedBox(height: 16),

                            // Time Picker Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTimeInput(
                                    label: 'Start Time',
                                    value: startTime,
                                    onTap: () => _showTimePicker(true),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTimeInput(
                                    label: 'End Time',
                                    value: endTime,
                                    onTap: () => _showTimePicker(false),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Add Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _addSubject,
                                icon: const Icon(Icons.add_rounded, size: 20),
                                label: const Text('Add to Schedule'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Added Subjects Title
                    if (_currentDayHasSubjects) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.list_alt_rounded,
                            size: 20,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Scheduled Classes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${addedSubjectsByDay[selectedDayIndex]!.length} Classes',
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // List of subjects
                      ...addedSubjectsByDay[selectedDayIndex]!
                          .asMap()
                          .entries
                          .map((entry) {
                            return _buildSubjectCard(
                              selectedDayIndex,
                              entry.value,
                              entry.key,
                            );
                          }),
                    ] else ...[
                      // Empty State
                      Container(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 48,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No classes scheduled for ${days[selectedDayIndex]}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Final Save Button
                    if (_allDaysHaveSubjects)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveSchedule,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              elevation: 4,
                              shadowColor: const Color(
                                0xFF0F172A,
                              ).withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Save Complete Schedule',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInput({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF8FAFC),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(
                  Icons.access_time_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _subjectsError ?? "Error occurred",
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: OutlinedButton(
              onPressed: _fetchSubjects,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                foregroundColor: const Color(0xFFB91C1C),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(
    int dayIndex,
    Map<String, dynamic> subject,
    int index,
  ) {
    final type = subject['type'] ?? 'Lecture';
    final backgroundColor =
        componentColors[type] ?? componentColors['Lecture']!;
    final borderColor =
        componentBorderColors[type] ?? componentBorderColors['Lecture']!;
    final textColor =
        componentTextColors[type] ?? componentTextColors['Lecture']!;
    // Extract everything for display
    String displayName = subject['subject'].toString();
    // Clean up display name if it already has (Lecture) or (Lab) at end to avoid double display in card if needed
    // But logic puts it in 'subject' key so we use it as is.

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: borderColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: borderColor.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            subject['time'].toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _removeSubject(dayIndex, index),
                icon: const Icon(Icons.delete_outline_rounded),
                color: const Color(0xFF94A3B8),
                hoverColor: const Color(0xFFFEE2E2),
                splashRadius: 20,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTimePicker(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final period = picked.hour >= 12 ? 'PM' : 'AM';
      final hour = picked.hour > 12
          ? picked.hour - 12
          : picked.hour == 0
          ? 12
          : picked.hour;
      final minute = picked.minute.toString().padLeft(2, '0');
      final timeString = '$hour:$minute $period';

      setState(() {
        if (isStartTime) {
          startTime = timeString;
        } else {
          endTime = timeString;
        }
      });
    }
  }

  Future<void> _saveSchedule() async {
    try {
      // Prepare schedule
      final Map<String, List<Map<String, dynamic>>> scheduleData = {};

      for (int i = 0; i < days.length; i++) {
        final dayName = days[i];
        final daySubjects = addedSubjectsByDay[i]!;

        scheduleData[dayName] = daySubjects.map((subject) {
          return {
            'start_time': subject['start_time_24'],
            'end_time': subject['end_time_24'],
            'subject': subject['subject_id'],
          };
        }).toList();
      }

      final requestBody = {
        'academic_year': '2025',
        'program': 'MCA',
        'semester': '2',
        'schedule': scheduleData,
      };

      final clerkRepo = ref.read(clerkRepositoryProvider);

      setState(() {
        _isLoading = true;
      });

      final result = await clerkRepo.createTimeTable(requestBody);

      if (!mounted) return;

      if (result['success'] == true) {
        showSuccessSnackBar(
          context,
          result["message"] ?? "Time table created successfully!",
        );
        context.go('/clerk');
      } else {
        showErrorSnackBar(
          context,
          result['error'] ?? 'Failed to save timetable',
        );
      }
    } catch (error) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
