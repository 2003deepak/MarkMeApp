import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';

import 'package:markmeapp/core/utils/app_logger.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';
import 'package:markmeapp/presentation/pages/teacher/raise_exception_page.dart';

class SessionPage extends StatefulWidget {
  final Map<String, dynamic> sessionData;

  const SessionPage({super.key, required this.sessionData});

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _buttonController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _buttonScaleAnimation;

  bool _isStartingAttendance = false;
  String _timeUntilStart = '';
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;
  List<CameraDescription>? _cameras;

  // Helper methods to extract data from sessionData
  String get subjectName =>
      widget.sessionData['subject_name'] ?? 'Unknown Subject';
  String get subjectCode => widget.sessionData['subject_code'] ?? 'N/A';
  String get teacherName =>
      widget.sessionData['teacher_name'] ?? 'Unknown Teacher';
  String get component => widget.sessionData['component'] ?? 'Lecture';
  String get startTime => widget.sessionData['start_time'] ?? '';
  String get endTime => widget.sessionData['end_time'] ?? '';
  String get attendanceId => widget.sessionData['attendance_id'] ?? '';

  // ✅ Get lecture type from session data
  String get lectureType => widget.sessionData['lecture_type'] ?? 'current';

  @override
  void initState() {
    super.initState();

    // Log the received data for debugging
    AppLogger.info("🎯 Session Data Received: ${widget.sessionData}");
    AppLogger.info("🆔 Session ID: $attendanceId");
    AppLogger.info("📋 Lecture Type: $lectureType");

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    // ✅ Only pulse for current sessions
    if (lectureType == 'current') {
      _pulseController.repeat(reverse: true);
    }

    // ✅ Start countdown timer for upcoming sessions
    if (lectureType == 'upcoming') {
      _startCountdownTimer();
    }

    // ✅ Initialize cameras
    _initializeCameras();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _buttonController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ✅ Initialize cameras
  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
      AppLogger.info('📷 Cameras initialized: ${_cameras?.length ?? 0} found');
    } catch (e) {
      AppLogger.error('❌ Error initializing cameras: $e');
      _showErrorSnackBar('Failed to initialize camera: $e');
    }
  }

  void _handleBackPressed() {
    if (mounted) {
      HapticFeedback.lightImpact();
      context.go('/teacher');
    }
  }

  // ✅ Start countdown timer for upcoming sessions
  void _startCountdownTimer() {
    // Calculate initial time remaining
    _calculateTimeRemaining();

    // Update every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _timeRemaining = _timeRemaining - const Duration(seconds: 1);
        _timeUntilStart = _formatDuration(_timeRemaining);

        if (_timeRemaining.inSeconds <= 0) {
          timer.cancel();

          setState(() {
            widget.sessionData['lecture_type'] = 'current';
          });

          // Restart pulse animation because it is required for current sessions
          _pulseController.reset();
          _pulseController.repeat(reverse: true);
        }
      });
    });
  }

  // ✅ Calculate time remaining until session starts
  void _calculateTimeRemaining() {
    try {
      final now = DateTime.now();
      final startTimeParts = startTime.split(':');

      if (startTimeParts.length >= 2) {
        int hour = int.parse(startTimeParts[0]);
        int minute = int.parse(startTimeParts[1].split(' ')[0]);

        // Handle PM times (if time contains PM and hour < 12, add 12)
        if (startTime.toLowerCase().contains('pm') && hour < 12) {
          hour += 12;
        }
        // Handle AM times (if time contains AM and hour == 12, set to 0)
        if (startTime.toLowerCase().contains('am') && hour == 12) {
          hour = 0;
        }

        final sessionStart = DateTime(
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );
        _timeRemaining = sessionStart.difference(now);

        if (_timeRemaining.isNegative) {
          _timeRemaining = Duration.zero;
        }

        _timeUntilStart = _formatDuration(_timeRemaining);
      }
    } catch (e) {
      AppLogger.error('Error calculating time remaining: $e');
      _timeUntilStart = 'Time not available';
    }
  }

  // Helper method to format duration in a readable way
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      final hours = duration.inHours.remainder(24);
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);
      return '${duration.inDays}d ${hours}h ${minutes}m ${seconds}s';
    } else if (duration.inHours > 0) {
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);
      return '${duration.inHours}h ${minutes}m ${seconds}s';
    } else if (duration.inMinutes > 0) {
      final seconds = duration.inSeconds.remainder(60);
      return '${duration.inMinutes}m ${seconds}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: MarkMeAppBar(
        title: 'Session Details',
        onBackPressed: _handleBackPressed,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Lecture Details Card
              _buildLectureDetailsCard(),

              const SizedBox(height: 32),

              // Attendance Button (conditionally shown)
              if (lectureType != 'past') _buildAttendanceButton(),

              const SizedBox(height: 24),

              // Raise Exception Button
              if (lectureType != 'past') ...[
                _buildRaiseExceptionButton(),
                const SizedBox(height: 24),
              ],

              // Additional Info
              _buildAdditionalInfo(),

              // ✅ Past session message
              if (lectureType == 'past') _buildPastSessionMessage(),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds lecture details card
  Widget _buildLectureDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20), // 0.08
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withAlpha(77), // 0.3
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 28),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subjectName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subjectCode,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Status badge with appropriate color
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor().withAlpha(26), // 0.1
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
                  color: const Color(0xFF2563EB),
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.category,
                  title: 'Component',
                  value: component,
                  color: const Color(0xFF2563EB),
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
        Icon(icon, color: color, size: 24),
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
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
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
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
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
                  teacherName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds attendance button based on lecture type
  Widget _buildAttendanceButton() {
    if (lectureType == 'current') {
      return _buildStartAttendanceButton();
    } else if (lectureType == 'upcoming') {
      return _buildUpcomingButton();
    } else {
      return const SizedBox.shrink();
    }
  }

  /// Builds start attendance button for current sessions
  Widget _buildStartAttendanceButton() {
    return AnimatedBuilder(
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withAlpha(102), // 0.4
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                        BoxShadow(
                          color: Colors.blue.withAlpha(51), // 0.2
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
                          _isStartingAttendance
                              ? 'Starting...'
                              : 'Start\nAttendance',
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
    );
  }

  /// Builds upcoming session button
  Widget _buildUpcomingButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: AnimatedBuilder(
            animation: _buttonScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _buttonScaleAnimation.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(102), // 0.4
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.schedule, color: Colors.white, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'Starts In\n$_timeUntilStart',
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
              );
            },
          ),
        );
      },
    );
  }

  /// Builds raise exception button
  Widget _buildRaiseExceptionButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () async {
          // Navigate to Raise Exception Page
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  RaiseExceptionPage(sessionData: widget.sessionData),
            ),
          );
        },
        icon: const Icon(Icons.assignment_late_outlined, color: Colors.orange),
        label: const Text(
          'Raise Exception',
          style: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Colors.orange.withAlpha(26), // 0.1
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Builds past session message
  Widget _buildPastSessionMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(Icons.history, color: Colors.grey.shade500, size: 48),
          const SizedBox(height: 16),
          Text(
            'Session Completed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This session has already ended. You can view attendance records in the history section.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// Builds additional info
  Widget _buildAdditionalInfo() {
    return Container(
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
              const Icon(
                Icons.info_outline,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ..._getInstructions().map(_buildInstructionItem),
        ],
      ),
    );
  }

  /// Builds instruction item
  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

  /// Starts attendance marking (only for current sessions)
  Future<void> _startAttendance() async {
    if (_isStartingAttendance || lectureType != 'current') return;

    if (attendanceId.isEmpty) {
      _showErrorSnackBar('Attendance ID is empty');
      return;
    }

    setState(() {
      _isStartingAttendance = true;
    });

    HapticFeedback.mediumImpact();

    // Simulate loading
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _isStartingAttendance = false;
    });

    if (mounted) {
      try {
        context.push(
          '/teacher/session/capture',
          extra: {'sessionData': widget.sessionData},
        );
      } catch (e) {
        _showErrorSnackBar('Failed to open camera: $e');
      }
    }
  }

  // ✅ Status color helpers (only for status badges)
  Color _getStatusColor() {
    switch (lectureType) {
      case 'current':
        return Colors.green; // Green for current
      case 'upcoming':
        return Colors.orange; // Yellow/Orange for upcoming
      case 'past':
        return Colors.red; // Red for past
      default:
        return const Color(0xFF2563EB);
    }
  }

  String _getStatusText() {
    switch (lectureType) {
      case 'current':
        return 'Current';
      case 'upcoming':
        return 'Upcoming';
      case 'past':
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  List<String> _getInstructions() {
    switch (lectureType) {
      case 'current':
        return [
          '1. Ensure all students are present in the classroom',
          '2. Click "Start Attendance" to begin the session',
          '3. Mark each student as present or absent',
          '4. Submit the attendance when complete',
        ];
      case 'upcoming':
        return [
          '1. Prepare your teaching materials in advance',
          '2. Ensure the classroom is ready for students',
          '3. Attendance can only be started when session begins',
        ];
      case 'past':
        return [
          '1. This session has already been completed',
          '2. Attendance records are available in history',
          '3. You can review student participation data',
          '4. Contact admin for any attendance modifications',
        ];
      default:
        return [
          '1. Session details are displayed above',
          '2. Follow the appropriate procedures',
          '3. Contact support if you need assistance',
        ];
    }
  }

  /// Formats time range
  String _formatTimeRange() {
    return '$startTime - $endTime';
  }

  /// Shows error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
