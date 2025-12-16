import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/data/repositories/teacher_repository.dart';

class TimeTablePage extends ConsumerStatefulWidget {
  const TimeTablePage({super.key});

  @override
  ConsumerState<TimeTablePage> createState() => _TimeTableState();
}

class _TimeTableState extends ConsumerState<TimeTablePage> {
  int selectedDayIndex = 0; // Monday as default
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  // API data state
  Map<String, dynamic>? timetableData;
  bool isLoading = true;
  String errorMessage = '';

  // Timeline configuration
  static const double pixelsPerHour = 100.0;
  static const int startHour = 8; // 8 AM
  static const int totalHours = 12; // 8 AM to 6 PM (inclusive)
  static const double eventSpacing = 8.0; // Gap between events

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
    _fetchTimetable();
  }

  Future<void> _fetchTimetable() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Get repository using Riverpod
      final teacherRepo = ref.read(teacherRepositoryProvider);

      final result = await teacherRepo.fetchTimeTable();

      if (result['success'] == true) {
        setState(() {
          timetableData = result['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['error'] ?? 'Failed to load timetable';
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

  // Convert API day name to index (0=Monday, 1=Tuesday, etc.)
  /*
  int _getDayIndex(String dayName) {
    switch (dayName.toLowerCase()) {
      case 'monday':
        return 0;
      case 'tuesday':
        return 1;
      case 'wednesday':
        return 2;
      case 'thursday':
        return 3;
      case 'friday':
        return 4;
      case 'saturday':
        return 5;
      case 'sunday':
        return 6;
      default:
        return 0;
    }
  }
  */

  // Get the full day name from index
  String _getFullDayName(int index) {
    switch (index) {
      case 0:
        return 'Monday';
      case 1:
        return 'Tuesday';
      case 2:
        return 'Wednesday';
      case 3:
        return 'Thursday';
      case 4:
        return 'Friday';
      case 5:
        return 'Saturday';
      case 6:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  // Parse time string "HH:MM" to DateTime components
  Map<String, int> _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return {'hour': hour, 'minute': minute};
    } catch (e) {
      return {'hour': 0, 'minute': 0};
    }
  }

  // Format time for display (convert 24h to 12h format)
  String _formatTimeForDisplay(String timeStr) {
    try {
      final time = _parseTime(timeStr);
      final hour = time['hour']!;
      final minute = time['minute']!;

      final period = hour >= 12 ? 'pm' : 'am';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final minuteStr = minute.toString().padLeft(2, '0');

      return '$displayHour:$minuteStr $period';
    } catch (e) {
      return timeStr;
    }
  }

  // Get events for selected day from API data
  List<EventData> _getEventsForSelectedDay() {
    if (timetableData == null) return [];

    final selectedDayName = _getFullDayName(selectedDayIndex);

    // Check if the selected day exists in the timetable data
    if (!timetableData!.containsKey(selectedDayName)) {
      return [];
    }

    final sessions = timetableData![selectedDayName] as List<dynamic>?;
    if (sessions == null || sessions.isEmpty) return [];

    // Convert API sessions to EventData objects
    return sessions.map((session) {
      final sessionMap = session as Map<String, dynamic>;
      final startTime = sessionMap['start_time'] as String;
      final endTime = sessionMap['end_time'] as String;
      final startTimeMap = _parseTime(startTime);
      final endTimeMap = _parseTime(endTime);

      return EventData(
        title: sessionMap['subject_name'] ?? 'No Subject',
        component: sessionMap['component'] ?? 'Lecture',
        program: sessionMap['program'] ?? 'N/A',
        semester: sessionMap['semester']?.toString() ?? 'N/A',
        startTime: _formatTimeForDisplay(startTime),
        endTime: _formatTimeForDisplay(endTime),
        startHour: startTimeMap['hour']!,
        startMinute: startTimeMap['minute']!,
        endHour: endTimeMap['hour']!,
        endMinute: endTimeMap['minute']!,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
              child: Stack(
                children: [
                  // Centered title and program info
                  Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        const Text(
                          'Time Table',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),

                  // Legend column on right side
                  Align(
                    alignment: Alignment.topRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLegendDot(
                              const Color(0xFF1E3A8A),
                            ), // Lecture dot
                            const SizedBox(width: 6),
                            const Text(
                              "Lecture",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLegendDot(const Color(0xFFE67C00)), // Lab dot
                            const SizedBox(width: 6),
                            const Text(
                              "Lab",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Error message
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
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
                          errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Day Selector
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  bool isSelected = index == selectedDayIndex;

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
                        color: isSelected
                            ? const Color(0xFFE8F0FF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            days[index],
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? const Color(0xFF1E3A8A)
                                  : const Color(0xFFCCCCCC),
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

            const SizedBox(height: 16),

            // Main content - Show loading, error, or timetable
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
      );
    }

    if (errorMessage.isNotEmpty && timetableData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Failed to load timetable',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _fetchTimetable,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    final events = _getEventsForSelectedDay();

    return LayoutBuilder(
      builder: (context, constraints) {
        final timelineHeight = totalHours * pixelsPerHour;
        final eventAreaWidth = constraints.maxWidth - 80 - 16;

        return Stack(
          children: [
            // Vertical scrollable content (time labels + events)
            SingleChildScrollView(
              child: SizedBox(
                height: timelineHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fixed time labels (8 AM to 6 PM)
                    SizedBox(
                      width: 80,
                      child: Column(
                        children: List.generate(totalHours, (i) {
                          final hour = startHour + i;
                          String timeLabel;
                          if (hour == 12) {
                            timeLabel = '12:00 pm';
                          } else if (hour > 12) {
                            timeLabel = '${hour - 12}:00 pm';
                          } else {
                            timeLabel = '${hour == 0 ? 12 : hour}:00 am';
                          }
                          return SizedBox(
                            height: pixelsPerHour,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                timeLabel,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFCCCCCC),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Event area
                    SizedBox(
                      width: eventAreaWidth,
                      height: timelineHeight,
                      child: Stack(
                        children: [
                          // Horizontal separator lines
                          ...List.generate(totalHours, (i) {
                            return Positioned(
                              top: i * pixelsPerHour,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 1,
                                color: const Color(0xFFE8E8E8),
                              ),
                            );
                          }),

                          // No classes message
                          if (events.isEmpty)
                            const Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Center(
                                child: Text(
                                  'No classes scheduled',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),

                          // Actual events with proper spacing
                          ..._buildEventWidgets(events),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(102), // 0.4
            blurRadius: 3,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEventWidgets(List<EventData> events) {
    final List<Widget> eventWidgets = [];

    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      final startPixel =
          (event.startHour - startHour + event.startMinute / 60.0) *
          pixelsPerHour;
      final endPixel =
          (event.endHour - startHour + event.endMinute / 60.0) * pixelsPerHour;
      final height = endPixel - startPixel;

      // Calculate top position with spacing
      double topPosition = startPixel;

      // Add spacing between consecutive events
      if (i > 0) {
        final previousEvent = events[i - 1];
        final previousEndPixel =
            (previousEvent.endHour -
                startHour +
                previousEvent.endMinute / 60.0) *
            pixelsPerHour;

        // If current event starts immediately after previous event, add spacing
        if (startPixel <= previousEndPixel + eventSpacing) {
          // Adjust top position to create gap
          topPosition = previousEndPixel + eventSpacing;

          // Recalculate height to maintain correct duration
          final newHeight = endPixel - topPosition;

          // Ensure minimum height for readability
          final displayHeight = newHeight < 40 ? 40.0 : newHeight;

          eventWidgets.add(
            _buildEventWidget(
              event: event,
              top: topPosition,
              height: displayHeight,
            ),
          );
          continue;
        }
      }

      // Minimum height for readability
      final displayHeight = height < 40 ? 40.0 : height.toDouble();

      eventWidgets.add(
        _buildEventWidget(
          event: event,
          top: topPosition,
          height: displayHeight,
        ),
      );
    }

    return eventWidgets;
  }

  // Helper method to build individual event widget
  Widget _buildEventWidget({
    required EventData event,
    required double top,
    required double height,
  }) {
    final componentColor =
        componentColors[event.component] ?? const Color(0xFFE8F0FF);
    final borderColor =
        componentBorderColors[event.component] ?? const Color(0xFF1E3A8A);

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 8.0),
        decoration: BoxDecoration(
          color: componentColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13), // 0.05
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: height - 24, // Adjusted height for padding
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.only(right: 12),
              ),
              Expanded(child: _buildEventContent(event, height)),
            ],
          ),
        ),
      ),
    );
  }

  // FIXED: Separate method to build event content with proper constraints
  Widget _buildEventContent(EventData event, double containerHeight) {
    // Calculate available height for content (subtract padding)
    final availableHeight =
        containerHeight - 24; // 12px top + 12px bottom padding

    // Determine content layout based on available height
    if (availableHeight < 50) {
      // Very small height - show only subject name
      return Center(
        child: Text(
          event.title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      );
    } else if (availableHeight < 70) {
      // Medium height - show subject name and time
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${event.startTime} - ${event.endTime}',
            style: const TextStyle(fontSize: 10, color: Color(0xFF999999)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    } else {
      // Full height - show all information
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            maxLines: availableHeight < 90 ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (availableHeight >= 90) ...[
            const SizedBox(height: 4),
            Text(
              '${event.program} - Sem ${event.semester}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 2),
          Text(
            '${event.startTime} - ${event.endTime}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }
  }
}

class EventData {
  final String title;
  final String component;
  final String program;
  final String semester;
  final String startTime;
  final String endTime;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const EventData({
    required this.title,
    required this.component,
    required this.program,
    required this.semester,
    required this.startTime,
    required this.endTime,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });
}
