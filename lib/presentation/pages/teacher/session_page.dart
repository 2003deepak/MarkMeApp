import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class SessionPage extends StatefulWidget {
  final Map<String, dynamic> sessionData;

  const SessionPage({Key? key, required this.sessionData}) : super(key: key);

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

  // Helper methods to extract data from sessionData
  String get subjectName =>
      widget.sessionData['subject_name'] ?? 'Unknown Subject';
  String get subjectCode => widget.sessionData['subject_code'] ?? 'N/A';
  String get teacherName =>
      widget.sessionData['teacher_name'] ?? 'Unknown Teacher';
  String get component => widget.sessionData['component'] ?? 'Lecture';
  String get startTime => widget.sessionData['start_time'] ?? '';
  String get endTime => widget.sessionData['end_time'] ?? '';
  String get sessionId => widget.sessionData['session_id'] ?? '';

  @override
  void initState() {
    super.initState();

    // Log the received data for debugging
    debugPrint("🎯 Session Data Received: ${widget.sessionData}");
    debugPrint("🆔 Session ID: $sessionId");

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

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _handleBackPressed() {
    context.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
          onPressed: _handleBackPressed,
        ),
        title: const Text(
          'Session Details',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.category,
                  title: 'Component',
                  value: component,
                  color: Colors.teal.shade600,
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
              Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
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
          _buildInstructionItem('3. Mark each student as present or absent'),
          _buildInstructionItem('4. Submit the attendance when complete'),
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

    setState(() {
      _isStartingAttendance = false;
    });

    // TODO: Uncomment and implement navigation to AttendanceMarkingPage
    // if (mounted) {
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(
    //       builder: (context) => AttendanceMarkingPage(sessionData: widget.sessionData),
    //     ),
    //   );
    // }
  }

  /// Gets status color
  Color _getStatusColor() {
    return Colors.green.shade600;
  }

  /// Gets status text
  String _getStatusText() {
    return 'Ready to Start';
  }

  /// Formats time range
  String _formatTimeRange() {
    return '$startTime - $endTime';
  }
}
