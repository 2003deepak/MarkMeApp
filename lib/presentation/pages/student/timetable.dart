import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/data/repositories/student_repository.dart';

class TimeTablePage extends ConsumerStatefulWidget {
  const TimeTablePage({super.key});

  @override
  ConsumerState<TimeTablePage> createState() => _TimeTableState();
}

class _TimeTableState extends ConsumerState<TimeTablePage>
    with SingleTickerProviderStateMixin {
  int selectedDayIndex = 0; // Monday as default
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  // API data state
  Map<String, dynamic>? timetableData;
  bool isLoading = true;
  String errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  // Timeline configuration
  static const double pixelsPerHour = 100.0;
  static const int startHour = 8; // 8 AM
  static const int totalHours = 10; // 8 AM to 6 PM (inclusive)
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
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fetchTimetable();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchTimetable() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Get repository using Riverpod
      final studentRepo = ref.read(studentRepositoryProvider);

      // Replace these with actual values from your app state/context
      final result = await studentRepo.fetchTimeTable(
        program: 'MCA', // Get from your app state
        dept: 'BTECH', // Get from your app state
        sem: '2', // Get from your app state
        batch: '2025', // Get from your app state
      );

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

    final schedule = timetableData!['schedule'] as List<dynamic>?;
    if (schedule == null || schedule.isEmpty) return [];

    // Find the schedule for selected day
    final selectedDaySchedule = schedule
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (daySchedule) => _getDayIndex(daySchedule['day']) == selectedDayIndex,
          orElse: () => <String, dynamic>{},
        );

    if (selectedDaySchedule.isEmpty) return [];

    final sessions = selectedDaySchedule['sessions'] as List<dynamic>?;
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
        instructor: sessionMap['teacher_name'] ?? 'No Instructor',
        component: sessionMap['component'] ?? 'Lecture', // Default to Lecture
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
                        if (timetableData != null)
                          Text(
                            '${timetableData!['program']} - Semester ${timetableData!['semester']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
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
                        const SizedBox(
                          height: 10,
                        ), // gap between Lecture and Lab
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
      return _buildLoadingSkeleton();
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
            color: color.withValues(alpha: 0.4),
            blurRadius: 3,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  // New method to build event widgets with proper spacing
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
        margin: const EdgeInsets.only(bottom: 8.0), // Additional bottom margin
        decoration: BoxDecoration(
          color: componentColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: height - 24, // account for padding
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
              margin: const EdgeInsets.only(right: 12),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        event.instructor,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF999999),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${event.startTime} - ${event.endTime}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Skeleton Loading Widget
  Widget _buildLoadingSkeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final timelineHeight = totalHours * pixelsPerHour;
        final eventAreaWidth = constraints.maxWidth - 80 - 16;

        return FadeTransition(
          opacity: _opacityAnimation,
          child: SingleChildScrollView(
            physics:
                const NeverScrollableScrollPhysics(), // Disable scrolling during load
            child: SizedBox(
              height: timelineHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Skeleton Time Labels
                  SizedBox(
                    width: 80,
                    child: Column(
                      children: List.generate(totalHours, (i) {
                        return SizedBox(
                          height: pixelsPerHour,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              left: 16.0,
                            ),
                            child: Container(
                              width: 40,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Skeleton Event Area
                  SizedBox(
                    width: eventAreaWidth,
                    height: timelineHeight,
                    child: Stack(
                      children: [
                        // Horizontal Lines
                        ...List.generate(totalHours, (i) {
                          return Positioned(
                            top: i * pixelsPerHour,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 1,
                              color: Colors.grey.shade200,
                            ),
                          );
                        }),

                        // Fake Events
                        _buildSkeletonEvent(
                          top: 100,
                          height: 120,
                          color: Colors.blue.shade50,
                        ),
                        _buildSkeletonEvent(
                          top: 350,
                          height: 90,
                          color: Colors.orange.shade50,
                        ),
                        _buildSkeletonEvent(
                          top: 500,
                          height: 180,
                          color: Colors.blue.shade50,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonEvent({
    required double top,
    required double height,
    required Color color,
  }) {
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: height - 24,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EventData {
  final String title;
  final String instructor;
  final String component;
  final String startTime;
  final String endTime;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const EventData({
    required this.title,
    required this.instructor,
    required this.component,
    required this.startTime,
    required this.endTime,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });
}
