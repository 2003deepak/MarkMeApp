import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'class_selection_page.dart';
import 'student_selection_page.dart';

/// Send Notification Page - Beautiful UI for teachers to send notifications
/// This page allows teachers to:
/// - Send notifications to students
/// - Choose notification types and priorities
/// - Select target audience (class, subject, individual)
/// - Schedule notifications for later
/// - Preview notifications before sending
/// 
/// Backend developers: This page will need notification API integration
/// Expected endpoints:
/// - POST /api/notifications/send - Send notification to students
/// - GET /api/classes - Get teacher's classes for targeting
/// - GET /api/students - Get students list for individual targeting
class SendNotificationPage extends StatefulWidget {
  const SendNotificationPage({Key? key}) : super(key: key);

  @override
  State<SendNotificationPage> createState() => _SendNotificationPageState();
}

class _SendNotificationPageState extends State<SendNotificationPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _buttonScaleAnimation;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedType = 'general';
  String _selectedPriority = 'normal';
  String _selectedAudience = 'all_students';
  bool _scheduleForLater = false;
  DateTime? _scheduledDateTime;

  final List<Map<String, dynamic>> _notificationTypes = [
    {
      'id': 'general',
      'title': 'General',
      'icon': Icons.info_outline,
      'color': Colors.blue.shade600,
      'description': 'General information and announcements',
    },
    {
      'id': 'attendance',
      'title': 'Attendance',
      'icon': Icons.how_to_reg_outlined,
      'color': Colors.green.shade600,
      'description': 'Attendance related notifications',
    },
    {
      'id': 'assignment',
      'title': 'Assignment',
      'icon': Icons.assignment_outlined,
      'color': Colors.orange.shade600,
      'description': 'Assignment and homework notifications',
    },
    {
      'id': 'urgent',
      'title': 'Urgent',
      'icon': Icons.priority_high,
      'color': Colors.red.shade600,
      'description': 'Urgent and critical alerts',
    },
  ];

  final List<Map<String, dynamic>> _audienceOptions = [
    {
      'id': 'all_students',
      'title': 'All Students',
      'subtitle': 'Send to all your students',
      'icon': Icons.groups_outlined,
    },
    {
      'id': 'specific_class',
      'title': 'Specific Class',
      'subtitle': 'Choose a particular class',
      'icon': Icons.class_outlined,
    },
    {
      'id': 'selective_students',
      'title': 'Selective Students',
      'subtitle': 'Select individual students',
      'icon': Icons.person_add_outlined,
    },
  ];

  int _selectedStudentsCount = 0;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _buttonAnimationController = AnimationController(
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

    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _buttonAnimationController.dispose();
    _titleController.dispose();
    _messageController.dispose();
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
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Section
                                _buildHeaderSection(),
                                
                                const SizedBox(height: 32),
                                
                                // Notification Type Selection
                                _buildNotificationTypeSection(),
                                
                                const SizedBox(height: 24),
                                
                                // Title Input
                                _buildTitleInput(),
                                
                                const SizedBox(height: 20),
                                
                                // Message Input
                                _buildMessageInput(),
                                
                                const SizedBox(height: 24),
                                
                                // Priority Selection
                                _buildPrioritySection(),
                                
                                const SizedBox(height: 24),
                                
                                // Audience Selection
                                _buildAudienceSection(),
                                
                                const SizedBox(height: 24),
                                
                                // Schedule Options
                                _buildScheduleSection(),
                                
                                const SizedBox(height: 32),
                                
                                // Preview Section
                                _buildPreviewSection(),
                                
                                const SizedBox(height: 32),
                                
                                // Send Button
                                _buildSendButton(),
                                
                                const SizedBox(height: 20),
                              ],
                            ),
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

  /// Builds custom app bar with back button
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
            onTap: () => context.pop(),
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
              'Send Notification',
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
              Icons.notifications_active,
              color: Colors.blue.shade600,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds header section with icon and description
  Widget _buildHeaderSection() {
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
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.campaign,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reach Your Students',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Send important updates and announcements instantly',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds notification type selection
  Widget _buildNotificationTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notification Type',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 16),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: _notificationTypes.length,
          itemBuilder: (context, index) {
            final type = _notificationTypes[index];
            final isSelected = _selectedType == type['id'];
            
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 600 + (index * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, animationValue, child) {
                return Transform.scale(
                  scale: animationValue,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedType = type['id'];
                      });
                      HapticFeedback.lightImpact();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? type['color'].withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? type['color'] : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected 
                                ? type['color'].withOpacity(0.2)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: isSelected ? 8 : 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            type['icon'],
                            color: isSelected ? type['color'] : Colors.grey.shade600,
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            type['title'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? type['color'] : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type['description'],
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  /// Builds title input field
  Widget _buildTitleInput() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - animationValue), 0),
          child: Opacity(
            opacity: animationValue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Title',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _titleController,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter notification title',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(
                        Icons.title,
                        color: Colors.blue.shade400,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds message input field
  Widget _buildMessageInput() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 900),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - animationValue), 0),
          child: Opacity(
            opacity: animationValue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Message',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _messageController,
                    maxLines: 4,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your message here...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a message';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds priority selection
  Widget _buildPrioritySection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - animationValue), 0),
          child: Opacity(
            opacity: animationValue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Priority Level',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildPriorityOption('low', 'Low', Colors.green.shade600),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPriorityOption('normal', 'Normal', Colors.blue.shade600),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPriorityOption('high', 'High', Colors.red.shade600),
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

  /// Builds individual priority option
  Widget _buildPriorityOption(String id, String title, Color color) {
    final isSelected = _selectedPriority == id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPriority = id;
        });
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? color : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  /// Builds audience selection
  Widget _buildAudienceSection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1100),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - animationValue), 0),
          child: Opacity(
            opacity: animationValue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Send To',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                ..._audienceOptions.map((option) => 
                  _buildAudienceOption(option),
                ).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds individual audience option
  Widget _buildAudienceOption(Map<String, dynamic> option) {
    final isSelected = _selectedAudience == option['id'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _handleAudienceSelection(option['id']),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                option['icon'],
                color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
                size: 20,
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option['title'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.blue.shade600 : Colors.black87,
                      ),
                    ),
                    Text(
                      _getSubtitleText(option),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              
              if (option['id'] == 'specific_class' || option['id'] == 'selective_students')
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Gets subtitle text for audience options
  String _getSubtitleText(Map<String, dynamic> option) {
    if (option['id'] == 'selective_students' && _selectedStudentsCount > 0) {
      return '$_selectedStudentsCount students selected';
    }
    return option['subtitle'];
  }

  /// Handles audience selection and navigation
  void _handleAudienceSelection(String audienceId) async {
    HapticFeedback.lightImpact();
    
    if (audienceId == 'specific_class') {
      // Navigate to class selection page
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ClassSelectionPage(),
        ),
      );
      
      if (result != null) {
        setState(() {
          _selectedAudience = audienceId;
        });
      }
    } else if (audienceId == 'selective_students') {
      // Navigate to student selection page
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const StudentSelectionPage(),
        ),
      );
      
      if (result != null) {
        setState(() {
          _selectedAudience = audienceId;
          _selectedStudentsCount = result['count'] ?? 0;
        });
      }
    } else {
      setState(() {
        _selectedAudience = audienceId;
      });
    }
  }

  /// Builds schedule section
  Widget _buildScheduleSection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - animationValue), 0),
          child: Opacity(
            opacity: animationValue,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Schedule Options',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Switch(
                        value: _scheduleForLater,
                        onChanged: (value) {
                          setState(() {
                            _scheduleForLater = value;
                          });
                        },
                        activeColor: Colors.blue.shade600,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Schedule for later',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  
                  if (_scheduleForLater) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _selectDateTime,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.blue.shade600,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _scheduledDateTime != null
                                  ? _formatDateTime(_scheduledDateTime!)
                                  : 'Select date and time',
                              style: TextStyle(
                                fontSize: 14,
                                color: _scheduledDateTime != null
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds preview section
  Widget _buildPreviewSection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1300),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - animationValue), 0),
          child: Opacity(
            opacity: animationValue,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade50, Colors.grey.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.preview,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Preview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
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
                        Row(
                          children: [
                            Icon(
                              _getSelectedTypeIcon(),
                              color: _getSelectedTypeColor(),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _titleController.text.isEmpty 
                                  ? 'Notification Title' 
                                  : _titleController.text,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _messageController.text.isEmpty 
                              ? 'Your notification message will appear here...' 
                              : _messageController.text,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Just now',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
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

  /// Builds send button with animation
  Widget _buildSendButton() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1400),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: AnimatedBuilder(
            animation: _buttonScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _buttonScaleAnimation.value,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade700],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _sendNotification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: Text(
                      _scheduleForLater ? 'Schedule Notification' : 'Send Now',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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

  /// Handles send notification
  void _sendNotification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _buttonAnimationController.forward().then((_) {
      _buttonAnimationController.reverse();
    });

    // TODO: Implement actual notification sending logic
    // This would call your backend API to send the notification

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _scheduleForLater 
                  ? 'Notification scheduled successfully!' 
                  : 'Notification sent successfully!',
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );

    // Navigate back after a short delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        context.pop();
      }
    });
  }

  /// Selects date and time for scheduling
  void _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _scheduledDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  /// Gets selected notification type icon
  IconData _getSelectedTypeIcon() {
    final type = _notificationTypes.firstWhere(
      (t) => t['id'] == _selectedType,
      orElse: () => _notificationTypes[0],
    );
    return type['icon'];
  }

  /// Gets selected notification type color
  Color _getSelectedTypeColor() {
    final type = _notificationTypes.firstWhere(
      (t) => t['id'] == _selectedType,
      orElse: () => _notificationTypes[0],
    );
    return type['color'];
  }

  /// Formats date time for display
  String _formatDateTime(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} at $displayHour:$minute $period';
  }
}