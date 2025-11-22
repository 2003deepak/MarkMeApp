import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/repositories/teacher_repository.dart';

class ClassSelectionPage extends ConsumerStatefulWidget {
  const ClassSelectionPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ClassSelectionPage> createState() => _ClassSelectionPageState();
}

class _ClassSelectionPageState extends ConsumerState<ClassSelectionPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? _selectedClassId;
  List<Map<String, dynamic>> _classes = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final Map<String, Color> componentColors = {
    'Lecture': const Color(0xFF1E3A8A), // Dark Blue
    'Lab': const Color(0xFFE67C00), // Dark Orange
    'Practical': const Color(0xFF059669), // Green for Practical
    'Tutorial': const Color(0xFF7C3AED), // Purple for Tutorial
  };

  final Map<String, Color> componentLightColors = {
    'Lecture': const Color(0xFFDBEAFE), // Light Blue
    'Lab': const Color(0xFFFFEDD5), // Light Orange
    'Practical': const Color(0xFFD1FAE5), // Light Green
    'Tutorial': const Color(0xFFF3E8FF), // Light Purple
  };

  void _handleBackPressed() {
    context.pop("/teacher/push-notification");
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Correct way to access the repository using Provider
      final teacherRepo = ref.read(teacherRepositoryProvider);

      final response = await teacherRepo.fetchClassForNotification();

      debugPrint("📦 Class Fetch Response: $response");

      if (response['success'] == true) {
        final apiData = response['data'] as List<dynamic>;

        // Transform API data to match UI format
        _classes = _transformApiData(apiData);

        _animationController.forward();
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to load classes';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while loading classes: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _transformApiData(List<dynamic> apiData) {
    final List<Map<String, dynamic>> transformedClasses = [];
    final List<Color> colorOptions = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.red.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
      Colors.pink.shade600,
    ];

    for (int i = 0; i < apiData.length; i++) {
      final classData = apiData[i] as Map<String, dynamic>;
      final subjects = classData['subjects'] as List<dynamic>;

      // Use the first subject for display (you can modify this logic as needed)
      final firstSubject = subjects.isNotEmpty
          ? subjects[0] as Map<String, dynamic>
          : null;

      transformedClasses.add({
        'id': 'class_${i + 1}',
        'name': classData['program'] ?? 'Unknown Program',
        'degree': '${classData['program']} Program',
        'semester': '${classData['semester']}th Semester',
        'section': 'A', // You might want to get this from API if available
        'year': _getYearFromSemester(classData['semester']),
        'students_count': classData['student_count'] ?? 0,
        'subject': firstSubject != null
            ? '${firstSubject['subject_name']} (${firstSubject['subject_code']})'
            : 'No Subject',
        'color': colorOptions[i % colorOptions.length],
        'api_data': classData, // Store original API data for later use
      });
    }

    return transformedClasses;
  }

  String _getYearFromSemester(dynamic semester) {
    final sem = semester is int
        ? semester
        : int.tryParse(semester.toString()) ?? 1;
    if (sem <= 2) return '1st Year';
    if (sem <= 4) return '2nd Year';
    if (sem <= 6) return '3rd Year';
    return '4th Year';
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          onPressed: _handleBackPressed,
        ),
        title: const Text(
          'Select Class',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // Main Content
                    Expanded(child: _buildContent()),

                    // Bottom Action Button
                    if (_selectedClassId != null) _buildBottomActionButton(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          _buildHeaderSection(),

          const SizedBox(height: 24),

          // Classes List
          _buildClassesList(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading Classes...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadClasses,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds header section
  Widget _buildHeaderSection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.school_rounded,
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
                        'Choose Your Class',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _classes.isEmpty
                            ? 'No classes available'
                            : '${_classes.length} ${_classes.length == 1 ? 'class' : 'classes'} available for selection',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
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

  /// Builds classes list
  Widget _buildClassesList() {
    if (_classes.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Classes (${_classes.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        ..._classes.asMap().entries.map((entry) {
          final index = entry.key;
          final classData = entry.value;

          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 400 + (index * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutBack,
            builder: (context, animationValue, child) {
              return Transform.translate(
                offset: Offset(30 * (1 - animationValue), 0),
                child: Opacity(
                  opacity: animationValue.clamp(0.0, 1.0),
                  child: _buildClassCard(classData),
                ),
              );
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.class_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Classes Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no classes assigned to you at the moment.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds individual class card
  Widget _buildClassCard(Map<String, dynamic> classData) {
    final isSelected = _selectedClassId == classData['id'];
    final cardColor = classData['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedClassId = isSelected ? null : classData['id'];
          });
          HapticFeedback.lightImpact();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? cardColor.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? cardColor : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? cardColor.withOpacity(0.15)
                    : Colors.black.withOpacity(0.05),
                blurRadius: isSelected ? 16 : 8,
                offset: const Offset(0, 3),
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
                      gradient: LinearGradient(
                        colors: [cardColor.withOpacity(0.8), cardColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: cardColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.class_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classData['degree'] ?? 'Unknown Program',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? cardColor : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildInfoChip(
                              '${classData['year']}',
                              Colors.blue.shade100,
                              Colors.blue.shade800,
                            ),
                            const SizedBox(width: 6),
                            _buildInfoChip(
                              classData['semester'],
                              Colors.green.shade100,
                              Colors.green.shade800,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Selection Indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? cardColor : Colors.grey.shade300,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? cardColor : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Subjects Information
              if (classData['api_data']['subjects'] != null)
                _buildSubjectsSection(classData['api_data']['subjects']),
              const SizedBox(height: 12),
              // Footer with student count
              Row(
                children: [
                  _buildStudentCount(classData['students_count']),
                  const Spacer(),
                  if (isSelected)
                    Text(
                      'Selected',
                      style: TextStyle(
                        color: cardColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStudentCount(int count) {
    return Row(
      children: [
        Icon(Icons.people_alt_rounded, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          '$count ${count == 1 ? 'Student' : 'Students'}',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Builds subjects section with improved component colors
  Widget _buildSubjectsSection(List<dynamic> subjects) {
    if (subjects.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: Colors.grey.shade500,
            ),
            const SizedBox(width: 8),
            Text(
              'No subjects assigned',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subjects (${subjects.length})',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: subjects.map<Widget>((subject) {
            final subjectMap = subject as Map<String, dynamic>;
            final component = subjectMap['component']?.toString() ?? 'Unknown';
            final subjectName =
                subjectMap['subject_name']?.toString() ?? 'Unknown';
            final subjectCode = subjectMap['subject_code']?.toString() ?? '';

            final bgColor = componentColors[component] ?? Colors.grey.shade600;
            final lightColor =
                componentLightColors[component] ?? Colors.grey.shade100;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: lightColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: bgColor.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: bgColor.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    subjectName.length > 20
                        ? '${subjectName.substring(0, 20)}...'
                        : subjectName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '($component)',
                    style: TextStyle(
                      fontSize: 11,
                      color: bgColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Builds bottom action button
  Widget _buildBottomActionButton() {
    final selectedClass = _classes.firstWhere(
      (c) => c['id'] == _selectedClassId,
    );
    final cardColor = selectedClass['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 500),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.elasticOut,
        builder: (context, animationValue, child) {
          return Transform.scale(
            scale: animationValue,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cardColor, cardColor.withOpacity(0.8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: cardColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _confirmSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                label: Text(
                  'Select ${selectedClass['degree']}',
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
  }

  /// Confirms class selection
  void _confirmSelection() {
    if (_selectedClassId != null) {
      final selectedClass = _classes.firstWhere(
        (c) => c['id'] == _selectedClassId,
      );

      // Return both formatted data and original API data
      Navigator.pop(context, {
        'class_id': _selectedClassId,
        'class_name': selectedClass['name'],
        'students_count': selectedClass['students_count'],
        'program': selectedClass['api_data']['program'],
        'semester': selectedClass['api_data']['semester'],
        'subjects': selectedClass['api_data']['subjects'],
        'original_data': selectedClass['api_data'],
      });
    }
  }
}
