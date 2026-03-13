import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/data/repositories/teacher_repository.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';
import 'package:markmeapp/presentation/widgets/ui/custom_bottom_sheet_layout.dart';
import 'package:markmeapp/presentation/widgets/ui/filter_chip.dart';
import 'package:markmeapp/presentation/widgets/ui/search_bar.dart';
import 'package:markmeapp/state/teacher_state.dart';
import 'package:markmeapp/data/models/teacher_model.dart';
import 'package:markmeapp/presentation/widgets/ui/dropdown.dart' as ui;

class StudentSelectionPage extends ConsumerStatefulWidget {
  const StudentSelectionPage({super.key});

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
  final List<String> _programs = ['MCA', 'AI'];
  final List<int> _batchYears = [2025, 2024];
  final List<int> _semesters = [1, 2, 3, 4, 5, 6, 7, 8];

  @override
  void initState() {
    super.initState();
    _setupSearchDebouncer();
    _setupScrollController();
    _loadStudents(reset: true);
    
    // Fetch teacher profile if not loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(teacherStoreProvider).profile == null) {
        ref.read(teacherStoreProvider.notifier).loadProfile();
      }
    });
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

    if (_isLoading) return;
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        currentBatchYear: _selectedBatchYear?.toString(),
        currentProgram: _selectedProgram,
        currentSemester: _selectedSemester?.toString(),
        onApply: (batchYear, program, semester) {
          setState(() {
            _selectedBatchYear = batchYear != null ? int.tryParse(batchYear) : null;
            _selectedProgram = program;
            _selectedSemester = semester != null ? int.tryParse(semester) : null;
          });
          _loadStudents(reset: true);
        },
        onReset: () {
          setState(() {
            _selectedBatchYear = null;
            _selectedProgram = null;
            _selectedSemester = null;
          });
          _loadStudents(reset: true);
        },
      ),
    );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedProgram != null) count++;
    if (_selectedBatchYear != null) count++;
    if (_selectedSemester != null) count++;
    return count;
  }

  bool _hasActiveFilters() {
    return _selectedProgram != null ||
        _selectedBatchYear != null ||
        _selectedSemester != null;
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
      appBar: MarkMeAppBar(
        title: 'Add Students',
        onBackPressed: _isLoading ? null : _handleBackPressed,
        isLoading: _isLoading,
      ),
      body: SafeArea(
        child: Column(
          children: [
            AppSearchBar(
              controller: _searchController,
              hintText: 'Search by name or roll number...',
              onChanged: (txt) => _searchDebouncer.value = txt,
              onFilterTap: _showFilterBottomSheet,
              activeFilterCount: _activeFilterCount,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            _buildFiltersSection(),
            Expanded(child: _buildContent()),
            if (_selectedStudentIds.isNotEmpty) _buildBottomActionButton(),
          ],
        ),
      ),
    );
  }


  Widget _buildFiltersSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        if (_activeFilterCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_selectedProgram != null)
                    FilterChipWidget(
                      label: 'Program: $_selectedProgram',
                      onRemove: () {
                        setState(() => _selectedProgram = null);
                        _loadStudents(reset: true);
                      },
                      isDark: isDark,
                    ),
                  if (_selectedBatchYear != null)
                    FilterChipWidget(
                      label: 'Batch: $_selectedBatchYear',
                      onRemove: () {
                        setState(() => _selectedBatchYear = null);
                        _loadStudents(reset: true);
                      },
                      isDark: isDark,
                    ),
                  if (_selectedSemester != null)
                    FilterChipWidget(
                      label: 'Semester: $_selectedSemester',
                      onRemove: () {
                        setState(() => _selectedSemester = null);
                        _loadStudents(reset: true);
                      },
                      isDark: isDark,
                    ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Text(
                '${_displayedStudents.length} students found',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
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
    return SizedBox(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          final fullName = student['name'];
          final avatarColor = _getAvatarColor(fullName);

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
                color: isSelected
                    ? (isDark ? Colors.blue.withValues(alpha: 0.1) : Colors.blue.shade50)
                    : (isDark ? const Color(0xFF252542) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Colors.blue.shade600
                      : (isDark ? Colors.white10 : const Color(0xFFF1F3F4)),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: isSelected ? 12 : 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar
                  if (student['profile_picture'] != null &&
                      student['profile_picture'].toString().isNotEmpty)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(student['profile_picture']),
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
                          'Roll: ${student['roll_number']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF3B5BDB),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${student['degree']} • Sem ${student['semester']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Selection Indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.shade600
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue.shade600
                            : (isDark ? Colors.white24 : Colors.grey.shade300),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
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
      const Color(0xFF3B5BDB),
      const Color(0xFFF59F00),
      const Color(0xFF37B24D),
      const Color(0xFFF03E3E),
      const Color(0xFF7048E8),
      const Color(0xFF0CA678),
    ];
    final hash = name.codeUnits.fold(0, (a, b) => a + b);
    return colors[hash % colors.length];
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
            color: Colors.black.withValues(alpha: 0.1),
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

    context.pop({
      'count': _selectedStudentIds.length,
      'student_ids': _selectedStudentIds.toList(),
      'students': selectedStudents,
    });
  }
}

// Filter Bottom Sheet for Student Selection
class FilterBottomSheet extends ConsumerStatefulWidget {
  final String? currentBatchYear;
  final String? currentProgram;
  final String? currentSemester;
  final Function(String?, String?, String?) onApply;
  final VoidCallback onReset;

  const FilterBottomSheet({
    super.key,
    required this.currentBatchYear,
    required this.currentProgram,
    required this.currentSemester,
    required this.onApply,
    required this.onReset,
  });

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late String? _batchYear;
  late String? _program;
  late String? _semester;

  final List<String> _batchYears = ['2023', '2024', '2025', '2026'];

  @override
  void initState() {
    super.initState();
    _batchYear = widget.currentBatchYear;
    _program = widget.currentProgram;
    _semester = widget.currentSemester;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final teacherState = ref.watch(teacherStoreProvider);
    final teacherProfile = teacherState.profile;

    final programs = teacherProfile?.scope.map((s) => s.program).toSet().toList() ?? [];
    
    // Get semesters for selected program from teacher's subjects
    final semesters = (_program != null && teacherProfile != null)
        ? teacherProfile.subjects
            .where((s) => s.program == _program)
            .map((s) => s.semester)
            .whereType<int>()
            .toSet()
            .toList()
        : [1, 2, 3, 4, 5, 6, 7, 8];
    semesters.sort();

    return CustomBottomSheetLayout(
      title: 'Filter Students',
      onReset: () {
        setState(() {
          _batchYear = null;
          _program = null;
          _semester = null;
        });
        widget.onReset();
        Navigator.pop(context);
      },
      onApply: () {
        widget.onApply(_batchYear, _program, _semester);
        Navigator.pop(context);
      },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Program
          _buildLabel('Program', isDark),
          _buildDropdown(
            value: _program,
            items: programs,
            onChanged: (v) => setState(() {
              _program = v;
              _semester = null;
            }),
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Semester
          _buildLabel('Semester', isDark),
          _buildDropdown(
            value: _semester,
            items: semesters.map((e) => e.toString()).toList(),
            onChanged: (v) => setState(() => _semester = v),
            isDark: isDark,
          ),
          const SizedBox(height: 24),
          _buildFilterSection(
            title: 'Batch Year',
            options: _batchYears,
            selectedValue: _batchYear,
            onSelected: (val) => setState(() => _batchYear = val),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required List<String> options,
    required String? selectedValue,
    required Function(String?) onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return ChoiceChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                onSelected(selected ? option : null);
              },
              selectedColor: const Color(0xFF3B5BDB),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: isDark ? const Color(0xFF252542) : Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF3B5BDB) : Colors.transparent,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return ui.Dropdown(
      label: "",
      hint: "Select Option",
      items: items,
      value: value,
      onChanged: onChanged,
    );
  }
}
