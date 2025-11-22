import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/data/repositories/teacher_repository.dart';
import 'package:debounce_throttle/debounce_throttle.dart';

class StudentSelectionPage extends ConsumerStatefulWidget {
  const StudentSelectionPage({Key? key}) : super(key: key);

  @override
  ConsumerState<StudentSelectionPage> createState() =>
      _StudentSelectionPageState();
}

class _StudentSelectionPageState extends ConsumerState<StudentSelectionPage> {
  // Controllers & State
  final TextEditingController _searchController = TextEditingController();
  final Debouncer<String> _searchDebouncer = Debouncer<String>(
    const Duration(milliseconds: 500),
    initialValue: '',
  );

  final Set<String> _selectedStudentIds = {};
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _displayedStudents = [];

  // Filters
  String? _selectedProgram;
  int? _selectedBatchYear;
  int? _selectedSemester;

  // Pagination
  int _currentPage = 1;
  final int _limit = 10;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isInitialLoad = true;
  bool _isLoading = false;
  String _errorMessage = '';

  final ScrollController _scrollController = ScrollController();

  // Static filter options
  final List<String> _programs = ['BTECH', 'MTECH'];
  final List<int> _batchYears = [2025, 2024];
  final List<int> _semesters = [1, 2, 3, 4, 5, 6, 7, 8];

  @override
  void initState() {
    super.initState();
    _setupSearchDebouncer();
    _setupScrollController();
    _loadStudents(reset: true);
    _loadPreviouslySelectedStudents();
  }

