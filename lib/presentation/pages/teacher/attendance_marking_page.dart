import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:markmeapp/data/repositories/teacher_repository.dart';

class AttendanceMarkingPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> sessionData;
  final List<XFile> images;
  final String attendanceId;

  const AttendanceMarkingPage({
    Key? key,
    required this.sessionData,
    required this.images,
    required this.attendanceId,
  }) : super(key: key);

  @override
  ConsumerState<AttendanceMarkingPage> createState() =>
      _AttendanceMarkingPageState();
}

class _AttendanceMarkingPageState extends ConsumerState<AttendanceMarkingPage>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _animationController;
  late AnimationController _headerController;
  late AnimationController _submitController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _submitScaleAnimation;

  // Face Recognition Logic
  final List<Map<String, dynamic>> _recognizedStudents = [];
  final List<String> _annotatedImages = [];
  bool _isProcessing = true;
  StreamSubscription? _streamSubscription;

  // UI State
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _attendanceMap = {};
  List<Map<String, dynamic>> _filteredStudents = [];
  bool _isSubmitting = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startFaceRecognition();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _headerController.dispose();
    _submitController.dispose();
    _searchController.dispose();
    _streamSubscription?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _submitController = AnimationController(
      duration: const Duration(milliseconds: 200),
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

    _submitScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _submitController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _headerController.forward();
  }

  // ========== FACE RECOGNITION LOGIC ==========
  Future<void> _startFaceRecognition() async {
    try {
      final teacherRepository = ref.read(teacherRepositoryProvider);
      final stream = teacherRepository.recognizeStudent(
        widget.attendanceId,
        widget.images,
      );

      _streamSubscription = stream.listen(
        (data) {
          _handleSSEData(data);
        },
        onError: (error) {
          setState(() {
            _isProcessing = false;
          });
        },
        onDone: () {
          setState(() {
            _isProcessing = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _handleSSEData(Map<String, dynamic> data) {
    print('Received SSE data: $data');

    // Handle student recognition events - FIXED TYPE CONVERSION
    if (data['student_id'] != null && data['name'] != null) {
      setState(() {
        // Convert roll_number to string to avoid type errors
        final rollNumber = data['roll_number']?.toString() ?? '';
        final studentKey = '$rollNumber:${data['name']}';

        final exists = _recognizedStudents.any(
          (student) =>
              '${student['roll_number']}:${student['name']}' == studentKey,
        );

        if (!exists) {
          final newStudent = {
            'id': data['student_id'].toString(),
            'name': data['name'].toString(),
            'roll_number': rollNumber, // Use converted string
            'confidence': data['confidence']?.toString() ?? '0',
            'student_id': data['student_id'].toString(),
          };

          _recognizedStudents.add(newStudent);
          _attendanceMap[data['student_id'].toString()] = true;
          // Update filtered list
          _filterStudents();
        }
      });
      return;
    }

    // Handle progress updates
    if (data['status'] == 'progress') {
    } else if (data['status'] == 'image_processed') {
      if (data['annotated_image_base64'] != null) {
        setState(() {
          _annotatedImages.add(data['annotated_image_base64'].toString());
        });
      }
    } else if (data['status'] == 'complete') {
      setState(() {
        _isProcessing = false;
      });
    } else if (data['status'] == 'failed') {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _handleBackPressed() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _attendanceMap.values
        .where((present) => present)
        .length;
    final totalCount = _recognizedStudents.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
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
                    // Header with total count
                    _buildHeaderSection(presentCount, totalCount),
                    // Search and filter section
                    _buildSearchAndFilterBar(),
                    // Students list
                    Expanded(child: _buildStudentsList()),
                    // Submit button
                    _buildSubmitButton(presentCount, totalCount),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
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
        'Class Attendance',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeaderSection(int presentCount, int totalCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total count: $presentCount/$totalCount',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          if (_isProcessing) ...[
            const LinearProgressIndicator(
              backgroundColor: Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              minHeight: 2,
            ),
            const SizedBox(height: 4),
            const Text(
              'Processing images...',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search students...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2563EB),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: (value) => _filterStudents(),
            ),
          ),
          const SizedBox(height: 16),
          // Filter chips
          Row(
            children: [
              _buildFilterChip('all', 'All (${_recognizedStudents.length})'),
              const SizedBox(width: 12),
              _buildFilterChip('present', 'Present '),
              const SizedBox(width: 12),
              _buildFilterChip('absent', 'Absent (0)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final isSelected = _selectedFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
        _filterStudents();
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    if (_recognizedStudents.isEmpty && !_isProcessing) {
      return _buildEmptyState();
    }

    if (_filteredStudents.isEmpty && _searchController.text.isNotEmpty) {
      return _buildNoResultsState();
    }

    return Container(
      color: const Color(0xFFF5F7FA),
      child: ListView.builder(
        itemCount: _filteredStudents.length,
        itemBuilder: (context, index) {
          final student = _filteredStudents[index];

          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 50)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutBack,
            builder: (context, animationValue, child) {
              return Transform.translate(
                offset: Offset(30 * (1 - animationValue), 0),
                child: Opacity(
                  opacity: animationValue.clamp(0.0, 1.0),
                  child: _buildStudentCard(student),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isProcessing
                ? Icons.face_retouching_natural
                : Icons.people_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _isProcessing
                ? 'Processing images...'
                : 'No students recognized yet',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!_isProcessing) ...[
            const SizedBox(height: 8),
            const Text(
              'Students will appear here once recognized',
              style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No students found',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search terms',
            style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final isPresent = _attendanceMap[student['id']] ?? false;
    final confidence = student['confidence'] ?? '0';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF1F5F9),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: const Icon(Icons.person, size: 20, color: Color(0xFF64748B)),
        ),
        title: Text(
          student['name']?.toString() ?? 'Unknown',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              "ID: ${student['roll_number']?.toString() ?? ''}",
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$confidence%',
              style: TextStyle(
                fontSize: 12,
                color: _getConfidenceColor(double.tryParse(confidence) ?? 0),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPresent
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            isPresent ? 'Present' : 'Absent',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        onTap: () => _toggleAttendance(student['id']),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return const Color(0xFF10B981);
    if (confidence >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Widget _buildSubmitButton(int presentCount, int totalCount) {
    final hasMarkedAttendance = presentCount > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _submitController,
        builder: (context, child) {
          return Transform.scale(
            scale: _submitScaleAnimation.value,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: hasMarkedAttendance && !_isSubmitting
                    ? _submitAttendance
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Attendance',
                        style: TextStyle(
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

  void _toggleAttendance(String studentId) {
    setState(() {
      _attendanceMap[studentId] = !(_attendanceMap[studentId] ?? false);
    });

    HapticFeedback.lightImpact();
    _filterStudents();
  }

  void _filterStudents() {
    setState(() {
      _filteredStudents = _recognizedStudents.where((student) {
        final searchQuery = _searchController.text.toLowerCase();

        // Safe string conversion for search
        final studentName = student['name']?.toString().toLowerCase() ?? '';
        final studentRoll =
            student['roll_number']?.toString().toLowerCase() ?? '';

        final matchesSearch =
            searchQuery.isEmpty ||
            studentName.contains(searchQuery) ||
            studentRoll.contains(searchQuery);

        final isPresent = _attendanceMap[student['id']] ?? false;
        final matchesFilter =
            _selectedFilter == 'all' ||
            (_selectedFilter == 'present' && isPresent) ||
            (_selectedFilter == 'absent' && !isPresent);

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _submitAttendance() async {
    if (_isSubmitting) return;

    _submitController.forward().then((_) => _submitController.reverse());

    setState(() {
      _isSubmitting = true;
    });

    HapticFeedback.mediumImpact();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Attendance submitted successfully!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          context.pop();
        }
      });
    }
  }
}
