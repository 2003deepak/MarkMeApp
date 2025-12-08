import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/data/models/student_model.dart';
import 'package:markmeapp/data/repositories/clerk_repository.dart';

class StudentListPage extends ConsumerStatefulWidget {
  const StudentListPage({super.key});

  @override
  ConsumerState<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends ConsumerState<StudentListPage> {
  final TextEditingController _searchController = TextEditingController();
  late final ClerkRepository _clerkRepo;

  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isFirstLoad = true;

  // Filter variables
  String? _selectedBatchYear = '2025';
  String? _selectedProgram = 'MCA';
  String? _selectedSemester = '2';
  String? _selectedFaceRegistration;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _limit = 10;
  bool _isLoadingMore = false;

  int _totalStudents = 0;

  @override
  void initState() {
    super.initState();
    _clerkRepo = ref.read(clerkRepositoryProvider);
    _searchController.addListener(_debounceSearch);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isFirstLoad) {
      _isFirstLoad = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchStudents();
      });
    }
  }

  final _searchDebounce = Duration(milliseconds: 800);
  Timer? _debounceTimer;

  void _debounceSearch() {
    if (_debounceTimer != null) {
      _debounceTimer!.cancel();
    }

    _debounceTimer = Timer(_searchDebounce, () {
      _fetchStudents();
    });
  }

  Future<void> _fetchStudents({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      _currentPage = 1;
      _students.clear();
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final result = await _clerkRepo.fetchStudents(
        batchYear:
            (_selectedBatchYear != null && _selectedBatchYear!.isNotEmpty)
            ? int.tryParse(_selectedBatchYear!)
            : null,

        program: (_selectedProgram != null && _selectedProgram!.isNotEmpty)
            ? _selectedProgram
            : null,

        semester: (_selectedSemester != null && _selectedSemester!.isNotEmpty)
            ? int.tryParse(_selectedSemester!)
            : null,

        mode: 'student_listing',
        search: _searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : null,
        page: _currentPage,
        limit: _limit,
      );

      if (result['success'] == true) {
        final List<dynamic> data = result['data'] ?? [];

        if (loadMore) {
          // Append new data
          final newStudents = data.map((e) => Student.fromJson(e)).toList();
          setState(() {
            _students.addAll(newStudents);
            _hasMoreData = result['has_next'] == true;
          });
        } else {
          // Replace data
          setState(() {
            _students = data.map((e) => Student.fromJson(e)).toList();
            _totalStudents = result['total'] ?? data.length;
            _hasMoreData = result['has_next'] == true;
          });
        }

        _filterStudents();
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to load students';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _filterStudents() {
    String searchText = _searchController.text.toLowerCase().trim();

    List<Student> filtered = _students.where((student) {
      bool matchesSearch =
          searchText.isEmpty ||
          student.firstName.toLowerCase().contains(searchText) ||
          student.lastName.toLowerCase().contains(searchText) ||
          student.email.toLowerCase().contains(searchText) ||
          student.rollNumber.toString().contains(searchText);

      bool matchesFaceFilter = true;
      if (_selectedFaceRegistration != null) {
        if (_selectedFaceRegistration == 'Registered') {
          matchesFaceFilter = student.isEmbeddings == true;
        } else if (_selectedFaceRegistration == 'Pending') {
          matchesFaceFilter = student.isEmbeddings == false;
        }
      }

      return matchesSearch && matchesFaceFilter;
    }).toList();

    setState(() {
      _filteredStudents = filtered;
    });
  }

  void _loadMoreData() {
    if (_hasMoreData && !_isLoadingMore) {
      _currentPage++;
      _fetchStudents(loadMore: true);
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        currentBatchYear: _selectedBatchYear,
        currentProgram: _selectedProgram,
        currentSemester: _selectedSemester,
        currentFaceRegistration: _selectedFaceRegistration,
        onApply: (batchYear, program, semester, faceRegistration) {
          setState(() {
            _selectedBatchYear = batchYear;
            _selectedProgram = program;
            _selectedSemester = semester;
            _selectedFaceRegistration = faceRegistration;
          });
          _fetchStudents();
        },
        onReset: () {
          setState(() {
            _selectedBatchYear = '2025';
            _selectedProgram = 'MCA';
            _selectedSemester = '2';
            _selectedFaceRegistration = null;
          });
          _fetchStudents();
        },
      ),
    );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedBatchYear != '2025') count++;
    if (_selectedProgram != 'MCA') count++;
    if (_selectedSemester != '2') count++;
    if (_selectedFaceRegistration != null) count++;
    return count;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF3B5BDB);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Text(
                  'Student List',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),

          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF252542)
                    : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE9ECEF),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Search students by name, email, or roll number...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        onPressed: _showFilterBottomSheet,
                        icon: Icon(
                          Icons.tune,
                          color: isDark ? Colors.white70 : primaryColor,
                        ),
                      ),
                      if (_activeFilterCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF3B5BDB),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$_activeFilterCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Error Message
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _errorMessage = '';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Filter Summary
          if (_activeFilterCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft, // <-- force alignment to left
                child: Wrap(
                  spacing: 8, // <-- chips spacing
                  runSpacing: 8,
                  children: [
                    if (_selectedBatchYear != null &&
                        _selectedBatchYear != '2025')
                      _buildFilterChip(
                        label: 'Batch: $_selectedBatchYear',
                        onRemove: () {
                          setState(() {
                            _selectedBatchYear = '2025';
                          });
                          _fetchStudents();
                        },
                        isDark: isDark,
                      ),

                    if (_selectedProgram != null && _selectedProgram != 'MCA')
                      _buildFilterChip(
                        label: 'Program: $_selectedProgram',
                        onRemove: () {
                          setState(() {
                            _selectedProgram = 'MCA';
                          });
                          _fetchStudents();
                        },
                        isDark: isDark,
                      ),

                    if (_selectedSemester != null && _selectedSemester != '2')
                      _buildFilterChip(
                        label: 'Semester: $_selectedSemester',
                        onRemove: () {
                          setState(() {
                            _selectedSemester = '2';
                          });
                          _fetchStudents();
                        },
                        isDark: isDark,
                      ),

                    if (_selectedFaceRegistration != null)
                      _buildFilterChip(
                        label: 'Face: $_selectedFaceRegistration',
                        onRemove: () {
                          setState(() {
                            _selectedFaceRegistration = null;
                          });
                          _fetchStudents();
                        },
                        isDark: isDark,
                      ),
                  ],
                ),
              ),
            ),

          // Student Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '$_totalStudents student  found',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Student List
          Expanded(
            child: _isLoading && !_isLoadingMore
                ? const Center(child: CircularProgressIndicator())
                : _filteredStudents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: isDark ? Colors.white30 : Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No students found',
                          style: TextStyle(
                            fontSize: 18,
                            color: isDark ? Colors.white70 : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters or search',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await _fetchStudents();
                    },
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        if (!_isLoadingMore &&
                            _hasMoreData &&
                            scrollInfo.metrics.pixels ==
                                scrollInfo.metrics.maxScrollExtent) {
                          _loadMoreData();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount:
                            _filteredStudents.length +
                            (_isLoadingMore ? 1 : 0) +
                            (_hasMoreData ? 0 : 1),
                        itemBuilder: (context, index) {
                          if (index == _filteredStudents.length) {
                            if (_isLoadingMore) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            }

                            return const SizedBox();
                          }

                          return StudentCard(
                            student: _filteredStudents[index],
                            isDark: isDark,
                            onRefresh: () {
                              _fetchStudents();
                            },
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onRemove,
    required bool isDark,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onRemove, // <-- remove filter on any tap
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF3B5BDB).withValues(alpha: 0.2)
              : const Color(0xFF3B5BDB).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF3B5BDB).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF3B5BDB)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.close, size: 14, color: Color(0xFF3B5BDB)),
          ],
        ),
      ),
    );
  }
}

