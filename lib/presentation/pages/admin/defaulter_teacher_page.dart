import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/models/teacher_model.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';
import 'package:markmeapp/data/repositories/admin_repository.dart';
import 'package:markmeapp/presentation/widgets/ui/search_bar.dart';
import 'package:markmeapp/presentation/widgets/ui/custom_bottom_sheet_layout.dart';
import 'package:markmeapp/presentation/widgets/ui/filter_chip.dart';
import 'package:markmeapp/state/admin_state.dart';
import 'package:markmeapp/state/refresh_state.dart';

class AdminDefaulterTeacherPage extends ConsumerStatefulWidget {
  const AdminDefaulterTeacherPage({super.key});

  @override
  ConsumerState<AdminDefaulterTeacherPage> createState() => _AdminDefaulterTeacherPageState();
}

class _AdminDefaulterTeacherPageState extends ConsumerState<AdminDefaulterTeacherPage> {
  late final AdminRepository _adminRepo;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  final _searchDebounceDuration = const Duration(milliseconds: 800);

  List<Teacher> _teachers = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _errorMessage = '';

  bool _isFirstLoad = true;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _limit = 10;
  int _totalTeachers = 0;

  // Filters
  String? _selectedProgram;
  String? _selectedDepartment;
  double _rescheduleThreshold = 0.10; // 10%
  double _cancellationThreshold = 0.20; // 20%
  bool _isFiltersVisible = true;

