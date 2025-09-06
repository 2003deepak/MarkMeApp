import 'package:flutter/material.dart';
import '../../data/models/schedule_model.dart';

/// Individual schedule card widget that displays class information
/// This widget handles the visual representation of different class types
/// and user interactions (attendance marking, class details)
/// 
/// Backend developers: The visual styling is based on the class type and status
/// fields in your API response. Ensure you're sending the correct values:
/// - 'lecture' -> Blue book icon
/// - 'practical' -> Green computer icon  
/// - 'tutorial' -> Orange help icon
/// - 'exam' -> Red assignment icon
/// - 'assignment' -> Purple task icon
/// 
/// Status values affect the card appearance:
/// - 'scheduled' -> Normal appearance
/// - 'ongoing' -> Highlighted with pulse animation
/// - 'completed' -> Muted colors
/// - 'cancelled' -> Red accent with strikethrough
/// - 'rescheduled' -> Orange accent with info icon
class ScheduleCard extends StatelessWidget {
  /// The schedule data to display
  final ScheduleModel schedule;
  
  /// Callback when user taps the attendance button
  /// This should trigger attendance marking via backend API
  final VoidCallback? onAttendanceTap;
  
  /// Callback when user taps the card for details
  final VoidCallback? onTap;
  
  /// Whether to show the date in the card
  final bool showDate;
  
  /// Whether to show a subtle animation when the card appears
  final bool animate;