// Student Card Widget
class StudentCard extends StatelessWidget {
  final Student student;
  final bool isDark;
  final VoidCallback onRefresh;

  const StudentCard({
    super.key,
    required this.student,
    required this.isDark,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColor = _getAvatarColor(student.firstName);
    final fullName = '${student.firstName} ${student.lastName}'.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252542) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFF1F3F4),
        ),
      ),
      child: Row(
        children: [
          // Profile Picture or Avatar
          if (student.profilePicture != null &&
              student.profilePicture!.isNotEmpty)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(student.profilePicture!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: avatarColor.withValues(alpha: isDark ? 0.3 : 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getInitials(fullName),
                  style: TextStyle(
                    color: avatarColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

          const SizedBox(width: 16),

          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Roll No: ${student.rollNumber}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF3B5BDB),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  student.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildInfoChip(label: student.department, isDark: isDark),
                    _buildInfoChip(
                      label: 'Sem ${student.semester}',
                      isDark: isDark,
                    ),
                    _buildInfoChip(
                      label: 'Batch ${student.batchYear}',
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Face Registration Status
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    student.isEmbeddings
                        ? 'Face is registered'
                        : 'Face not registered yet',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Tooltip(
              message: student.isEmbeddings
                  ? 'Face Registered'
                  : 'Face Not Registered',
              triggerMode: TooltipTriggerMode.tap, // <-- IMPORTANT for mobile
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: student.isEmbeddings
                      ? const Color(0xFFD4EDDA)
                      : const Color(0xFFFFF3BF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  student.isEmbeddings
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  color: student.isEmbeddings
                      ? const Color(0xFF28A745)
                      : const Color(0xFFF59F00),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required String label, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: isDark ? Colors.white70 : Colors.grey[700],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return '?';
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF3B5BDB), // Blue
      const Color(0xFFF59F00), // Orange
      const Color(0xFF37B24D), // Green
      const Color(0xFFF03E3E), // Red
      const Color(0xFF7048E8), // Purple
      const Color(0xFF0CA678), // Teal
    ];

    final hash = name.codeUnits.fold(0, (a, b) => a + b);
    return colors[hash % colors.length];
  }
}

// Filter Bottom Sheet
class FilterBottomSheet extends StatefulWidget {
  final String? currentBatchYear;
  final String? currentProgram;
  final String? currentSemester;
  final String? currentFaceRegistration;
  final Function(String?, String?, String?, String?) onApply;
  final VoidCallback onReset;

  const FilterBottomSheet({
    super.key,
    required this.currentBatchYear,
    required this.currentProgram,
    required this.currentSemester,
    required this.currentFaceRegistration,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? _batchYear;
  late String? _program;
  late String? _semester;
  late String? _faceRegistration;

  @override
  void initState() {
    super.initState();
    _batchYear = widget.currentBatchYear ?? '2025';
    _program = widget.currentProgram ?? 'MCA';
    _semester = widget.currentSemester ?? '2';
    _faceRegistration = widget.currentFaceRegistration;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Students',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Batch Year
                  _buildLabel('Batch Year', isDark),
                  _buildDropdown(
                    value: _batchYear,
                    items: const ['2022', '2023', '2024', '2025', '2026'],
                    onChanged: (v) => setState(() => _batchYear = v),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),

                  // Program
                  _buildLabel('Program', isDark),
                  _buildDropdown(
                    value: _program,
                    items: const ['MCA', 'MBA', 'BBA', 'BCOM', 'BTECH'],
                    onChanged: (v) => setState(() => _program = v),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),

                  // Semester
                  _buildLabel('Semester', isDark),
                  _buildDropdown(
                    value: _semester,
                    items: const ['1', '2', '3', '4', '5', '6', '7', '8'],
                    onChanged: (v) => setState(() => _semester = v),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),

                  // Face Registration Status
                  _buildLabel('Face Registration', isDark),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildToggleButton(
                        label: 'Registered',
                        isSelected: _faceRegistration == 'Registered',
                        onTap: () => setState(() {
                          _faceRegistration = _faceRegistration == 'Registered'
                              ? null
                              : 'Registered';
                        }),
                        isDark: isDark,
                      ),
                      _buildToggleButton(
                        label: 'Pending',
                        isSelected: _faceRegistration == 'Pending',
                        onTap: () => setState(() {
                          _faceRegistration = _faceRegistration == 'Pending'
                              ? null
                              : 'Pending';
                        }),
                        isDark: isDark,
                      ),
                      _buildToggleButton(
                        label: 'All',
                        isSelected: _faceRegistration == null,
                        onTap: () => setState(() {
                          _faceRegistration = null;
                        }),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _batchYear = '2025';
                        _program = 'MCA';
                        _semester = '2';
                        _faceRegistration = null;
                      });
                      widget.onReset();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3B5BDB),
                      side: const BorderSide(color: Color(0xFF3B5BDB)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(
                        _batchYear,
                        _program,
                        _semester,
                        _faceRegistration,
                      );
                      // Close Modal
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B5BDB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white70 : Colors.black54,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252542) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE9ECEF),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: isDark ? Colors.white38 : Colors.grey,
          ),
          dropdownColor: isDark ? const Color(0xFF252542) : Colors.white,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final primaryColor = const Color(0xFF3B5BDB);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark ? const Color(0xFF252542) : Colors.white),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? Colors.white24 : const Color(0xFFE9ECEF)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black54),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