  @override
  void initState() {
    super.initState();
    _adminRepo = ref.read(adminRepositoryProvider);
    _searchController.addListener(_debounceSearchListener);
    
    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminStoreProvider.notifier).fetchHierarchicalMetadata();
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
      _fetchTeachers();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isFirstLoad) {
      _isFirstLoad = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchTeachers();
      });
    }
  }

  // FETCH TEACHERS
  Future<void> _fetchTeachers({bool loadMore = false}) async {
    try {
      if (!loadMore) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
        _currentPage = 1;
        _teachers.clear();
      } else {
        if (_isLoadingMore || !_hasMoreData) return;
        setState(() => _isLoadingMore = true);
      }

      final result = await _adminRepo.fetchDefaulterTeachers(
        page: loadMore ? _currentPage : 1,
        limit: _limit,
        // search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        program: _selectedProgram,
        department: _selectedDepartment,
      );

      if (result['success'] == true) {
        final List<dynamic> data = result['data'] ?? [];
        final fetchedTeachers = data
            .map((json) => Teacher.fromJson(json))
            .toList();

        setState(() {
          if (loadMore) {
            _teachers.addAll(fetchedTeachers);
          } else {
            _teachers = fetchedTeachers;
          }

          _totalTeachers = result['total'] ?? _teachers.length;
          _hasMoreData = result['has_next'] == true;

          // Update current page for next load more
          if (loadMore) {
            _currentPage++;
          } else {
            _currentPage = 1;
          }
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to load defaulter teachers';
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'An error occurred: $e');
    } finally {
      if (!loadMore) {
        setState(() => _isLoading = false);
      }
      setState(() => _isLoadingMore = false);
    }
  }

  // LOAD MORE (INFINITE SCROLL)
  void _loadMore() {
    if (_hasMoreData && !_isLoadingMore) {
      _fetchTeachers(loadMore: true);
    }
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedProgram != null) count++;
    if (_selectedDepartment != null) count++;
    return count;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final adminState = ref.watch(adminStoreProvider);
        final metadata = adminState.hierarchyMetadata ?? {};

        return _FilterBottomSheet(
          currentProgram: _selectedProgram,
          currentDepartment: _selectedDepartment,
          metadata: metadata,
          onApply: (program, department) {
            setState(() {
              _selectedProgram = program;
              _selectedDepartment = department;
            });
            _fetchTeachers();
            Navigator.pop(context);
          },
          onReset: () {
            setState(() {
              _selectedProgram = null;
              _selectedDepartment = null;
            });
            _fetchTeachers();
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(dashboardRefreshProvider, (previous, next) {
      if (next > 0) {
        _fetchTeachers();
      }
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      appBar: MarkMeAppBar(
        title: 'Defaulters List',
        onBackPressed: () => context.pop(),
      ),
      body: Column(
        children: [
          AppSearchBar(
            controller: _searchController,
            hintText: 'Search by name...',
            onFilterTap: _showFilterSheet,
            activeFilterCount: _activeFilterCount,
          ),
          _buildErrorMessage(),
          if (_activeFilterCount > 0) _buildFilterChips(isDark),
          _buildCountRow(isDark),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchTeachers(),
              child: _isLoading && !_isLoadingMore
                  ? const Center(child: CircularProgressIndicator())
                  : _teachers.isEmpty
                      ? _buildEmpty(isDark)
                      : _buildTeacherList(isDark),
            ),
          ),
        ],
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
                  _fetchTeachers();
                },
                isDark: isDark,
              ),
            if (_selectedDepartment != null)
              FilterChipWidget(
                label: 'Dept: $_selectedDepartment',
                onRemove: () {
                  setState(() => _selectedDepartment = null);
                  _fetchTeachers();
                },
                isDark: isDark,
              ),
          ],
        ),
      ),
    );
  }

  // ------------------------------
  // ERROR MESSAGE BOX
  // ------------------------------
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

  // ------------------------------
  // COUNT + PAGE INFO
  // ------------------------------
  Widget _buildCountRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Text(
            '$_totalTeachers teacher${_totalTeachers == 1 ? '' : 's'} found',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          if (_hasMoreData && _teachers.isNotEmpty)
            Text(
              'Page $_currentPage',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------
  // EMPTY STATE
  // ------------------------------
  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: isDark ? Colors.white30 : Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No defaulter teachers found',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.white70 : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
           Text(
            'Try adjusting filters',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // TEACHER LIST + INFINITE SCROLL
  // ------------------------------
  Widget _buildTeacherList(bool isDark) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scroll) {
        if (!_isLoadingMore &&
            _hasMoreData &&
            scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 40) {
          _loadMore();
        }
        return false;
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: _teachers.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _teachers.length) {
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

          return TeacherCard(
            teacher: _teachers[index],
            isDark: isDark,
          );
        },
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final String? currentProgram;
  final String? currentDepartment;
  final Map<String, dynamic> metadata;
  final Function(String?, String?) onApply;
  final VoidCallback onReset;

  const _FilterBottomSheet({
    required this.currentProgram,
    required this.currentDepartment,
    required this.metadata,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  String? _selectedProgram;
  String? _selectedDepartment;

  @override
  void initState() {
    super.initState();
    _selectedProgram = widget.currentProgram;
    _selectedDepartment = widget.currentDepartment;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF3B5BDB);

    // Filter available departments based on selected program
    List<String> programs = widget.metadata.keys.toList();
    List<String> departments = [];
    if (_selectedProgram != null && widget.metadata[_selectedProgram] != null) {
      if (widget.metadata[_selectedProgram] is Map) {
        departments = (widget.metadata[_selectedProgram] as Map<String, dynamic>)
            .keys
            .toList();
      }
    }

    return CustomBottomSheetLayout(
      title: "Filter Teachers",
      onReset: widget.onReset,
      onApply: () => widget.onApply(_selectedProgram, _selectedDepartment),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropdownLabel("Select Program", isDark),
          _buildDropdown(
            value: _selectedProgram,
            items: programs,
            onChanged: (val) {
              setState(() {
                _selectedProgram = val;
                _selectedDepartment = null;
              });
            },
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          _buildDropdownLabel("Select Department", isDark),
          _buildDropdown(
            value: _selectedDepartment,
            items: departments,
            onChanged: (val) {
              setState(() {
                _selectedDepartment = val;
              });
            },
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownLabel(String label, bool isDark) {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            "Select Option",
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey.shade500,
              fontSize: 15,
            ),
          ),
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1F1F35) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ----------------------------------------------------------
// CARD WIDGET
// ----------------------------------------------------------
class TeacherCard extends StatelessWidget {
  final Teacher teacher;
  final bool isDark;

  const TeacherCard({
    super.key,
    required this.teacher,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColor = _getAvatarColor(teacher.firstName);
    final fullName = '${teacher.firstName} ${teacher.lastName}'.trim();
    final primaryColor = const Color(0xFF3B5BDB);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252542) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Teacher Details coming soon...')),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatar(fullName, avatarColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    fullName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _buildStatusBadge(),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              teacher.teacherId,
                              style: TextStyle(
                                fontSize: 13,
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8)
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (teacher.score != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMetric('Score', teacher.score!.toStringAsFixed(1), Colors.orange),
                          _buildDivider(),
                          _buildMetric('Cancel %', '${teacher.cancellationRate}%', Colors.red),
                          _buildDivider(),
                          _buildMetric('Excep %', '${teacher.exceptionRate}%', Colors.blue),
                          _buildDivider(),
                          _buildMetric('Total', '${teacher.totalSessions}', Colors.green),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Active',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF166534),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.2),
    );
  }

  Widget _buildAvatar(String fullName, Color avatarColor) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: avatarColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: avatarColor.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: avatarColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: teacher.profilePicture != null && teacher.profilePicture!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.network(
                teacher.profilePicture!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(fullName, avatarColor),
              ),
            )
          : _buildInitialsAvatar(fullName, avatarColor),
    );
  }

  Widget _buildInitialsAvatar(String fullName, Color avatarColor) {
    return Center(
      child: Text(
        _getInitials(fullName),
        style: TextStyle(
          color: avatarColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white38 : Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : "?";
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
}
