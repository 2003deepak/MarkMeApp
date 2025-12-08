import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/models/teacher_model.dart';
import 'package:markmeapp/data/repositories/clerk_repository.dart';

class TeacherListPage extends ConsumerStatefulWidget {
  const TeacherListPage({super.key});

  @override
  ConsumerState<TeacherListPage> createState() => _TeacherListPageState();
}

class _TeacherListPageState extends ConsumerState<TeacherListPage> {
  final TextEditingController _searchController = TextEditingController();
  late final ClerkRepository _clerkRepo;

  List<Teacher> _teachers = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _errorMessage = '';

  bool _isFirstLoad = true;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _limit = 10;

  int _totalTeachers = 0;

  Timer? _debounceTimer;
  final _searchDebounceDuration = const Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    _clerkRepo = ref.read(clerkRepositoryProvider);
    _searchController.addListener(_debounceSearchListener);
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

  // SEARCH DEBOUNCER
  void _debounceSearchListener() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_searchDebounceDuration, () {
      _currentPage = 1;
      _hasMoreData = true;
      _fetchTeachers();
    });
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

      final result = await _clerkRepo.fetchTeachers(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        page: loadMore ? _currentPage : 1,
        limit: _limit,
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
          _errorMessage = result['error'] ?? 'Failed to load teachers';
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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // MAIN BUILD
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      body: Column(
        children: [
          _buildHeader(isDark),
          _buildSearchBar(isDark),
          const SizedBox(height: 10),
          _buildErrorMessage(),
          _buildCountRow(isDark),
          Expanded(
            child: _isLoading && !_isLoadingMore
                ? const Center(child: CircularProgressIndicator())
                : _teachers.isEmpty
                ? _buildEmpty(isDark)
                : _buildTeacherList(isDark),
          ),
        ],
      ),
      // FLOATING ACTION BUTTON
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20, right: 20),
        child: FloatingActionButton(
          onPressed: () {
            context.push('/clerk/add-teacher');
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

  // ------------------------------
  // HEADER
  // ------------------------------
  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            'Teacher List',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // SEARCH BAR
  // ------------------------------
  Widget _buildSearchBar(bool isDark) {
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
                  hintText: 'Search by name, email, or ID...',
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
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.clear,
                  color: isDark ? Colors.white38 : Colors.grey,
                ),
                onPressed: () {
                  _searchController.clear();
                  _fetchTeachers();
                },
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
            'No teachers found',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.white70 : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'No teachers in the system'
                : 'Try adjusting your search',
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
    return RefreshIndicator(
      onRefresh: () => _fetchTeachers(),
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
          padding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            80,
          ), // Bottom padding for FAB
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
              onRefresh: () => _fetchTeachers(),
            );
          },
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
  final VoidCallback onRefresh;

  const TeacherCard({
    super.key,
    required this.teacher,
    required this.isDark,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColor = _getAvatarColor(teacher.firstName);
    final fullName = '${teacher.firstName} ${teacher.lastName}'.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252542) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFF1F3F4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(fullName, avatarColor),
              const SizedBox(width: 16),
              _buildTeacherInfo(fullName),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String fullName, Color avatarColor) {
    if (teacher.profilePicture != null && teacher.profilePicture!.isNotEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(teacher.profilePicture!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 60,
      height: 60,
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
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherInfo(String fullName) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fullName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            teacher.teacherId,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF3B5BDB),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            teacher.email,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            teacher.mobileNumber.toString(),
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(" ");
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
