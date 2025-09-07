import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/mock/mock_schedule_data.dart';
import '../../../data/models/schedule_model.dart';
import 'lecture_attendance_page.dart';

/// Attendance Management Page - Shows today's lectures for attendance marking
/// This is the first page in the attendance flow where teachers can:
/// - View all today's scheduled lectures
/// - See lecture details (time, subject, room)
/// - Select a lecture to start attendance
/// - Navigate to individual lecture attendance
/// 
/// Backend developers: This page will need lecture API integration
/// Expected endpoints:
/// - GET /api/teacher/lectures/today - Get today's lectures for teacher
/// - GET /api/lectures/{id}/details - Get specific lecture details
class AttendanceManagementPage extends StatefulWidget {
  const AttendanceManagementPage({Key? key}) : super(key: key);

  @override
  State<AttendanceManagementPage> createState() => _AttendanceManagementPageState();
}

class _AttendanceManagementPageState extends State<AttendanceManagementPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  List<ScheduleModel> _todayLectures = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));

    _loadTodayLectures();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  /// Loads today's lectures
  void _loadTodayLectures() async {
    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    setState(() {
      _todayLectures = MockScheduleData.getTodaySchedules();
      _isLoading = false;
    });
    
    _animationController.forward();
    _cardAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            _buildCustomAppBar(),
            
            // Main Content
            Expanded(
              child: _isLoading ? _buildLoadingState() : _buildLecturesList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds custom app bar
  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.grey.shade700,
                size: 20,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          const Expanded(
            child: Text(
              'Mark Attendance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.how_to_reg,
              color: Colors.blue.shade600,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: const Text(
                  'Loading today\'s lectures...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Builds lectures list
  Widget _buildLecturesList() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    _buildHeaderSection(),
                    
                    const SizedBox(height: 32),
                    
                    // Lectures List
                    if (_todayLectures.isEmpty)
                      _buildEmptyState()
                    else
                      _buildLecturesGrid(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds header section
  Widget _buildHeaderSection() {
    final now = DateTime.now();
    final dateStr = '${_getMonthName(now.month)} ${now.day}, ${now.year}';
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.today,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Today\'s Lectures',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.schedule,
                      label: '${_todayLectures.length} Lectures',
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      icon: Icons.people,
                      label: 'Multiple Classes',
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds stat chip
  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds lectures grid
  Widget _buildLecturesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select a lecture to mark attendance',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        
        const SizedBox(height: 20),
        
        AnimatedBuilder(
          animation: _cardAnimationController,
          builder: (context, child) {
            return Column(
              children: _todayLectures.asMap().entries.map((entry) {
                final index = entry.key;
                final lecture = entry.value;
                
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 600 + (index * 150)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutBack,
                  builder: (context, animationValue, child) {
                    return Transform.translate(
                      offset: Offset(50 * (1 - animationValue), 0),
                      child: Opacity(
                        opacity: animationValue,
                        child: _buildLectureCard(lecture, index),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  /// Builds individual lecture card
  Widget _buildLectureCard(ScheduleModel lecture, int index) {
    final now = DateTime.now();
    final isOngoing = lecture.status == ScheduleStatus.ongoing;
    final isUpcoming = lecture.startTime.isAfter(now);
    final isCompleted = lecture.status == ScheduleStatus.completed;
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (isCompleted) {
      statusColor = Colors.grey.shade600;
      statusText = 'Completed';
      statusIcon = Icons.check_circle;
    } else if (isOngoing) {
      statusColor = Colors.green.shade600;
      statusText = 'Ongoing';
      statusIcon = Icons.play_circle;
    } else if (isUpcoming) {
      statusColor = Colors.blue.shade600;
      statusText = 'Upcoming';
      statusIcon = Icons.schedule;
    } else {
      statusColor = Colors.orange.shade600;
      statusText = 'Ready';
      statusIcon = Icons.play_arrow;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => _navigateToLectureAttendance(lecture),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.school,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lecture.subjectName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lecture.subjectCode,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Details Row
              Row(
                children: [
                  _buildDetailItem(
                    icon: Icons.access_time,
                    label: _formatTimeRange(lecture.startTime, lecture.endTime),
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 20),
                  _buildDetailItem(
                    icon: Icons.location_on,
                    label: lecture.roomNumber,
                    color: Colors.green.shade600,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  _buildDetailItem(
                    icon: Icons.business,
                    label: lecture.building ?? 'N/A',
                    color: Colors.purple.shade600,
                  ),
                  const SizedBox(width: 20),
                  _buildDetailItem(
                    icon: Icons.timer,
                    label: '${lecture.durationMinutes} min',
                    color: Colors.orange.shade600,
                  ),
                ],
              ),
              
              if (!isCompleted) ...[
                const SizedBox(height: 16),
                
                Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade700],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToLectureAttendance(lecture),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.how_to_reg,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Mark Attendance',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds detail item
  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Builds empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'No Lectures Today',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'You don\'t have any lectures scheduled for today.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Navigates to lecture attendance page
  void _navigateToLectureAttendance(ScheduleModel lecture) {
    HapticFeedback.lightImpact();
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            LectureAttendancePage(lecture: lecture),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  /// Formats time range
  String _formatTimeRange(DateTime start, DateTime end) {
    return '${_formatTime(start)} - ${_formatTime(end)}';
  }

  /// Formats time
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  /// Gets month name
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}