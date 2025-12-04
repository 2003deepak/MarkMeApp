import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LectureCardWidget extends StatelessWidget {
  final String subject;
  final String time;
  final String component;
  final String teacherName;
  final String? timeUntilStart;
  final Color color;
  final bool isDesktop;
  final String entityType; // student | teacher | clerk | admin
  final String? sessionId;
  final Map<String, dynamic> sessionData;
  final String lectureType;

  const LectureCardWidget({
    Key? key,
    required this.subject,
    required this.time,
    required this.color,
    required this.component,
    required this.teacherName,
    this.timeUntilStart,
    required this.entityType,
    this.isDesktop = false,
    this.sessionId,
    required this.sessionData,
    required this.lectureType,
  }) : super(key: key);

  // 🎯 Handle click
  void _handleCardClick(BuildContext context) {
    // ❌ If user is NOT teacher → block navigation
    if (entityType.toLowerCase() != 'teacher') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Only teachers can start or view this session'),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // ❌ Missing session ID
    if (sessionId == null || sessionId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Session ID not available'),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // DEBUG LOGS
    debugPrint("🎯 Navigating to session: $sessionId");
    debugPrint("📦 Session Data: $sessionData");
    debugPrint("📋 Lecture Type: $lectureType");

    // Add extra info
    final enhancedData = Map<String, dynamic>.from(sessionData);
    enhancedData['lecture_type'] = lectureType;
    enhancedData['navigation_timestamp'] = DateTime.now().toIso8601String();

    // ✅ ONLY TEACHER can navigate
    context.go('/teacher/session/$sessionId', extra: enhancedData);
  }

  @override
  Widget build(BuildContext context) {
    final double minHeight = isDesktop ? 160 : 140;
    final double maxHeight = isDesktop ? 180 : 160;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: minHeight,
        maxHeight: maxHeight,
        minWidth: double.infinity,
      ),
      child: GestureDetector(
        onTap: () => _handleCardClick(context),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: EdgeInsets.all(isDesktop ? 16 : 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header Row ---
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getComponentIcon(),
                        color: color,
                        size: isDesktop ? 18 : 14,
                      ),
                    ),
                    const Spacer(),

                    if (timeUntilStart != null && timeUntilStart!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          timeUntilStart!,
                          style: TextStyle(
                            fontSize: isDesktop ? 12 : 10,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // --- Subject ---
                Text(
                  subject,
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // --- Component ---
                Text(
                  component,
                  style: TextStyle(
                    fontSize: isDesktop ? 12 : 10,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                // --- Time ---
                Text(
                  time,
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 12,
                    color: Colors.grey.shade600,
                  ),
                ),

                const Spacer(),

                // --- Footer ---
                Row(
                  children: [
                    if (entityType.toLowerCase() != 'teacher')
                      Expanded(
                        child: Text(
                          'By $teacherName',
                          style: TextStyle(
                            fontSize: isDesktop ? 12 : 10,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
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

  IconData _getComponentIcon() {
    switch (component.toLowerCase()) {
      case 'lecture':
        return Icons.school;
      case 'lab':
        return Icons.science;
      case 'tutorial':
        return Icons.groups;
      case 'practical':
        return Icons.build;
      default:
        return Icons.access_time;
    }
  }

  // 🎨 Optional helper
  Color _getLectureTypeColor() {
    switch (lectureType.toLowerCase()) {
      case 'current':
        return Colors.green;
      case 'upcoming':
        return Colors.orange;
      case 'past':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}