  const ScheduleCard({
    Key? key,
    required this.schedule,
    this.onAttendanceTap,
    this.onTap,
    this.showDate = true,
    this.animate = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getBorderColor(),
                width: 1,
              ),
              // Add subtle shadow for ongoing classes
              boxShadow: schedule.isOngoing
                  ? [
                      BoxShadow(
                        color: _getAccentColor().withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with class type icon, subject, and status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Class type icon
                    _buildClassTypeIcon(),
                    
                    const SizedBox(width: 12),
                    
                    // Subject and details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subject name and code
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  schedule.subjectName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _getTextColor(),
                                    decoration: schedule.status == ScheduleStatus.cancelled
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              
                              // Subject code
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getAccentColor().withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  schedule.subjectCode,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getAccentColor(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // Instructor name
                          Text(
                            schedule.instructorName,
                            style: TextStyle(
                              fontSize: 14,
                              color: _getSecondaryTextColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Status indicator
                    _buildStatusIndicator(),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Time and location row
                Row(
                  children: [
                    // Time information
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: _getSecondaryTextColor(),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            schedule.formattedTimeRange,
                            style: TextStyle(
                              fontSize: 14,
                              color: _getSecondaryTextColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          
                          // Duration
                          const SizedBox(width: 8),
                          Text(
                            '(${schedule.durationMinutes}min)',
                            style: TextStyle(
                              fontSize: 12,
                              color: _getSecondaryTextColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Location information
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: _getSecondaryTextColor(),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _getLocationText(),
                        style: TextStyle(
                          fontSize: 14,
                          color: _getSecondaryTextColor(),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                // Show date if requested
                if (showDate) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: _getSecondaryTextColor(),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        schedule.formattedDate,
                        style: TextStyle(
                          fontSize: 14,
                          color: _getSecondaryTextColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Show description if available
                if (schedule.description != null && schedule.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    schedule.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: _getSecondaryTextColor(),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                // Show metadata if available (for backend developers)
                if (schedule.metadata != null && schedule.metadata!.isNotEmpty)
                  _buildMetadataSection(),
                
                // Action buttons row
                if (_shouldShowActionButtons()) ...[
                  const SizedBox(height: 12),
                  _buildActionButtons(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the class type icon based on the type from backend
  /// Backend developers: Ensure your API returns the correct type values
  Widget _buildClassTypeIcon() {
    IconData iconData;
    Color iconColor;
    Color backgroundColor;

    switch (schedule.classType) {
      case ClassType.lecture:
        // Book icon for lectures
        iconData = Icons.menu_book_outlined;
        iconColor = Colors.blue.shade600;
        backgroundColor = Colors.blue.shade50;
        break;
        
      case ClassType.practical:
        // Computer icon for practicals
        iconData = Icons.computer_outlined;
        iconColor = Colors.green.shade600;
        backgroundColor = Colors.green.shade50;
        break;
        
      case ClassType.tutorial:
        // Help icon for tutorials
        iconData = Icons.help_outline;
        iconColor = Colors.orange.shade600;
        backgroundColor = Colors.orange.shade50;
        break;
        
      case ClassType.exam:
        // Assignment icon for exams
        iconData = Icons.assignment_outlined;
        iconColor = Colors.red.shade600;
        backgroundColor = Colors.red.shade50;
        break;
        
      case ClassType.assignment:
        // Task icon for assignments
        iconData = Icons.task_outlined;
        iconColor = Colors.purple.shade600;
        backgroundColor = Colors.purple.shade50;
        break;
    }

    // Adjust colors based on status
    if (schedule.status == ScheduleStatus.completed) {
      iconColor = iconColor.withOpacity(0.6);
      backgroundColor = backgroundColor.withOpacity(0.5);
    } else if (schedule.status == ScheduleStatus.cancelled) {
      iconColor = Colors.red.shade600;
      backgroundColor = Colors.red.shade50;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  /// Builds status indicator based on schedule status
  Widget _buildStatusIndicator() {
    Widget? indicator;
    
    switch (schedule.status) {
      case ScheduleStatus.ongoing:
        indicator = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
        break;
        
      case ScheduleStatus.cancelled:
        indicator = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.shade600,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'CANCELLED',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        );
        break;
        
      case ScheduleStatus.rescheduled:
        indicator = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade600,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'RESCHEDULED',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        );
        break;
        
      case ScheduleStatus.completed:
        if (schedule.attendanceMarked) {
          indicator = Icon(
            Icons.check_circle,
            color: Colors.green.shade600,
            size: 20,
          );
        }
        break;
        
      case ScheduleStatus.scheduled:
        if (schedule.isUpcoming) {
          indicator = Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'UPCOMING',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          );
        }
        break;
    }
    
    return indicator ?? const SizedBox.shrink();
  }

  /// Builds metadata section for additional class information
  /// Backend developers: This displays any additional data you send in the metadata field
  /// Common metadata examples:
  /// - semester, academic_year, credits
  /// - assignment_due_date, exam_type, practical_requirements
  Widget _buildMetadataSection() {
    final metadata = schedule.metadata!;
    
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          // Show semester if available
          if (metadata['semester'] != null)
            _buildMetadataChip(
              label: metadata['semester'].toString(),
              icon: Icons.school,
            ),
          
          // Show credits if available
          if (metadata['credits'] != null)
            _buildMetadataChip(
              label: '${metadata['credits']} credits',
              icon: Icons.star_outline,
            ),
          
          // Show attendance percentage if available
          if (schedule.attendancePercentage != null)
            _buildMetadataChip(
              label: '${schedule.attendancePercentage!.toStringAsFixed(1)}%',
              icon: Icons.percent,
              color: _getAttendanceColor(schedule.attendancePercentage!),
            ),
        ],
      ),
    );
  }

  /// Builds a small chip for metadata display
  Widget _buildMetadataChip({
    required String label,
    required IconData icon,
    Color? color,
  }) {
    final chipColor = color ?? Colors.grey.shade600;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chipColor.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: chipColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds action buttons for attendance marking
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Attendance button
        if (_canMarkAttendance()) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAttendanceTap,
              icon: const Icon(Icons.how_to_reg, size: 18),
              label: const Text('Mark Attendance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getAccentColor(),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ] else if (schedule.attendanceMarked) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Attendance Marked',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Gets background color based on schedule status
  Color _getBackgroundColor() {
    switch (schedule.status) {
      case ScheduleStatus.ongoing:
        return _getAccentColor().withOpacity(0.05);
      case ScheduleStatus.completed:
        return Colors.grey.shade50;
      case ScheduleStatus.cancelled:
        return Colors.red.shade25;
      case ScheduleStatus.rescheduled:
        return Colors.orange.shade25;
      case ScheduleStatus.scheduled:
      default:
        return Colors.white;
    }
  }

  /// Gets border color based on schedule status
  Color _getBorderColor() {
    switch (schedule.status) {
      case ScheduleStatus.ongoing:
        return _getAccentColor().withOpacity(0.3);
      case ScheduleStatus.completed:
        return Colors.grey.shade200;
      case ScheduleStatus.cancelled:
        return Colors.red.shade200;
      case ScheduleStatus.rescheduled:
        return Colors.orange.shade200;
      case ScheduleStatus.scheduled:
      default:
        return Colors.grey.shade200;
    }
  }

  /// Gets accent color based on class type
  Color _getAccentColor() {
    switch (schedule.classType) {
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

  /// Gets text color based on schedule status
  Color _getTextColor() {
    switch (schedule.status) {
      case ScheduleStatus.completed:
        return Colors.grey.shade600;
      case ScheduleStatus.cancelled:
        return Colors.red.shade700;
      default:
        return Colors.black87;
    }
  }

  /// Gets secondary text color based on schedule status
  Color _getSecondaryTextColor() {
    switch (schedule.status) {
      case ScheduleStatus.completed:
        return Colors.grey.shade500;
      case ScheduleStatus.cancelled:
        return Colors.red.shade500;
      default:
        return Colors.grey.shade600;
    }
  }

  /// Gets location text combining room and building
  String _getLocationText() {
    if (schedule.building != null && schedule.building!.isNotEmpty) {
      return '${schedule.roomNumber}, ${schedule.building}';
    }
    return schedule.roomNumber;
  }

  /// Gets color for attendance percentage display
  /// Backend developers: This provides visual feedback for attendance data
  Color _getAttendanceColor(double percentage) {
    if (percentage >= 75) {
      return Colors.green.shade600; // Good attendance
    } else if (percentage >= 50) {
      return Colors.orange.shade600; // Warning attendance
    } else {
      return Colors.red.shade600; // Critical attendance
    }
  }

  /// Determines if action buttons should be shown
  bool _shouldShowActionButtons() {
    return schedule.status == ScheduleStatus.scheduled ||
           schedule.status == ScheduleStatus.ongoing ||
           (schedule.status == ScheduleStatus.completed && schedule.attendanceMarked);
  }

  /// Determines if attendance can be marked
  bool _canMarkAttendance() {
    if (schedule.attendanceMarked) return false;
    if (schedule.status == ScheduleStatus.cancelled) return false;
    if (schedule.status == ScheduleStatus.completed) return false;
    
    // Can mark attendance if class is ongoing or recently ended (within 30 minutes)
    final now = DateTime.now();
    final thirtyMinutesAfterEnd = schedule.endTime.add(const Duration(minutes: 30));
    
    return (schedule.status == ScheduleStatus.ongoing) ||
           (schedule.status == ScheduleStatus.scheduled && 
            now.isAfter(schedule.startTime) && 
            now.isBefore(thirtyMinutesAfterEnd));
  }
}

/// Extension to add color shade 25 for very light backgrounds
extension ColorShades on Color {
  Color get shade25 => Color.lerp(this, Colors.white, 0.95)!;
}