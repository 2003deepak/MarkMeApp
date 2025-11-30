import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:markmeapp/data/repositories/teacher_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  // Animation Controllers (only for initial page load)
  late AnimationController _animationController;
  late AnimationController _headerController;
  late AnimationController _submitController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _submitScaleAnimation;

  // Student Data
  final List<Map<String, dynamic>> _allStudents = [];
  final List<Map<String, dynamic>> _recognizedStudents = [];
  final List<String> _annotatedImages = [];
  bool _isProcessing = true;
  bool _isLoadingStudents = true;
  StreamSubscription? _streamSubscription;

  // UI State
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _attendanceMap = {};
  List<Map<String, dynamic>> _filteredStudents = [];
  bool _isSubmitting = false;
  String _selectedFilter = 'all';

  // BitString state
  String _attendanceBitString = '';

  TeacherRepository get teacherRepository =>
      ref.read(teacherRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAllStudents();
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

  void _generatePresentAbsentLists() {
    final present = <String>[];
    final absent = <String>[];

    _allStudents.forEach((student) {
      final id = student['id']!;
      final isPresent = _attendanceMap[id] ?? false;

      if (isPresent) {
        present.add(id);
      } else {
        absent.add(id);
      }
    });

    print("🎯 Present IDs: $present");
    print("🎯 Absent IDs:  $absent");

    // Attach to state
    widget.sessionData['present_students'] = present;
    widget.sessionData['absent_students'] = absent;
  }

  // ========== LOAD ALL STUDENTS ==========
  Future<void> _loadAllStudents() async {
    try {
      final batchYear = int.tryParse(
        widget.sessionData['academic_year'].toString(),
      );
      final program = widget.sessionData['program']?.toString();
      final semester = int.tryParse(widget.sessionData['semester'].toString());

      if (batchYear == null || program == null || semester == null) {
        print("❌ sessionData incomplete: $batchYear, $program, $semester");
        setState(() => _isLoadingStudents = false);
        return;
      }

      print("📌 Fetching students for $batchYear $program Sem-$semester");

      final result = await teacherRepository.fetchStudentsForAttendance(
        batchYear: batchYear,
        program: program,
        semester: semester,
      );

      if (result['success'] == true) {
        final studentsData = List<Map<String, dynamic>>.from(
          result['data'] ?? [],
        );

        setState(() {
          _allStudents.clear();
          _attendanceMap.clear();
          _recognizedStudents.clear();

          for (final student in studentsData) {
            final studentId = student['_id']?.toString() ?? '';
            final studentData = {
              'id': studentId,
              'name':
                  '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'
                      .trim(),
              'roll_number': student['roll_number']?.toString() ?? '',
              'confidence': '0',
              'profile_image': (student['profile_picture'] ?? '')
                  .toString()
                  .trim(),

              'student_id': studentId,
              'is_recognized': false,
            };

            _allStudents.add(studentData);
            _attendanceMap[studentId] = false; // mark absent default
          }

          _isLoadingStudents = false;
          _filterStudents();
          _generateAttendanceBitString(); // Generate initial bitstring
        });
      } else {
        setState(() => _isLoadingStudents = false);
        print('Error loading students: ${result['error']}');
      }
    } catch (e) {
      setState(() => _isLoadingStudents = false);
      print('Exception loading students: $e');
    }
  }

  // ========== FACE RECOGNITION LOGIC ==========
  Future<void> _startFaceRecognition() async {
    try {
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

    // Handle student recognition events
    if (data['student_id'] != null && data['name'] != null) {
      setState(() {
        final recognizedStudentId = data['student_id'].toString();
        final rollNumber = data['roll_number']?.toString() ?? '';
        final confidence = data['confidence']?.toString() ?? '0';

        // Find if this student exists in allStudents list
        final existingStudentIndex = _allStudents.indexWhere(
          (student) => student['id'] == recognizedStudentId,
        );

        if (existingStudentIndex != -1) {
          // Update existing student with recognition data
          _allStudents[existingStudentIndex] = {
            ..._allStudents[existingStudentIndex],
            'confidence': confidence,
            'is_recognized': true,
          };

          // Mark as present when recognized
          _attendanceMap[recognizedStudentId] = true;

          // Add to recognized students list if not already there
          final existsInRecognized = _recognizedStudents.any(
            (student) => student['id'] == recognizedStudentId,
          );

          if (!existsInRecognized) {
            _recognizedStudents.add(_allStudents[existingStudentIndex]);
          }
        } else {
          // Create new student entry (in case of unexpected student)
          final newStudent = {
            'id': recognizedStudentId,
            'name': data['name'].toString(),
            'roll_number': rollNumber,
            'confidence': confidence,
            'profile_image': '', // No profile image for unexpected students
            'student_id': recognizedStudentId,
            'is_recognized': true,
          };

          _allStudents.add(newStudent);
          _recognizedStudents.add(newStudent);
          _attendanceMap[recognizedStudentId] = true;
        }

        // Update filtered list and regenerate bitstring
        _filterStudents();
        _generateAttendanceBitString();
      });
      return;
    }

    // Handle progress updates
    if (data['status'] == 'progress') {
      // Progress update handling
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

  // ========== BITSTRING GENERATION ==========
  void _generateAttendanceBitString() {
    if (_allStudents.isEmpty) {
      setState(() {
        _attendanceBitString = '';
      });
      return;
    }

    // Sort students by roll number to ensure consistent ordering
    final sortedStudents = List<Map<String, dynamic>>.from(_allStudents)
      ..sort((a, b) {
        final rollA = a['roll_number']?.toString() ?? '';
        final rollB = b['roll_number']?.toString() ?? '';
        return rollA.compareTo(rollB);
      });

    // Generate bitstring: 1 for present, 0 for absent
    final bitString = StringBuffer();
    for (final student in sortedStudents) {
      final studentId = student['id'] ?? '';
      final isPresent = _attendanceMap[studentId] ?? false;
      bitString.write(isPresent ? '1' : '0');
    }

    setState(() {
      _attendanceBitString = bitString.toString();
    });

    print('📊 Generated BitString: $_attendanceBitString');
    print('📊 Total Students: ${sortedStudents.length}');
    print(
      '📊 Present Count: ${_attendanceMap.values.where((present) => present).length}',
    );

    // Print roll numbers with attendance status for verification
    for (int i = 0; i < sortedStudents.length; i++) {
      final student = sortedStudents[i];
      final status = _attendanceBitString[i];
      print(
        '🎯 Roll: ${student['roll_number']} - ${status == '1' ? 'Present' : 'Absent'}',
      );
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
    final totalCount = _allStudents.length;
    final absentCount = totalCount - presentCount;

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
                    // Search and filter section
                    _buildSearchAndFilterBar(presentCount, absentCount),
                    // Header with total count and bitstring
                    _buildHeaderSection(presentCount, totalCount),
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
      backgroundColor: const Color(0xFF2563EB),
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
        'Mark Attendance',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
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

          if (_isLoadingStudents) ...[
            const LinearProgressIndicator(
              backgroundColor: Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              minHeight: 2,
            ),
            const SizedBox(height: 4),
            const Text(
              'Loading students...',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ] else if (_isProcessing) ...[
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

  Widget _buildSearchAndFilterBar(int presentCount, int absentCount) {
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
              _buildFilterChip('all', 'All (${_allStudents.length})'),
              const SizedBox(width: 12),
              _buildFilterChip('present', 'Present ($presentCount)'),
              const SizedBox(width: 12),
              _buildFilterChip('absent', 'Absent ($absentCount)'),
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
    if (_isLoadingStudents) {
      return _buildLoadingState();
    }

    if (_allStudents.isEmpty) {
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
          return _buildStudentCard(student);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF2563EB)),
          const SizedBox(height: 16),
          const Text(
            'Loading students...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
            _isLoadingStudents ? 'Loading students...' : 'No students found',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!_isLoadingStudents) ...[
            const SizedBox(height: 8),
            const Text(
              'No students registered for this class',
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
    final isRecognized = student['is_recognized'] ?? false;
    final profileImage = student['profile_image']?.toString().trim() ?? '';

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
        leading: _buildProfileImage(profileImage, isRecognized),
        title: Text(
          student['name']?.toString() ?? 'Unknown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
            fontStyle: FontStyle.normal,
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
            if (isRecognized)
              Text(
                'Confidence :- $confidence%',
                style: TextStyle(
                  fontSize: 12,
                  color: _getConfidenceColor(double.tryParse(confidence) ?? 0),
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              const Text(
                'Absent',
                style: TextStyle(
                  fontSize: 12,
                  color: Color.fromARGB(255, 192, 32, 32),
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

  Widget _buildProfileImage(String profileImageUrl, bool isRecognized) {
    if (profileImageUrl.isNotEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isRecognized
                ? const Color(0xFF10B981)
                : const Color(0xFFE2E8F0),
            width: isRecognized ? 2 : 1,
          ),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: profileImageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: const Color(0xFFF1F5F9),
              child: const Icon(
                Icons.person,
                size: 20,
                color: Color(0xFF64748B),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: const Color(0xFFF1F5F9),
              child: const Icon(
                Icons.person,
                size: 20,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ),
      );
    } else {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF1F5F9),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Icon(Icons.person, size: 20, color: const Color(0xFF64748B)),
      );
    }
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
    _generateAttendanceBitString(); // Regenerate bitstring when attendance changes
  }

  void _filterStudents() {
    setState(() {
      _filteredStudents = _allStudents.where((student) {
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

    // Generate present & absent lists
    _generatePresentAbsentLists();

    // Include the bitstring in your submission if needed
    print('🎯 Submitting attendance with bitstring: $_attendanceBitString');

    final resp = await teacherRepository.saveAttendance(
      widget.attendanceId,
      _attendanceBitString,
      widget.sessionData['present_students'],
      widget.sessionData['absent_students'],
    );

    if (resp['success'] != true) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  resp['message']?.toString() ?? 'Failed to submit attendance',
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(resp['message']?.toString() ?? 'Attendance submitted'),
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

        // Navigate back after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.pop();
          }
        });
      }
    }
  }
}
