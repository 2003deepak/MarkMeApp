import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/models/clerk_model.dart';
import 'package:markmeapp/data/repositories/admin_repository.dart';
import 'package:markmeapp/presentation/widgets/ui/custom_bottom_sheet_layout.dart';
import 'package:markmeapp/presentation/widgets/ui/filter_chip.dart';
import 'package:markmeapp/presentation/widgets/ui/search_bar.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';
import 'package:markmeapp/state/admin_state.dart';
import 'package:markmeapp/state/refresh_state.dart';

class ClerkListPage extends ConsumerStatefulWidget {
  const ClerkListPage({super.key});

  @override
  ConsumerState<ClerkListPage> createState() => _ClerkListPageState();
}

class _ClerkListPageState extends ConsumerState<ClerkListPage> {
  final TextEditingController _searchController = TextEditingController();
  late final AdminRepository _adminRepo;

  List<Clerk> _clerks = [];
  List<Clerk> _filteredClerks = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _errorMessage = '';
  bool _isFirstLoad = true;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _limit = 10;
  int _totalClerks = 0;

  // Filter variables
  String? _selectedProgram;
  String? _selectedDepartment;

  Timer? _debounceTimer;
  final _searchDebounceDuration = const Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    _adminRepo = ref.read(adminRepositoryProvider);
    _searchController.addListener(_debounceSearchListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isFirstLoad) {
      _isFirstLoad = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchClerks();
        // Fetch hierarchical metadata if needed
        ref.read(adminStoreProvider.notifier).fetchHierarchicalMetadata();
      });
    }
  }

  void _debounceSearchListener() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_searchDebounceDuration, () {
      _fetchClerks();
    });
  }

  Future<void> _fetchClerks({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      _currentPage = 1;
      _clerks.clear();
    } else {
      if (_isLoadingMore || !_hasMoreData) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final result = await _adminRepo.fetchClerks(
        search: _searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : null,
        program: _selectedProgram,
        department: _selectedDepartment,
        page: loadMore ? _currentPage + 1 : 1,
        limit: _limit,
      );

      if (result['success'] == true) {
        final List<dynamic> data = result['data'] ?? [];
        final fetchedClerks = data
            .map((json) => Clerk.fromJson(json))
            .toList();

        setState(() {
          if (loadMore) {
            _clerks.addAll(fetchedClerks);
          } else {
            _clerks = fetchedClerks;
          }

          _totalClerks = result['total'] ?? _clerks.length;
          _hasMoreData = result['has_next'] == true;

          if (loadMore) {
            _currentPage++;
          } else {
            _currentPage = 1;
          }
        });

        _filterClerks();
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to load clerks';
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

  void _filterClerks() {
    String searchText = _searchController.text.toLowerCase().trim();

    List<Clerk> filtered = _clerks.where((clerk) {
      bool matchesSearch = searchText.isEmpty ||
          clerk.firstName.toLowerCase().contains(searchText) ||
          (clerk.middleName?.toLowerCase().contains(searchText) ?? false) ||
          clerk.lastName.toLowerCase().contains(searchText) ||
          clerk.email.toLowerCase().contains(searchText) ||
          clerk.id.toLowerCase().contains(searchText);

      // Filter by program (client-side)
      bool matchesProgram = _selectedProgram == null ||
          (clerk.academicScopes?.any((scope) => scope.programId == _selectedProgram) ?? false);

      // Filter by department (client-side)
      bool matchesDepartment = _selectedDepartment == null ||
          (clerk.academicScopes?.any((scope) => scope.departmentId == _selectedDepartment) ?? false);

      return matchesSearch && matchesProgram && matchesDepartment;
    }).toList();

    setState(() {
      _filteredClerks = filtered;
    });
  }

  void _loadMore() {
    if (_hasMoreData && !_isLoadingMore && _filteredClerks.isNotEmpty) {
      _fetchClerks(loadMore: true);
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClerkFilterBottomSheet(
        currentProgram: _selectedProgram,
        currentDepartment: _selectedDepartment,
        onApply: (program, department) {
          setState(() {
            _selectedProgram = program;
            _selectedDepartment = department;
          });
          _fetchClerks();
        },
        onReset: () {
          setState(() {
            _selectedProgram = null;
            _selectedDepartment = null;
          });
          _fetchClerks();
        },
      ),
    );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedProgram != null) count++;
    if (_selectedDepartment != null) count++;
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

    ref.listen<int>(dashboardRefreshProvider, (previous, next) {
      if (previous != next) {
        _fetchClerks();
      }
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      appBar: MarkMeAppBar(
        title: 'Clerk List',
        onBackPressed: () => context.pop()
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          AppSearchBar(
            controller: _searchController,
            hintText: 'Search by name, email, or ID...',
            onChanged: (txt) => _debounceSearchListener(),
            onFilterTap: _showFilterSheet,
            activeFilterCount: _activeFilterCount,
          ),

          const SizedBox(height: 16),

          // Error Message
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
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
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_selectedProgram != null)
                      FilterChipWidget(
                        label: 'Program: $_selectedProgram',
                        onRemove: () {
                          setState(() {
                            _selectedProgram = null;
                          });
                          _fetchClerks();
                        },
                        isDark: isDark,
                      ),
                    if (_selectedDepartment != null)
                      FilterChipWidget(
                        label: 'Department: $_selectedDepartment',
                        onRemove: () {
                          setState(() {
                            _selectedDepartment = null;
                          });
                          _fetchClerks();
                        },
                        isDark: isDark,
                      ),
                  ],
                ),
              ),
            ),

          // Clerk Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '$_totalClerks clerk${_totalClerks == 1 ? '' : 's'} found',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Clerk List
          Expanded(
            child: _isLoading && !_isLoadingMore
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      await _fetchClerks();
                    },
                    child: _filteredClerks.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: Center(
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
                                        'No clerks found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: isDark ? Colors.white70 : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _searchController.text.isNotEmpty ||
                                                _activeFilterCount > 0
                                            ? 'Try adjusting your search or filters'
                                            : 'No clerks in the system',
                                        style: TextStyle(
                                          color: isDark ? Colors.white38 : Colors.grey,
                                        ),
                                      ),
                                      if (_searchController.text.isNotEmpty ||
                                          _activeFilterCount > 0)
                                        const SizedBox(height: 16),
                                      if (_searchController.text.isNotEmpty ||
                                          _activeFilterCount > 0)
                                        TextButton.icon(
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              _selectedProgram = null;
                                              _selectedDepartment = null;
                                            });
                                            _fetchClerks();
                                          },
                                          icon: const Icon(Icons.refresh_rounded, size: 16),
                                          label: const Text('Clear all filters'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: const Color(0xFF3B5BDB),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification scrollInfo) {
                              if (!_isLoadingMore &&
                                  _hasMoreData &&
                                  scrollInfo.metrics.pixels >=
                                      scrollInfo.metrics.maxScrollExtent - 100) {
                                _loadMore();
                              }
                              return false;
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _filteredClerks.length +
                                  (_isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _filteredClerks.length) {
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
                                return ClerkCard(
                                  clerk: _filteredClerks[index],
                                  isDark: isDark,
                                );
                              },
                            ),
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20, right: 20),
        child: FloatingActionButton(
          onPressed: () {
            context.push('/admin/create-clerk').then((_) {
              _fetchClerks();
            });
          },
          backgroundColor: const Color(0xFF3B5BDB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// Clerk Card Widget
class ClerkCard extends StatelessWidget {
  final Clerk clerk;
  final bool isDark;

  const ClerkCard({
    super.key,
    required this.clerk,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColor = _getAvatarColor(clerk.firstName);
    final fullName = '${clerk.firstName} ${clerk.middleName ?? ''} ${clerk.lastName}'
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push('/admin/clerk/${clerk.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
        children: [
          // Profile Picture or Avatar
          if (clerk.profilePicture != null && clerk.profilePicture!.isNotEmpty)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(clerk.profilePicture!),
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

          // Clerk Info
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
                const SizedBox(height: 2),
                Text(
                  clerk.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              ],
            ),
          ),
        ],
      ),
          ),
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

// Filter Bottom Sheet
class ClerkFilterBottomSheet extends ConsumerStatefulWidget {
  final String? currentProgram;
  final String? currentDepartment;
  final void Function(String?, String?) onApply;
  final VoidCallback onReset;

  const ClerkFilterBottomSheet({
    super.key,
    required this.currentProgram,
    required this.currentDepartment,
    required this.onApply,
    required this.onReset,
  });

  @override
  ConsumerState<ClerkFilterBottomSheet> createState() =>
      _ClerkFilterBottomSheetState();
}

class _ClerkFilterBottomSheetState
    extends ConsumerState<ClerkFilterBottomSheet> {
  late String? _program;
  late String? _department;

  @override
  void initState() {
    super.initState();
    _program = widget.currentProgram;
    _department = widget.currentDepartment;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adminState = ref.watch(adminStoreProvider);
    final metadata = adminState.hierarchyMetadata ?? {};

    // Get unique programs from metadata
    final programs = metadata.keys.toList();

    // Get departments based on selected program
    List<String> departments = [];
    if (_program != null && metadata[_program] != null) {
      if (metadata[_program] is Map) {
        departments = (metadata[_program] as Map<String, dynamic>).keys.toList();
      }
    }

    return CustomBottomSheetLayout(
      title: 'Filter Clerks',
      onReset: () {
        setState(() {
          _program = null;
          _department = null;
        });
        widget.onReset();
        Navigator.pop(context);
      },
      onApply: () {
        widget.onApply(_program, _department);
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
            hint: 'Select Program',
            onChanged: (v) => setState(() {
              _program = v;
              _department = null;
            }),
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // Department
          _buildLabel('Department', isDark),
          _buildDropdown(
            value: _department,
            items: departments,
            hint: 'Select Department',
            onChanged: (v) => setState(() => _department = v),
            isDark: isDark,
          ),
          const SizedBox(height: 40),
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
    required String hint,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      height: 50,
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
          hint: Text(
            hint,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey,
              fontSize: 14,
            ),
          ),
          isDense: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: isDark ? Colors.white38 : Colors.grey,
            size: 20,
          ),
          dropdownColor: isDark ? const Color(0xFF252542) : Colors.white,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}