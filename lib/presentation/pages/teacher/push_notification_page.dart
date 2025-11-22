import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/models/notification_model.dart'
    as NotificationModel;
import 'package:markmeapp/data/repositories/teacher_repository.dart';
import 'class_selection_page.dart';
import 'student_selection_page.dart';

class PushNotificationPage extends ConsumerStatefulWidget {
  const PushNotificationPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PushNotificationPage> createState() =>
      _PushNotificationPageState();
}

class _PushNotificationPageState extends ConsumerState<PushNotificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedAudience = 'student';
  int _selectedStudentsCount = 0;
  bool _isLoading = false;

  // New fields for department and program selection
  List<String> _selectedDepartments = [];
  List<String> _selectedPrograms = [];
  String? _selectedClass;

  @override
  void initState() {
    super.initState();
    // Add listeners to update preview in real-time
    _titleController.addListener(_updatePreview);
    _messageController.addListener(_updatePreview);
  }

  void _updatePreview() {
    setState(() {}); // Trigger rebuild for preview
  }

  void _handleBackPressed() {
    context.go("/teacher");
  }

  final List<Map<String, dynamic>> _audienceOptions = [
    {
      'id': 'student',
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

  @override
  void dispose() {
    _titleController.removeListener(_updatePreview);
    _messageController.removeListener(_updatePreview);
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
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
          'Push Notification',
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
        child: Column(
          children: [
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

                      const SizedBox(height: 24),

                      // Live Preview Section
                      _buildPreviewSection(),

                      const SizedBox(height: 24),

                      // Title Input
                      _buildTitleInput(),

                      const SizedBox(height: 20),

                      // Message Input
                      _buildMessageInput(),

                      const SizedBox(height: 24),

                      // Audience Selection
                      _buildAudienceSection(),

                      // Show selected departments and programs if any
                      if (_selectedDepartments.isNotEmpty ||
                          _selectedPrograms.isNotEmpty)
                        _buildSelectionSummary(),

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
    );
  }

  /// Builds header section with icon and description
  Widget _buildHeaderSection() {
    return Container(
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
            child: const Icon(Icons.campaign, color: Colors.white, size: 28),
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
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds live preview section
  Widget _buildPreviewSection() {
    final hasTitle = _titleController.text.isNotEmpty;
    final hasMessage = _messageController.text.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
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
                Icons.visibility_rounded,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Live Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildNotificationPreview(),
        ],
      ),
    );
  }

  /// Builds actual notification preview
  Widget _buildNotificationPreview() {
    final title = _titleController.text.isNotEmpty
        ? _titleController.text
        : 'Notification Title';
    final message = _messageController.text.isNotEmpty
        ? _messageController.text
        : 'Your message will appear here...';
    final time = 'Now';
    final audienceText = _getAudienceText();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MarkMe App',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Educational App',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                time,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Notification Content
          if (_titleController.text.isNotEmpty)
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

          if (_titleController.text.isNotEmpty &&
              _messageController.text.isNotEmpty)
            const SizedBox(height: 8),

          if (_messageController.text.isNotEmpty)
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: 12),

          // Audience Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getAudienceIcon(), size: 12, color: Colors.blue.shade600),
                const SizedBox(width: 4),
                Text(
                  audienceText,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Gets audience display text
  String _getAudienceText() {
    switch (_selectedAudience) {
      case 'student':
        return 'All Students';
      case 'specific_class':
        return _selectedClass ?? 'Specific Class';
      case 'selective_students':
        return _selectedStudentsCount > 0
            ? '$_selectedStudentsCount Students'
            : 'Selective Students';
      default:
        return 'All Students';
    }
  }

  /// Gets audience icon
  IconData _getAudienceIcon() {
    switch (_selectedAudience) {
      case 'student':
        return Icons.groups_rounded;
      case 'specific_class':
        return Icons.class_rounded;
      case 'selective_students':
        return Icons.people_alt_rounded;
      default:
        return Icons.groups_rounded;
    }
  }

  /// Builds title input field
  Widget _buildTitleInput() {
    return Column(
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
    );
  }

  /// Builds message input field
  Widget _buildMessageInput() {
    return Column(
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
    );
  }

  /// Builds audience selection
  Widget _buildAudienceSection() {
    return Column(
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
        ..._audienceOptions
            .map((option) => _buildAudienceOption(option))
            .toList(),
      ],
    );
  }

  /// Builds selection summary for departments and programs
  Widget _buildSelectionSummary() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected Filters:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 18, 103, 201),
            ),
          ),
          const SizedBox(height: 8),
          if (_selectedDepartments.isNotEmpty)
            Text(
              'Departments: ${_selectedDepartments.join(', ')}',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
            ),
          if (_selectedPrograms.isNotEmpty)
            Text(
              'Programs: ${_selectedPrograms.join(', ')}',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
            ),
          if (_selectedClass != null)
            Text(
              'Class: $_selectedClass',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
            ),
        ],
      ),
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
                        color: isSelected
                            ? Colors.blue.shade600
                            : Colors.black87,
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
                Icon(Icons.check_circle, color: Colors.blue.shade600, size: 20),
              if (option['id'] == 'specific_class' ||
                  option['id'] == 'selective_students')
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
    if (option['id'] == 'specific_class' && _selectedClass != null) {
      return 'Class: $_selectedClass';
    }
    return option['subtitle'];
  }

  /// Handles audience selection and navigation
  void _handleAudienceSelection(String audienceId) async {
    if (audienceId == 'specific_class') {
      // Navigate to class selection page
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ClassSelectionPage()),
      );

      if (result != null) {
        setState(() {
          _selectedAudience = audienceId;
          _selectedClass = result['class_name'];
          _selectedDepartments = [result['program']] ?? [];
          _selectedPrograms = [result['program']] ?? [];
        });
      }
    } else if (audienceId == 'selective_students') {
      // Navigate to student selection page
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StudentSelectionPage()),
      );

      if (result != null) {
        setState(() {
          _selectedAudience = audienceId;
          _selectedStudentsCount = result['count'] ?? 0;
          _selectedDepartments = result['departments'] ?? [];
          _selectedPrograms = result['programs'] ?? [];
        });
      }
    } else {
      setState(() {
        _selectedAudience = audienceId;
        // Clear specific selections when choosing "all students"
        _selectedClass = null;
        _selectedDepartments = [];
        _selectedPrograms = [];
        _selectedStudentsCount = 0;
      });
    }
  }

  /// Builds send button
  Widget _buildSendButton() {
    return Container(
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
        onPressed: _isLoading ? null : _sendNotification,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.send, color: Colors.white, size: 20),
        label: Text(
          _isLoading ? 'Sending...' : 'Send Notification',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Handles send notification API call
  void _sendNotification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get repository instance
      final teacherRepo = ref.read(teacherRepositoryProvider);

      // Create notification object using alias
      final notification = NotificationModel.AppNotification(
        user: _selectedAudience,
        title: _titleController.text,
        dept: _selectedDepartments.join(
          ',',
        ), // Convert list to comma-separated string
        program: _selectedPrograms.join(
          ',',
        ), // Convert list to comma-separated string
        message: _messageController.text,
      );

      // Make API call
      final response = await teacherRepo.notify(notification);

      print("The response is: $response");

      setState(() {
        _isLoading = false;
      });

      if (response['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(response['message'] ?? 'Notification sent successfully!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back after success
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            context.pop();
          }
        });
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Failed to send notification'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('An error occurred: $e'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
