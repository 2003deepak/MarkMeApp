import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/repositories/clerk_repository.dart';
import 'package:markmeapp/presentation/widgets/ui/dropdown.dart';
import 'package:markmeapp/presentation/widgets/ui/snackbar.dart';

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
    'Lecture': const Color(0xFFE8F0FF),
    'Lab': const Color(0xFFFFF4E6),
  };

  final Map<String, Color> componentBorderColors = {
    'Lecture': const Color(0xFF1E3A8A), // Dark Blue
    'Lab': const Color(0xFFE67C00), // Dark Orange
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

      final result = await clerkRepo.fetchSubjects(program: 'MCA', semester: 2);

      if (result['success'] == true) {
        final subjectsData = result['data']['subjects'] as List<dynamic>;

        // List to store every subject (Lecture + Lab separately)
        final List<Map<String, dynamic>> subjectsList = [];

        for (var subject in subjectsData) {
          final subjectId = subject['subject_id']?.toString() ?? '';
          final subjectName = subject['subject_name']?.toString() ?? '';
          final component = subject['component']?.toString() ?? '';

          if (subjectId.isNotEmpty) {
            subjectsList.add({
              'id': subjectId,
              'name': '$subjectName ($component)', // Show component in UI
              'raw': subject, // Store raw subject if needed later
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
        selectedSubjectId = _subjects.first['id'];
        selectedSubjectName = _subjects.first['name'];
      } else {
        selectedSubjectId = null;
        selectedSubjectName = '';
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

  // Get color for day selector based on whether it has subjects
  Color _getDaySelectorColor(int index) {
    final hasSubjects = addedSubjectsByDay[index]!.isNotEmpty;

    if (index == selectedDayIndex) {
      // Selected day
      return const Color(0xFFE8F0FF); // Light blue when selected
    } else if (!hasSubjects) {
      // Day without subjects (not selected)
      return const Color(0xFFFFE6E6); // Light red
    } else {
      // Day with subjects (not selected)
      return Colors.transparent;
    }
  }

  // Get text color for day selector
  Color _getDayTextColor(int index) {
    final hasSubjects = addedSubjectsByDay[index]!.isNotEmpty;

    if (index == selectedDayIndex) {
      return const Color(0xFF1E3A8A); // Dark blue for selected
    } else if (!hasSubjects) {
      return const Color(0xFFDC2626); // Red for days without subjects
    } else {
      return const Color(0xFFCCCCCC); // Gray for days with subjects
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Color(0xFF475569),
            ),
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Add Time Table',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(
                top: 24.0,
                bottom: 8.0,
                left: 16.0,
                right: 16.0,
              ),
            ),

            const SizedBox(height: 16),

            // Day Selector
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  bool isSelected = index == selectedDayIndex;
                  // final hasSubjects = addedSubjectsByDay[index]!.isNotEmpty;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDayIndex = index;
                      });
                    },
                    child: Container(
                      width: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: _getDaySelectorColor(index),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1E3A8A)
                              : Colors.transparent,
                          width: isSelected ? 1 : 0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            days[index].substring(0, 3),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getDayTextColor(index),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form Title
                    const Text(
                      'Schedule Lecture',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Loading/Error state for subjects
                    if (_isFetchingSubjects) ...[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(
                            color: Color(0xFF3B5BDB),
                          ),
                        ),
                      ),
                    ] else if (_subjectsError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[100]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _subjectsError!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            IconButton(
                              onPressed: _fetchSubjects,
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Subject Dropdown
                    Dropdown<Map<String, dynamic>>(
                      label: "Subject",
                      hint: "Select Subject",
                      items: _subjects,
                      value:
                          selectedSubject ??
                          (_subjects.isNotEmpty ? _subjects.first : null),
                      displayText: (item) => item["name"],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedSubject = value;
                            selectedSubjectId = value['id'];
                            selectedSubjectName = value['name'];

                            selectedComponent =
                                value['raw']['component']; // 'Lecture' or 'Lab'
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Time Picker Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'Start Time',
                            child: GestureDetector(
                              onTap: () => _showTimePicker(true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      startTime,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    Icon(
                                      Icons.access_time,
                                      size: 20,
                                      color: Colors.grey[500],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFormField(
                            label: 'End Time',
                            child: GestureDetector(
                              onTap: () => _showTimePicker(false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      endTime,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    Icon(
                                      Icons.access_time,
                                      size: 20,
                                      color: Colors.grey[500],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Add More Subjects Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF3B5BDB),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _addSubject,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  color: Color(0xFF3B5BDB),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Add More Subjects',
                                  style: TextStyle(
                                    color: Color(0xFF3B5BDB),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Added Subjects List for current day
                    if (_currentDayHasSubjects) ...[
                      Text(
                        'Added Subjects (${days[selectedDayIndex]})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...addedSubjectsByDay[selectedDayIndex]!
                          .asMap()
                          .entries
                          .map((entry) {
                            final index = entry.key;
                            final subject = entry.value;
                            return _buildSubjectCard(
                              selectedDayIndex,
                              subject,
                              index,
                            );
                          }),
                    ] else ...[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No subjects added for ${days[selectedDayIndex]}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Save Button - Disabled if not all days have subjects
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _allDaysHaveSubjects
                            ? () {
                                _saveSchedule();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _allDaysHaveSubjects
                              ? const Color(0xFF3B5BDB)
                              : Colors.grey[300],
                          foregroundColor: _allDaysHaveSubjects
                              ? Colors.white
                              : Colors.grey[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save Schedule',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
        ],
        child,
      ],
    );
  }

  Widget _buildSubjectCard(
    int dayIndex,
    Map<String, dynamic> subject,
    int index,
  ) {
    final isLab = subject['type'] == 'Lab';
    final backgroundColor = isLab
        ? componentColors['Lab']!
        : componentColors['Lecture']!;
    final borderColor = isLab
        ? componentBorderColors['Lab']!
        : componentBorderColors['Lecture']!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withAlpha(77)), // 0.3
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
              margin: const EdgeInsets.only(right: 12),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject['subject'].toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subject['type'].toString(),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subject['time'].toString(),
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _removeSubject(dayIndex, index),
              icon: Icon(
                Icons.delete_outline,
                color: Colors.grey[500],
                size: 20,
              ),
            ),
          ],
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
            colorScheme: const ColorScheme.light(primary: Color(0xFF3B5BDB)),
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
      final result = await clerkRepo.createTimeTable(requestBody);

      if (!mounted) return;

      if (result['success'] == true) {
        showSuccessSnackBar(context, result["message"]);
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
    }
  }
}