  void _setupSearchDebouncer() {
    _searchDebouncer.values.listen((_) => _loadStudents(reset: true));
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMore &&
          !_isInitialLoad &&
          !_isLoading) {
        _loadMoreStudents();
      }
    });
  }

  // Load previously selected students from storage or previous session
  void _loadPreviouslySelectedStudents() {
    // You can replace this with your actual storage solution
    // For now, we'll use a simple example
    // In a real app, you might use SharedPreferences, Hive, or pass data via route parameters
    try {
      // Example: Load from shared preferences or previous state
      // final prefs = await SharedPreferences.getInstance();
      // final selectedIds = prefs.getStringList('selected_student_ids');
      // if (selectedIds != null) {
      //   setState(() {
      //     _selectedStudentIds.addAll(selectedIds);
      //   });
      // }

      // Alternative: Pass selected students via route arguments
      // final args = ModalRoute.of(context)?.settings.arguments;
      // if (args is Map && args.containsKey('preselected_students')) {
      //   final preselected = List<String>.from(args['preselected_students']);
      //   setState(() {
      //     _selectedStudentIds.addAll(preselected);
      //   });
      // }
    } catch (e) {
      print('Error loading previously selected students: $e');
    }
  }

  Future<void> _loadStudents({bool reset = false}) async {
    if (reset) {
      setState(() {
        _students = [];
        _displayedStudents = [];
        _currentPage = 1;
        _hasMore = true;
        _errorMessage = '';
        _isInitialLoad = true;
      });
    }

    if (_isLoading) return; // prevent duplicate calls

    setState(() => _isLoading = true);

    try {
      final teacherRepo = ref.read(teacherRepositoryProvider);
      final result = await teacherRepo.fetchStudentsForNotification(
        _currentPage,
        _limit,
        _selectedBatchYear,
        _selectedProgram,
        _searchController.text.isEmpty ? null : _searchController.text,
        _selectedSemester,
      );

      final List<Map<String, dynamic>> fetched =
          List<Map<String, dynamic>>.from(result['data'] ?? []);
      final transformed = _transformStudentData(fetched);

      setState(() {
        if (reset) {
          _students = transformed;
        } else {
          _students.addAll(transformed);
        }

        _applyLocalFilters();
        final total = result['total'] ?? 0;
        _hasMore = _students.length < total;
        _isInitialLoad = false;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch students';
        _isInitialLoad = false;
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreStudents() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;
    await _loadStudents(reset: false);
  }

  void _applyLocalFilters() {
    _displayedStudents = _students.where((student) {
      bool matchesProgram =
          _selectedProgram == null || student['degree'] == _selectedProgram;
      bool matchesBatch =
          _selectedBatchYear == null ||
          student['batch_year'] == _selectedBatchYear;
      bool matchesSemester =
          _selectedSemester == null || student['semester'] == _selectedSemester;
      return matchesProgram && matchesBatch && matchesSemester;
    }).toList();
  }

  List<Map<String, dynamic>> _transformStudentData(
    List<Map<String, dynamic>> data,
  ) {
    return data.map((student) {
      final fn = student['first_name'] ?? '';
      final mn = student['middle_name'] ?? '';
      final ln = student['last_name'] ?? '';

      String fullName = fn.trim();
      if (mn.trim().isNotEmpty) fullName += ' $mn';
      if (ln.trim().isNotEmpty) fullName += ' $ln';
      fullName = fullName.trim();

      return {
        'id': student['student_id'],
        'name': fullName,
        'roll_number': student['roll_number'].toString(),
        'degree': student['program'],
        'year': student['semester'],
        'batch_year': student['batch_year'],
        'semester': student['semester'],
        'profile_picture': student['profile_picture'],
        'email': student['email'] ?? '',
      };
    }).toList();
  }

  void _handleBackPressed() {
    context.pop("/teacher/push-notification");
  }

  void _applyFilters() {
    _loadStudents(reset: true);
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedProgram = null;
      _selectedBatchYear = null;
      _selectedSemester = null;
    });
    _loadStudents(reset: true);
  }

  bool _hasActiveFilters() {
    return _selectedProgram != null ||
        _selectedBatchYear != null ||
        _selectedSemester != null ||
        _searchController.text.isNotEmpty;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
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
          onPressed: _isLoading ? null : _handleBackPressed,
        ),
        title: const Text(
          'Add Students',
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
            _buildSearchBar(),
            _buildFiltersSection(),
            Expanded(child: _buildContent()),
            if (_selectedStudentIds.isNotEmpty) _buildBottomActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
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
        child: TextField(
          controller: _searchController,
          onChanged: (txt) => _searchDebouncer.value = txt,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Search by name or roll number...',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.blue.shade400,
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _loadStudents(reset: true);
                    },
                  )
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
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.white,
      child: Column(
        children: [
          // Filter Header
          Row(
            children: [
              if (_hasActiveFilters())
                GestureDetector(
                  onTap: _clearFilters,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.clear_all,
                          color: Colors.grey.shade600,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Clear All',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Filter Dropdowns
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterDropdown(
                  value: _selectedProgram,
                  hint: "Select Program",
                  label: "Program",
                  items: _programs,
                  icon: Icons.school_outlined,
                  onChanged: (v) {
                    setState(() => _selectedProgram = v);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 12),
                _buildFilterDropdown(
                  value: _selectedBatchYear?.toString(),
                  hint: "Select Batch",
                  label: "Batch Year",
                  items: _batchYears.map((e) => e.toString()).toList(),
                  icon: Icons.calendar_today_outlined,
                  onChanged: (v) {
                    setState(
                      () =>
                          _selectedBatchYear = v != null ? int.parse(v) : null,
                    );
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 12),
                _buildFilterDropdown(
                  value: _selectedSemester?.toString(),
                  hint: "Select Semester",
                  label: "Semester",
                  items: _semesters.map((e) => e.toString()).toList(),
                  icon: Icons.library_books_outlined,
                  onChanged: (v) {
                    setState(
                      () => _selectedSemester = v != null ? int.parse(v) : null,
                    );
                    _applyFilters();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String? value,
    required String hint,
    required String label,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(
                        hint,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('All Programs'),
                    ),
                  ),
                  ...items.map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(item),
                      ),
                    ),
                  ),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isInitialLoad) return _buildSkeletonLoading();
    if (_errorMessage.isNotEmpty) return _buildErrorState();
    if (_displayedStudents.isEmpty) return _buildEmptyState();
    return _buildStudentsList();
  }

  Widget _buildStudentsList() {
    return RefreshIndicator(
      onRefresh: () => _loadStudents(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: _displayedStudents.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _displayedStudents.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final student = _displayedStudents[index];
          final isSelected = _selectedStudentIds.contains(student['id']);

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedStudentIds.remove(student['id']);
                } else {
                  _selectedStudentIds.add(student['id']);
                }
              });
              HapticFeedback.lightImpact();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Colors.blue.shade600
                      : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: student['profile_picture'] != null
                        ? NetworkImage(student['profile_picture'])
                        : null,
                    child: student['profile_picture'] == null
                        ? Icon(
                            Icons.person,
                            size: 24,
                            color: Colors.grey.shade600,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.blue.shade600
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Roll: ${student['roll_number']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${student['degree']} • Semester ${student['semester']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.shade600
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue.shade600
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: 10,
      itemBuilder: (_, __) => Container(
        height: 70,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
          const SizedBox(height: 16),
          const Text(
            "Failed to load students",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _loadStudents(reset: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
            label: const Text(
              "Try Again",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
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
          Icon(Icons.people_outline, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            "No students found",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "Try adjusting your search or filters",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          if (_hasActiveFilters())
            ElevatedButton.icon(
              onPressed: _clearFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.clear_all, color: Colors.white, size: 18),
              label: const Text(
                "Clear Filters",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton.icon(
          onPressed: _confirmSelection,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.check, color: Colors.white, size: 20),
          label: Text(
            'Select ${_selectedStudentIds.length} Student${_selectedStudentIds.length == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _confirmSelection() {
    final selectedStudents = _displayedStudents
        .where((s) => _selectedStudentIds.contains(s['id']))
        .toList();

    // Save selected students to storage (optional)
    // _saveSelectedStudents();

    context.pop({
      'count': _selectedStudentIds.length,
      'student_ids': _selectedStudentIds.toList(),
      'students': selectedStudents,
    });
  }

  // Optional: Save selected students to persistent storage
  // void _saveSelectedStudents() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setStringList('selected_student_ids', _selectedStudentIds.toList());
  //   } catch (e) {
  //     print('Error saving selected students: $e');
  //   }
  // }
}
