import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/repositories/clerk_repository.dart';

class AddTimeTablePage extends ConsumerStatefulWidget {
  const AddTimeTablePage({Key? key}) : super(key: key);

  @override
  ConsumerState<AddTimeTablePage> createState() => _AddTimeTableState();
}

class _AddTimeTableState extends ConsumerState<AddTimeTablePage> {
  int selectedDayIndex = 0;
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  // Track subjects added for each day
  Map<int, List<Map<String, String>>> addedSubjectsByDay = {
    0: [], // Mon
    1: [], // Tue
    2: [], // Wed
    3: [], // Thu
    4: [], // Fri
    5: [], // Sat
  };

  List<Map<String, dynamic>> _subjects = [];
  bool _isFetchingSubjects = true;
  String? _subjectsError;

  // Subject form fields
  String? selectedSubjectId;
  String selectedSubjectName = '';
  String startTime = '10:10 AM';
  String endTime = '11:00 AM';
  String selectedClass = 'SY';
  String selectedType = 'Lab';

  // Color scheme for different components
  final Map<String, Color> componentColors = {
    'Lecture': const Color(0xFFE8F0FF), // Light Blue
    'Lab': const Color(0xFFFFF4E6), // Light Orange
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
      final result = await clerkRepo.fetchSubjects();

      if (result['success'] == true) {
        final subjectsData = result['data']['subjects'] as List<dynamic>;

        // Extract unique subjects by subject_code to avoid duplicates
        final uniqueSubjects = <String, Map<String, dynamic>>{};

        for (var subject in subjectsData) {
          final subjectCode = subject['subject_code'];
          final subjectName = subject['subject_name'];

          if (!uniqueSubjects.containsKey(subjectCode)) {
            uniqueSubjects[subjectCode] = {
              'id': subjectCode,
              'name': subjectName,
            };
          }
        }

        setState(() {
          _subjects = uniqueSubjects.values.toList();
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

  void _handleBackPressed() {
    context.pop();
  }

  void _addSubject() {
    if (selectedSubjectId == null || selectedSubjectName.isEmpty) return;

    setState(() {
      addedSubjectsByDay[selectedDayIndex]!.add({
        'subject': selectedSubjectName,
        'subject_id': selectedSubjectId!,
        'time': '$startTime - $endTime',
        'class': selectedClass,
        'type': selectedType,
      });

      // Reset form
      selectedSubjectId = null;
      selectedSubjectName = '';
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
                  final hasSubjects = addedSubjectsByDay[index]!.isNotEmpty;

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
                            days[index],
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
                    _buildFormField(
                      label: 'Subject',
                      child: DropdownButtonFormField<String>(
                        value: selectedSubjectId,
                        decoration: InputDecoration(
                          hintText: 'Select Subject',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF3B5BDB),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _subjects.map((subject) {
                          final subjectId = subject['id'] as String;
                          final subjectName = subject['name'] as String;
                          return DropdownMenuItem<String>(
                            value: subjectId,
                            child: Text(
                              subjectName,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            final selectedSubject = _subjects.firstWhere(
                              (subject) => subject['id'] == value,
                            );
                            setState(() {
                              selectedSubjectId = value;
                              selectedSubjectName =
                                  selectedSubject['name'] as String;
                            });
                          } else {
                            setState(() {
                              selectedSubjectId = null;
                              selectedSubjectName = '';
                            });
                          }
                        },
                      ),
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
                        const Text(
                          'to',
                          style: TextStyle(
                            color: Color.fromARGB(255, 119, 119, 119),
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

                    // Class and Type Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'Class',
                            child: DropdownButtonFormField<String>(
                              value: selectedClass,
                              decoration: InputDecoration(
                                hintText: 'Select',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF3B5BDB),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: ['SY', 'TY', 'FY'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedClass = value ?? 'SY';
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            label: 'Type',
                            child: DropdownButtonFormField<String>(
                              value: selectedType,
                              decoration: InputDecoration(
                                hintText: 'Select',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF3B5BDB),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: ['Lecture', 'Lab'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedType = value ?? 'Lab';
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Add More Subjects Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Color(0xFF3B5BDB),
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
                          })
                          .toList(),
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
                              ? Color(0xFF3B5BDB)
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
    Map<String, String> subject,
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
        border: Border.all(color: borderColor.withOpacity(0.3)),
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
                    subject['subject']!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${subject['class']!} | ${subject['type']!}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subject['time']!,
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
      final hour = picked.hour > 12 ? picked.hour - 12 : picked.hour;
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Schedule saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate back after saving
    Future.delayed(Duration(seconds: 1), () {
      context.pop();
    });
  }
}
