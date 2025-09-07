import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/schedule_model.dart';
import 'attendance_marking_page.dart';

/// Lecture Attendance Page - Shows selected lecture details with start attendance option
/// This is the second page in the attendance flow where teachers can:
/// - View detailed lecture information
/// - See lecture timing and room details
/// - Start the attendance marking process
/// - Navigate to the attendance marking interface
/// 
/// Backend developers: This page will need lecture details API integration
/// Expected endpoints:
/// - GET /api/lectures/{id}/details - Get detailed lecture information
/// - POST /api/lectures/{id}/start-attendance - Initialize attendance session
class LectureAttendancePage extends StatefulWidget {
  final ScheduleModel lecture;
  
  const LectureAttendancePage({
    Key? key,
    required this.lecture,
  }) : super(key: key);

  @override
  State<LectureAttendancePage> createState() => _LectureAttendancePageState();
}

class _LectureAttendancePageState extends State<LectureAttendancePage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _buttonController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _buttonScaleAnimation;

  bool _isStartingAttendance = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
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

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      // Custom App Bar
                      _buildCustomAppBar(),
                      
                      // Main Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Lecture Details Card
                              _buildLectureDetailsCard(),
                              
                              const SizedBox(height: 32),
                              
                              // Start Attendance Button
                              _buildStartAttendanceButton(),
                              
                              const SizedBox(height: 24),
                              
                              // Additional Info
                              _buildAdditionalInfo(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
              'Lecture Attendance',
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
              Icons.school,
              color: Colors.blue.shade600,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds lecture details card
  Widget _buildLectureDetailsCard() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject Header
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade600, Colors.blue.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.lecture.subjectName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.lecture.subjectCode,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Lecture Details Grid
                _buildDetailsGrid(),
                
                const SizedBox(height: 20),
                
                // Instructor Info
                _buildInstructorInfo(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds details grid
  Widget _buildDetailsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.access_time,
                  title: 'Time',
                  value: _formatTimeRange(),
                  color: Colors.blue.shade600,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade300,
              ),
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.location_on,
                  title: 'Room',
                  value: widget.lecture.roomNumber,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.business,
                  title: 'Building',
                  value: widget.lecture.building ?? 'N/A',
                  color: Colors.purple.shade600,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade300,
              ),
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.timer,
                  title: 'Duration',
                  value: '${widget.lecture.durationMinutes} min',
                  color: Colors.orange.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds detail item
  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Builds instructor info
  Widget _buildInstructorInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Instructor',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.lecture.instructorName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds start attendance button
  Widget _buildStartAttendanceButton() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: AnimatedBuilder(
                  animation: _buttonScaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _buttonScaleAnimation.value,
                      child: GestureDetector(
                        onTapDown: (_) => _buttonController.forward(),
                        onTapUp: (_) => _buttonController.reverse(),
                        onTapCancel: () => _buttonController.reverse(),
                        onTap: _startAttendance,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade600, Colors.blue.shade700],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.4),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.2),
                                blurRadius: 60,
                                offset: const Offset(0, 30),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isStartingAttendance)
                                const SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              
                              const SizedBox(height: 12),
                              
                              Text(
                                _isStartingAttendance ? 'Starting...' : 'Start\nAttendance',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Builds additional info
  Widget _buildAdditionalInfo() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Instructions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildInstructionItem(
                    '1. Ensure all students are present in the classroom',
                  ),
                  _buildInstructionItem(
                    '2. Click "Start Attendance" to begin the session',
                  ),
                  _buildInstructionItem(
                    '3. Mark each student as present or absent',
                  ),
                  _buildInstructionItem(
                    '4. Submit the attendance when complete',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds instruction item
  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Starts attendance marking
  void _startAttendance() async {
    if (_isStartingAttendance) return;
    
    setState(() {
      _isStartingAttendance = true;
    });
    
    HapticFeedback.mediumImpact();
    
    // Simulate loading
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
              AttendanceMarkingPage(lecture: widget.lecture),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Custom transition with scale and fade
            var scaleAnimation = Tween(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            );
            
            var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            );
            
            return ScaleTransition(
              scale: scaleAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  /// Gets status color
  Color _getStatusColor() {
    final now = DateTime.now();
    if (widget.lecture.status == ScheduleStatus.ongoing) {
      return Colors.green.shade600;
    } else if (widget.lecture.startTime.isAfter(now)) {
      return Colors.blue.shade600;
    } else {
      return Colors.orange.shade600;
    }
  }

  /// Gets status text
  String _getStatusText() {
    final now = DateTime.now();
    if (widget.lecture.status == ScheduleStatus.ongoing) {
      return 'Ongoing';
    } else if (widget.lecture.startTime.isAfter(now)) {
      return 'Upcoming';
    } else {
      return 'Ready';
    }
  }

  /// Formats time range
  String _formatTimeRange() {
    return '${_formatTime(widget.lecture.startTime)} - ${_formatTime(widget.lecture.endTime)}';
  }

  /// Formats time
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}