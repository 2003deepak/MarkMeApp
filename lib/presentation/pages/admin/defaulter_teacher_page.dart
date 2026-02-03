import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/models/teacher_model.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';
import 'package:markmeapp/data/repositories/admin_repository.dart';

class AdminDefaulterTeacherPage extends ConsumerStatefulWidget {
  const AdminDefaulterTeacherPage({super.key});

  @override
  ConsumerState<AdminDefaulterTeacherPage> createState() => _AdminDefaulterTeacherPageState();
}

class _AdminDefaulterTeacherPageState extends ConsumerState<AdminDefaulterTeacherPage> {
  late final AdminRepository _adminRepo;

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
  double _rescheduleThreshold = 0.10; // 10%
  double _cancellationThreshold = 0.20; // 20%
  bool _isFiltersVisible = true;

  @override
  void initState() {
    super.initState();
    _adminRepo = ref.read(adminRepositoryProvider);
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
        rescheduleThreshold: _rescheduleThreshold,
        cancellationThreshold: _cancellationThreshold,
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

  // MAIN BUILD
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(

      appBar: MarkMeAppBar(
        title: 'Defaulters List',
        onBackPressed: () => context.pop(),
      ),

      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      body: Column(
        children: [
          if (_isFiltersVisible) _buildFilters(isDark),
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
    );
  }

  // ------------------------------
  // FILTERS
  // ------------------------------
  Widget _buildFilters(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252542) : const Color(0xFFF8F9FA),
        border: Border(
           bottom: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE9ECEF)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Filters",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // Reschedule Slider
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Reschedule Rate > ${(_rescheduleThreshold * 100).toInt()}%",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    Slider(
                      value: _rescheduleThreshold,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      label: "${(_rescheduleThreshold * 100).toInt()}%",
                      onChanged: (value) {
                         setState(() {
                           _rescheduleThreshold = value;
                         });
                      },
                      onChangeEnd: (value) {
                        _fetchTeachers();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
           // Cancellation Slider
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Cancellation Rate > ${(_cancellationThreshold * 100).toInt()}%",
                      style: TextStyle(
                         fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    Slider(
                      value: _cancellationThreshold,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      label: "${(_cancellationThreshold * 100).toInt()}%",
                      onChanged: (value) {
                         setState(() {
                           _cancellationThreshold = value;
                         });
                      },
                       onChangeEnd: (value) {
                        _fetchTeachers();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
          ), 
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
             // context.push(
            //   '/admin/teacher/${teacher.id}',
            //   extra: '${teacher.firstName} ${teacher.lastName}',
            // );
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Teacher Details - Coming Soon')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                // Add Metrics if available in Teacher model or generic
                // For now, simpler card as per clone instruction
              ],
            ),
          ),
        ),
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
        color: avatarColor.withOpacity(isDark ? 0.3 : 0.2),
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
