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

  String _selectedAudience = '';
  int _selectedStudentsCount = 0;
  bool _isLoading = false;

  // Fields for different audience types
  List<Map<String, dynamic>> _selectedFilters = [];
  List<String> _selectedTargetIds = [];

  // Constants
  static const _primaryColor = Color(0xFF2563EB);
  static const _backgroundColor = Color(0xFFF5F7FA);
  static const _cardColor = Colors.white;
  static const _animationDuration = Duration(milliseconds: 200);

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

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_updatePreview);
    _messageController.addListener(_updatePreview);
  }

  @override
  void dispose() {
    _titleController.removeListener(_updatePreview);
    _messageController.removeListener(_updatePreview);
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _updatePreview() => setState(() {});

  void _handleBackPressed() => context.go("/teacher");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 24),
                      _buildPreviewSection(),
                      const SizedBox(height: 24),
                      _buildTitleInput(),
                      const SizedBox(height: 20),
                      _buildMessageInput(),
                      const SizedBox(height: 24),
                      _buildAudienceSection(),
                      const SizedBox(height: 32),
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

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _primaryColor,
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
    );
  }

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

  Widget _buildPreviewSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
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

  Widget _buildNotificationPreview() {
    final title = _titleController.text.isNotEmpty
        ? _titleController.text
        : 'Notification Title';
    final message = _messageController.text.isNotEmpty
        ? _messageController.text
        : 'Your message will appear here...';
    final audienceText = _getAudienceText();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
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
          _buildPreviewHeader(),
          const SizedBox(height: 12),
          if (_titleController.text.isNotEmpty) _buildPreviewTitle(title),
          if (_titleController.text.isNotEmpty &&
              _messageController.text.isNotEmpty)
            const SizedBox(height: 8),
          if (_messageController.text.isNotEmpty) _buildPreviewMessage(message),
          const SizedBox(height: 12),
          _buildAudienceBadge(audienceText),
        ],
      ),
    );
  }

  Widget _buildPreviewHeader() {
    return Row(
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
          'Now',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildPreviewTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPreviewMessage(String message) {
    return Text(
      message,
      style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildAudienceBadge(String audienceText) {
    return Container(
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
    );
  }

  String _getAudienceText() {
    switch (_selectedAudience) {
      case 'all_students':
        return 'All Students';
      case 'specific_class':
        return _getSelectedClassName();
      case 'selective_students':
        return _selectedStudentsCount > 0
            ? '$_selectedStudentsCount Students'
            : 'Selective Students';
      default:
        return 'All Students';
    }
  }

  String _getSelectedClassName() {
    if (_selectedFilters.isEmpty) return 'Specific Class';

    final firstFilter = _selectedFilters.first;
    final program = firstFilter['program'];
    final dept = firstFilter['dept'];
    final semester = firstFilter['semester'];

    if (program != null && dept != null && semester != null) {
      return '$dept $program Sem $semester';
    }

    return program?.toString() ?? 'Selected Class';
  }

  IconData _getAudienceIcon() {
    switch (_selectedAudience) {
      case 'all_students':
        return Icons.groups_rounded;
      case 'specific_class':
        return Icons.class_rounded;
      case 'selective_students':
        return Icons.people_alt_rounded;
      default:
        return Icons.groups_rounded;
    }
  }

  Widget _buildTitleInput() {
    return _buildInputField(
      label: 'Title',
      controller: _titleController,
      hintText: 'Enter notification title',
      prefixIcon: Icons.title,
      validator: (value) =>
          value?.isEmpty == true ? 'Please enter a title' : null,
    );
  }

  Widget _buildMessageInput() {
    return _buildInputField(
      label: 'Message',
      controller: _messageController,
      hintText: 'Enter your message here...',
      prefixIcon: null,
      maxLines: 4,
      validator: (value) =>
          value?.isEmpty == true ? 'Please enter a message' : null,
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData? prefixIcon,
    int maxLines = 1,
    required String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
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
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: Colors.blue.shade400, size: 20)
                  : null,
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
              fillColor: _cardColor,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: maxLines > 1 ? 16 : 0,
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

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
        ..._audienceOptions.map(_buildAudienceOption).toList(),
      ],
    );
  }

  Widget _buildAudienceOption(Map<String, dynamic> option) {
    final isSelected = _selectedAudience == option['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _handleAudienceSelection(option['id']),
        child: AnimatedContainer(
          duration: _animationDuration,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : _cardColor,
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

  String _getSubtitleText(Map<String, dynamic> option) {
    final id = option['id'];

    if (id == 'selective_students' && _selectedStudentsCount > 0) {
      return '$_selectedStudentsCount students selected';
    }

    if (id == 'specific_class' && _selectedFilters.isNotEmpty) {
      return 'Class: ${_getSelectedClassName()}';
    }

    return option['subtitle'];
  }

  void _handleAudienceSelection(String audienceId) async {
    switch (audienceId) {
      case 'specific_class':
        await _handleClassSelection();
        break;
      case 'selective_students':
        await _handleStudentSelection();
        break;
      default:
        _handleDefaultSelection(audienceId);
    }
  }

  Future<void> _handleClassSelection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ClassSelectionPage()),
    );

    if (result != null && result['filters'] != null) {
      final List<dynamic> filters = result['filters'];

      debugPrint("🎯 CLASS SELECTION RESULT → $result");
      debugPrint("🎯 FILTERS RECEIVED → $filters");

      setState(() {
        _selectedAudience = 'specific_class';
        _selectedFilters = List<Map<String, dynamic>>.from(filters);
      });
    }
  }

  Future<void> _handleStudentSelection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StudentSelectionPage()),
    );

    if (result != null) {
      setState(() {
        _selectedAudience = 'selective_students';
        _selectedStudentsCount = result['count'] ?? 0;
        _selectedTargetIds = result['student_ids'] != null
            ? List<String>.from(result['student_ids'])
            : [];
      });
    }
  }

  void _handleDefaultSelection(String audienceId) {
    setState(() {
      _selectedAudience = audienceId;
      _selectedFilters.clear();
      _selectedTargetIds.clear();
      _selectedStudentsCount = 0;
    });
  }

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

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final teacherRepo = ref.read(teacherRepositoryProvider);
      final notification = _createNotification();

      final response = await teacherRepo.notify(notification);

      debugPrint("The response is: $response");

      setState(() => _isLoading = false);

      if (response['success'] == true) {
        _showSuccessSnackBar(response['message']);
        _navigateBackAfterDelay();
      } else {
        _showErrorSnackBar('Failed to send notification');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('An error occurred: $e');
    }
  }

  // FIXED: Corrected _createNotification method without copyWith
  NotificationModel.AppNotification _createNotification() {
    switch (_selectedAudience) {
      case 'specific_class':
        final filters = _selectedFilters
            .map(
              (f) => NotificationModel.NotificationFilter(
                dept: f['dept'],
                program: f['program'],
                semester: f['semester'],
                batchYear: f['batch_year'],
              ),
            )
            .toList();

        return NotificationModel.AppNotification(
          user: 'student',
          title: _titleController.text,
          message: _messageController.text,
          filters: filters,
        );

      case 'selective_students':
        return NotificationModel.AppNotification(
          user: 'student',
          title: _titleController.text,
          message: _messageController.text,
          targetIds: _selectedTargetIds.isNotEmpty ? _selectedTargetIds : null,
        );

      default:
        return NotificationModel.AppNotification(
          user: 'student',
          title: _titleController.text,
          message: _messageController.text,
        );
    }
  }

  void _showSuccessSnackBar(String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message ?? 'Notification sent successfully!'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateBackAfterDelay() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) context.pop();
    });
  }
}
