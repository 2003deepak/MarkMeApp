import 'package:flutter/material.dart';
import 'package:markmeapp/presentation/widgets/lecture_card.dart';
import 'package:markmeapp/presentation/widgets/ui/error.dart';

class LecturesWidget extends StatelessWidget {
  final bool isDesktop;
  final String title;
  final List<dynamic> sessions;
  final bool isLoading;
  final String errorMessage;
  final VoidCallback onRetry;
  final String entityType;

  const LecturesWidget({
    super.key,
    required this.title,
    required this.isDesktop,
    required this.sessions,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.entityType,
  });

  // 🎨 Get fixed or dynamic color based on component type
  Color _getComponentColor(String component, String subjectName) {
    switch (component.toLowerCase()) {
      case 'lecture':
        return const Color(0xFF1E3A8A); // Deep Blue
      case 'lab':
        return const Color(0xFFE67C00); // Orange
      default:
        return _getSubjectColor(subjectName); // Dynamic fallback
    }
  }

  // 🎨 Dynamic color fallback for non-lecture/lab subjects
  Color _getSubjectColor(String subjectName) {
    final colors = [
      Colors.teal,
      Colors.purple,
      Colors.indigo,
      Colors.pink,
      Colors.blueGrey,
      Colors.redAccent,
      Colors.green,
    ];
    final index = subjectName.hashCode % colors.length;
    return colors[index];
  }

  // 🕒 Helper function to format time range
  String _formatTimeRange(String startTime, String endTime) {
    return '$startTime - $endTime';
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("📚 $title Sessions: $sessions");
    debugPrint("🧾 Is Empty: ${sessions.isEmpty}");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Section Title & Loader ---
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isDesktop ? 22 : 18,
                fontWeight: FontWeight.w700,
                color: const Color.fromARGB(221, 22, 21, 21),
              ),
            ),
            const SizedBox(width: 8),
            if (isLoading)
              SizedBox(
                width: isDesktop ? 20 : 16,
                height: isDesktop ? 20 : 16,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // --- Conditional Rendering ---
        if (isLoading)
          _buildLoadingState()
        else if (errorMessage.isNotEmpty)
          CustomErrorWidget(
            errorMessage: errorMessage,
            onRetry: onRetry,
            isRetryEnabled: true,
            isDesktop: isDesktop,
          )
        else if (sessions.isEmpty)
          _buildEmptyState()
        else
          _buildSessionsList(context),
      ],
    );
  }

  // --- Empty State Widget ---
  Widget _buildEmptyState() {
    String heading;
    String subtitle;

    if (title.toLowerCase().contains('current')) {
      heading = 'No Ongoing Sessions Right Now';
      subtitle = 'Check again later for active sessions.';
    } else if (title.toLowerCase().contains('upcoming')) {
      heading = 'No Upcoming Lectures';
      subtitle = 'Check back later for scheduled sessions.';
    } else {
      heading = 'No Past Sessions Available';
      subtitle =
          'You haven\'t conducted any sessions yet.'; // ✅ Fixed: escaped apostrophe
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 48 : 32,
        horizontal: isDesktop ? 24 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isDesktop ? 72 : 56,
            height: isDesktop ? 72 : 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              Icons.schedule,
              size: isDesktop ? 40 : 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            heading,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 20 : 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 16 : 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // --- Loading Skeleton ---
  Widget _buildLoadingState() {
    return Row(
      children: [
        Expanded(child: _buildSkeletonCard()),
        if (isDesktop) ...[
          const SizedBox(width: 12),
          Expanded(child: _buildSkeletonCard()),
          const SizedBox(width: 12),
          Expanded(child: _buildSkeletonCard()),
        ],
      ],
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isDesktop ? 40 : 32,
            height: isDesktop ? 40 : 32,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: isDesktop ? 16 : 14,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: isDesktop ? 14 : 12,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  // --- Main Sessions List ---
  Widget _buildSessionsList(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: sessions.map((session) {
          final subjectName = session['subject_name'] ?? 'Unknown Subject';
          final startTime = session['start_time'] ?? '';
          final endTime = session['end_time'] ?? '';
          final component = session['component'] ?? 'Lecture';
          final teacherName = session['teacher_name'] ?? '';
          final timeUntilStart = session['time_until_start_display'] ?? '';

          // ✅ FIXED: Use 'session_id' instead of 'id'
          final sessionId = session['session_id']?.toString();

          debugPrint("🆔 Session ID for card: $sessionId");

          final color = _getComponentColor(component, subjectName);

          return Container(
            width: isDesktop ? 200 : 160,
            margin: const EdgeInsets.only(right: 12),
            child: LectureCardWidget(
              subject: subjectName,
              time: _formatTimeRange(startTime, endTime),
              component: component,
              teacherName: teacherName,
              timeUntilStart: timeUntilStart,
              color: color,
              isDesktop: isDesktop,
              entityType: entityType,
              sessionId: sessionId,
              sessionData: session,
            ),
          );
        }).toList(),
      ),
    );
  }
}
