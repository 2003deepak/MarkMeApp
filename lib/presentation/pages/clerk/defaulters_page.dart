import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/models/defaulter_model.dart';
import 'package:markmeapp/data/repositories/clerk_repository.dart';
import 'package:markmeapp/presentation/widgets/ui/custom_bottom_sheet_layout.dart';
import 'package:markmeapp/presentation/widgets/ui/filter_chip.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';

class DefaultersPage extends ConsumerStatefulWidget {
  const DefaultersPage({super.key});

  @override
  ConsumerState<DefaultersPage> createState() => _DefaultersPageState();
}

class _DefaultersPageState extends ConsumerState<DefaultersPage> {
  final TextEditingController _searchController = TextEditingController();
  
  // Data State
  List<DefaulterStudent> _students = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _errorMessage = '';
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _limit = 10;
  int _totalStudents = 0;

  // Filter State
  String? _selectedProgram;
  int? _selectedSemester;
  int _threshold = 75;

  Timer? _debounceTimer;
  final _searchDebounceDuration = const Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_debounceSearchListener);
    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDefaulters();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _debounceSearchListener() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_searchDebounceDuration, () {
      _fetchDefaulters();
    });
  }

  Future<void> _fetchDefaulters({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _currentPage = 1;
        _students.clear();
      });
    } else {
      if (_isLoadingMore || !_hasMoreData) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final repo = ref.read(clerkRepositoryProvider);
      final response = await repo.getDefaulters(
        page: loadMore ? _currentPage : 1,
        limit: _limit,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        program: _selectedProgram,
        semester: _selectedSemester,
        threshold: _threshold,
      );

      if (response['success'] == true) {
        final data = DefaulterResponse.fromJson(response);
        
        setState(() {
          if (loadMore) {
            _students.addAll(data.students);
          } else {
            _students = data.students;
          }

          _totalStudents = data.total;
          _hasMoreData = data.students.length == _limit;
          
          if (loadMore) {
            _currentPage++;
          } else {
            _currentPage = 2; // Next page will be 2
          }
        });
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to load defaulters';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      if (!loadMore) {
        setState(() => _isLoading = false);
      }
      setState(() => _isLoadingMore = false);
    }
  }

  void _loadMore() {
    if (_hasMoreData && !_isLoadingMore) {
      _fetchDefaulters(loadMore: true);
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        currentProgram: _selectedProgram,
        currentSemester: _selectedSemester,
        currentThreshold: _threshold,
        onApply: (program, semester, threshold) {
          setState(() {
            _selectedProgram = program;
            _selectedSemester = semester;
            _threshold = threshold;
          });
          _fetchDefaulters();
          Navigator.pop(context);
        },
        onReset: () {
          setState(() {
            _selectedProgram = null;
            _selectedSemester = null;
            _threshold = 75;
          });
          _fetchDefaulters();
          Navigator.pop(context);
        },
      ),
    );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedProgram != null) count++;
    if (_selectedSemester != null) count++;
    if (_threshold != 75) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      appBar: MarkMeAppBar(
        title: 'Defaulters List',
        onBackPressed: () => context.pop(),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildSearchBar(isDark),
          const SizedBox(height: 10),
          _buildErrorMessage(),
          if (_activeFilterCount > 0) _buildFilterChips(isDark),
          _buildCountRow(isDark),
          Expanded(
            child: _isLoading && !_isLoadingMore
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? _buildEmpty(isDark)
                    : _buildList(isDark),
          ),
        ],
      ),
    );
  }


  Widget _buildSearchBar(bool isDark) {
    final primaryColor = const Color(0xFF3B5BDB);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252542) : const Color(0xFFF8F9FA),
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
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search by name...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            Stack(
              children: [
                IconButton(
                  onPressed: _showFilterSheet,
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
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.red),
              onPressed: () => setState(() => _errorMessage = ''),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  _fetchDefaulters();
                },
                isDark: isDark,
              ),
            if (_selectedSemester != null)
              FilterChipWidget(
                label: 'Sem: $_selectedSemester',
                onRemove: () {
                  setState(() => _selectedSemester = null);
                  _fetchDefaulters();
                },
                isDark: isDark,
              ),
            if (_threshold != 75)
              FilterChipWidget(
                label: 'Threshold: $_threshold%',
                onRemove: () {
                  setState(() => _threshold = 75);
                  _fetchDefaulters();
                },
                isDark: isDark,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Text(
            '$_totalStudents student${_totalStudents == 1 ? '' : 's'} found',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          if (_hasMoreData && _students.isNotEmpty)
            Text(
              'Page ${_currentPage - 1}',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 64,
            color: isDark ? Colors.white30 : Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No defaulters found',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.white70 : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Great! Everyone is attending classes.',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(bool isDark) {
    return RefreshIndicator(
      onRefresh: () => _fetchDefaulters(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (scroll) {
          if (!_isLoadingMore &&
              _hasMoreData &&
              scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 40) {
            _loadMore();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _students.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _students.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            return _DefaulterCard(
              student: _students[index],
              isDark: isDark,
            );
          },
        ),
      ),
    );
  }
}

class _DefaulterCard extends StatelessWidget {
  final DefaulterStudent student;
  final bool isDark;

  const _DefaulterCard({required this.student, required this.isDark});

  Color _getRiskColor() {
    switch (student.risk.toUpperCase()) {
      case 'HIGH': return const Color(0xFFDC2626);
      case 'MEDIUM': return const Color(0xFFD97706);
      default: return const Color(0xFF166534);
    }
  }

  Color _getRiskBgColor(bool isDark) {
    switch (student.risk.toUpperCase()) {
      case 'HIGH': return isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2);
      case 'MEDIUM': return isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
      default: return isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7);
    }
  }
  
  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF3B5BDB),
      const Color(0xFFF59F00),
      const Color(0xFF37B24D),
      const Color(0xFFF03E3E),
      const Color(0xFF7048E8),
    ];
    final hash = name.codeUnits.fold(0, (a, b) => a + b);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = _getAvatarColor(student.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252542) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFF1F3F4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          // Leading Avatar
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: avatarColor.withOpacity(isDark ? 0.3 : 0.2),
              shape: BoxShape.circle,
              image: student.profilePicture != null && student.profilePicture!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(student.profilePicture!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: student.profilePicture != null && student.profilePicture!.isNotEmpty
                ? null
                : Center(
                    child: Text(
                      student.name.isNotEmpty ? student.name[0] : '?',
                      style: TextStyle(
                        color: avatarColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
          ),
          // Title: Name & Risk Badge
          title: Row(
            children: [
              Expanded(
                child: Text(
                  student.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getRiskBgColor(isDark),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  student.risk,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getRiskColor(),
                  ),
                ),
              ),
            ],
          ),
          // Subtitle: Info & Overall %
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
               Text(
                'Roll: ${student.roll} • ${student.program} Sem ${student.semester}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Overall Attendance: ${student.overallPercentage.toStringAsFixed(1)}%',
                 style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: student.overallPercentage < 75 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          children: [
            Divider(color: isDark ? Colors.white10 : Colors.grey[200]),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Defaulter in Subjects:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...student.defaulterSubjects.map((subject) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          subject.code,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${subject.percentage}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final String? currentProgram;
  final int? currentSemester;
  final int currentThreshold;
  final Function(String?, int?, int) onApply;
  final VoidCallback onReset;

  const _FilterBottomSheet({
    required this.currentProgram,
    required this.currentSemester,
    required this.currentThreshold,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  String? _program;
  int? _semester;
  late int _threshold;

  @override
  void initState() {
    super.initState();
    _program = widget.currentProgram;
    _semester = widget.currentSemester;
    _threshold = widget.currentThreshold;
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheetLayout(
      title: 'Filter Defaulters',
      onReset: widget.onReset,
      onApply: () => widget.onApply(_program, _semester, _threshold),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropdown(
            label: 'Program',
            value: _program,
            items: ['MCA', 'MBA', 'BTECH'],
            onChanged: (val) => setState(() => _program = val),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Semester',
            value: _semester,
            items: [1, 2, 3, 4, 5, 6],
            onChanged: (val) => setState(() => _semester = val),
          ),
          const SizedBox(height: 24),
          Text(
            'Attendance Threshold: $_threshold%',
             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Slider(
            value: _threshold.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            label: '$_threshold%',
            activeColor: const Color(0xFF3B5BDB),
            onChanged: (val) => setState(() => _threshold = val.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: Text('All ${label}s'),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
