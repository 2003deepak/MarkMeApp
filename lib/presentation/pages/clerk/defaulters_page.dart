import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/models/defaulter_model.dart';
import 'package:markmeapp/data/models/notification_model.dart';
import 'package:markmeapp/data/repositories/clerk_repository.dart';
import 'package:markmeapp/data/repositories/notification_repository.dart';
import 'package:markmeapp/presentation/widgets/ui/custom_bottom_sheet_layout.dart';
import 'package:markmeapp/presentation/widgets/ui/filter_chip.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';
import 'package:markmeapp/presentation/widgets/ui/search_bar.dart';
import 'package:markmeapp/state/admin_state.dart';
import 'package:markmeapp/state/clerk_state.dart';
import 'package:markmeapp/state/refresh_state.dart';

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

  // Selection State
  final Set<String> _selectedStudentIds = {};
  bool _isSending = false;

  Timer? _debounceTimer;
  final _searchDebounceDuration = const Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_debounceSearchListener);
    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminStoreProvider.notifier).fetchHierarchicalMetadata();
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
      builder: (context) {
        final clerkState = ref.watch(clerkStoreProvider);
        final academicScopes = clerkState.profile?.academicScopes ?? [];

        return _FilterBottomSheet(
          currentProgram: _selectedProgram,
          currentSemester: _selectedSemester,
          currentThreshold: _threshold,
          academicScopes: academicScopes,
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
        );
      },
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
    final primaryColor = const Color(0xFF3B5BDB);

    ref.listen(dashboardRefreshProvider, (previous, next) {
      if (next > 0) {
        _fetchDefaulters();
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
            onChanged: (txt) => _fetchDefaulters(),
            onFilterTap: _showFilterSheet,
            activeFilterCount: _activeFilterCount,
          ),
          _buildErrorMessage(),
          if (_activeFilterCount > 0) _buildFilterChips(isDark),
          _buildSelectionHeader(isDark),
          _buildCountRow(isDark),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchDefaulters(),
              child: _isLoading && !_isLoadingMore
                  ? const Center(child: CircularProgressIndicator())
                  : _students.isEmpty
                      ? _buildEmpty(isDark)
                      : _buildList(isDark),
            ),
          ),
        ],
      ),
      // Floating Action Button for sending notifications
      floatingActionButton: _selectedStudentIds.isNotEmpty
          ? _buildFloatingActionButton(isDark, primaryColor)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSelectionHeader(bool isDark) {
    if (_students.isEmpty || _selectedStudentIds.isEmpty) return const SizedBox();
    
    final allSelected = _students.isNotEmpty && 
        _students.every((s) => _selectedStudentIds.contains(s.studentId));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252542) : const Color(0xFFF8F9FA),
        border: Border(
          bottom: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE9ECEF)),
        ),
      ),
      child: Row(
        children: [
          // Selection Info with icon
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B5BDB).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    color: const Color(0xFF3B5BDB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_selectedStudentIds.length} selected',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Tap avatar to select more',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Select All/Deselect All Button
          if (_students.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  if (allSelected) {
                    _selectedStudentIds.clear();
                  } else {
                    _selectedStudentIds.addAll(_students.map((s) => s.studentId));
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  allSelected ? 'Deselect All' : 'Select All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildFloatingActionButton(bool isDark, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: FloatingActionButton.extended(
        onPressed: _isSending ? null : _showSendNotificationBottomSheet,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        icon: _isSending 
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send, size: 20),
        label: Text(
          'Notify ${_selectedStudentIds.length}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
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
      )
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            '$_totalStudents student${_totalStudents == 1 ? '' : 's'} found',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
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
          ),
        ),
      ],
    );
  }

  Widget _buildList(bool isDark) {
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
              isSelected: _selectedStudentIds.contains(_students[index].studentId),
              onLongPress: () {
                setState(() {
                  if (_selectedStudentIds.contains(_students[index].studentId)) {
                    _selectedStudentIds.remove(_students[index].studentId);
                  } else {
                    _selectedStudentIds.add(_students[index].studentId);
                  }
                });
              },
            );
          },
        ),
      );
  }

  void _showSendNotificationBottomSheet() {
    final primaryColor = const Color(0xFF3B5BDB);
    final titleController = TextEditingController(text: 'Attendance Warning');
    final messageController = TextEditingController(
      text: 'Your attendance is below the required threshold. Please meet your class coordinator immediately.'
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252542) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white10 : const Color(0xFFE9ECEF),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_active,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Send Notification',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_selectedStudentIds.length} student${_selectedStudentIds.length == 1 ? '' : 's'} will be notified',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notification Title',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white12 : const Color(0xFFE9ECEF),
                            ),
                          ),
                          child: TextField(
                            controller: titleController,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter notification title',
                              hintStyle: TextStyle(
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
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Message Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Message',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white12 : const Color(0xFFE9ECEF),
                            ),
                          ),
                          child: TextField(
                            controller: messageController,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Write your notification message here...',
                              hintStyle: TextStyle(
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
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Quick Message Options
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Messages:',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildQuickMessageChip(
                              'Please improve your attendance',
                              messageController,
                              isDark,
                            ),
                            _buildQuickMessageChip(
                              'Meet class coordinator immediately',
                              messageController,
                              isDark,
                            ),
                            _buildQuickMessageChip(
                              'Attendance below required threshold',
                              messageController,
                              isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action Buttons
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white10 : const Color(0xFFE9ECEF),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: isDark ? Colors.white30 : const Color(0xFFDEE2E6),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSending 
                            ? null 
                            : () {
                                Navigator.pop(context);
                                _sendNotification(
                                  titleController.text,
                                  messageController.text,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSending
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.send, size: 18),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Send Now',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickMessageChip(String text, TextEditingController controller, bool isDark) {
    return GestureDetector(
      onTap: () => controller.text = text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white24 : const Color(0xFFE9ECEF),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Future<void> _sendNotification(String title, String message) async {
    setState(() => _isSending = true);

    try {
      final notification = AppNotification(
        user: "student", 
        title: title,
        message: message,
        targetIds: _selectedStudentIds.toList(),
      );

      final repo = ref.read(notificationRepositoryProvider);
      final result = await repo.pushNotification(notification);

      if (result['success'] == true) {
        setState(() {
          _selectedStudentIds.clear();
        });
        if (mounted) {
          // Show success overlay
          _showSuccessOverlay();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to send notifications'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showSuccessOverlay() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF252542)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF37B24D).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF37B24D),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Notifications Sent!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'All selected students have been notified successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white70 
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B5BDB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(120, 44),
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper to sync selection when loading more
  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }
}

class _DefaulterCard extends StatefulWidget {
  final DefaulterStudent student;
  final bool isDark;
  final bool isSelected;
  final VoidCallback? onLongPress; // Maintained for backward compatibility or if needed

  const _DefaulterCard({
    required this.student,
    required this.isDark,
    required this.isSelected,
    this.onLongPress,
  });

  @override
  State<_DefaulterCard> createState() => _DefaulterCardState();
}

class _DefaulterCardState extends State<_DefaulterCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  Color _getRiskColor() {
    switch (widget.student.risk.toUpperCase()) {
      case 'HIGH': return const Color(0xFFDC2626);
      case 'MEDIUM': return const Color(0xFFD97706);
      default: return const Color(0xFF166534);
    }
  }

  Color _getRiskBgColor(bool isDark) {
    switch (widget.student.risk.toUpperCase()) {
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
    final avatarColor = _getAvatarColor(widget.student.name);
    // Use the primary color 0xFF3B5BDB as the theme color
    final primaryColor = const Color(0xFF3B5BDB);
    final themeColor = widget.isDark ? primaryColor : primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16), // Increased bottom margin
      decoration: BoxDecoration(
        // Add a subtle tint when selected
        color: widget.isSelected 
            ? (widget.isDark ? themeColor.withOpacity(0.15) : themeColor.withOpacity(0.05))
            : (widget.isDark ? const Color(0xFF252542) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isSelected 
              ? themeColor 
              : (widget.isDark ? Colors.white10 : const Color(0xFFF1F3F4)),
          width: widget.isSelected ? 2 : 1, // Reduced width slightly for cleaner look
        ),
        boxShadow: widget.isSelected
            ? [
                BoxShadow(
                  color: themeColor.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(widget.isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16), // Increased padding
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with Tap to Select
                GestureDetector(
                  onTap: widget.onLongPress,
                  child: Stack(
                    children: [
                      Container(
                        width: 52, // Slightly larger avatar
                        height: 52,
                        decoration: BoxDecoration(
                          color: avatarColor.withOpacity(widget.isDark ? 0.3 : 0.2),
                          shape: BoxShape.circle,
                          image: widget.student.profilePicture != null && widget.student.profilePicture!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(widget.student.profilePicture!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: widget.student.profilePicture != null && widget.student.profilePicture!.isNotEmpty
                            ? null
                            : Center(
                                child: Text(
                                  widget.student.name.isNotEmpty ? widget.student.name[0] : '?',
                                  style: TextStyle(
                                    color: avatarColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                      ),
                      if (widget.isSelected)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: themeColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.isDark ? const Color(0xFF252542) : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16), // Increased spacing
                // Main Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.student.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold, // Bolder name
                                color: widget.isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Larger badge
                            decoration: BoxDecoration(
                              color: _getRiskBgColor(widget.isDark),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.student.risk,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _getRiskColor(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6), // More spacing
                      Text(
                        'Roll: ${widget.student.roll} • ${widget.student.program} Sem ${widget.student.semester}',
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.isDark ? Colors.white70 : Colors.grey[600],
                          height: 1.3, // Better line height
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Overall Attendance: ${widget.student.overallPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.student.overallPercentage < 75 ? const Color(0xFFDC2626) : const Color(0xFF37B24D),
                        ),
                      ),
                    ],
                  ),
                ),
                // Expand Icon Button
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(), // Minify constraints
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: widget.isDark ? Colors.white70 : Colors.grey[700],
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Expanded Content
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Divider(color: widget.isDark ? Colors.white10 : Colors.grey[200]),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Defaulter in Subjects:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? Colors.white70 : Colors.grey[800],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.student.defaulterSubjects.map((subject) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF9FAFB),
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
                                  color: widget.isDark ? Colors.white : const Color(0xFF1F2937),
                                ),
                              ),
                              Text(
                                subject.code,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.isDark ? Colors.white38 : const Color(0xFF6B7280),
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
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final String? currentProgram;
  final int? currentSemester;
  final int currentThreshold;
  final List<dynamic> academicScopes; // From AcademicScope model
  final Function(String?, int?, int) onApply;
  final VoidCallback onReset;

  const _FilterBottomSheet({
    required this.currentProgram,
    required this.currentSemester,
    required this.currentThreshold,
    required this.academicScopes,
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
    final programs = widget.academicScopes
        .map((e) => e.programId.toString())
        .toSet()
        .toList();

    return CustomBottomSheetLayout(
      title: 'Filter Defaulters',
      onReset: widget.onReset,
      onApply: () => widget.onApply(_program, _semester, _threshold),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropdown<String>(
            label: 'Program',
            value: _program,
            items: programs,
            onChanged: (val) => setState(() {
              _program = val;
              _semester = null;
            }),
          ),
          const SizedBox(height: 16),
          _buildDropdown<int>(
            label: 'Semester',
            value: _semester,
            items: const [1, 2, 3, 4, 5, 6, 7, 8],
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