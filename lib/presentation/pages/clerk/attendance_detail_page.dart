import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/core/utils/app_logger.dart';
import 'package:markmeapp/data/repositories/clerk_repository.dart';
import 'package:markmeapp/state/auth_state.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';
import 'package:markmeapp/presentation/widgets/ui/search_bar.dart';
import 'package:flutter/services.dart';
import 'package:markmeapp/core/theme/app_theme.dart';
import 'package:markmeapp/core/utils/date_formatters.dart';
import 'package:intl/intl.dart';

class AttendanceDetailPage extends ConsumerStatefulWidget {
  final String attendanceId;

  const AttendanceDetailPage({super.key, required this.attendanceId});

  @override
  ConsumerState<AttendanceDetailPage> createState() =>
      _AttendanceDetailPageState();
}

class _AttendanceDetailPageState extends ConsumerState<AttendanceDetailPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _attendanceData;

  // Edit Mode State
  bool _isEditing = false;
  bool _isSaving = false;
  final Map<String, bool> _attendanceMap = {};
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];

  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final repo = ref.read(clerkRepositoryProvider);
      final result = await repo.fetchAttendanceDetail(widget.attendanceId);

      if (mounted) {
        if (result['success'] == true) {
          final data = result['data'];
          _processAttendanceData(data);
          setState(() {
            _attendanceData = data;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = result['error'] ?? 'Failed to load data';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _processAttendanceData(Map<String, dynamic> data) {
    // Populate attendance map and student list for editing
    final studentsData = data['students'] ?? {};
    final presentList = List<Map<String, dynamic>>.from(
      studentsData['present'] ?? [],
    );
    final absentList = List<Map<String, dynamic>>.from(
      studentsData['absent'] ?? [],
    );

    _allStudents = [...presentList, ...absentList];

    // Sort students by roll number
    _allStudents.sort((a, b) {
      final rollA = int.tryParse(a['roll_no']?.toString() ?? '0') ?? 0;
      final rollB = int.tryParse(b['roll_no']?.toString() ?? '0') ?? 0;
      return rollA.compareTo(rollB);
    });

    _attendanceMap.clear();
    for (var s in presentList) {
      _attendanceMap[s['id'].toString()] = true;
    }
    for (var s in absentList) {
      _attendanceMap[s['id'].toString()] = false;
    }

    _filterStudents();
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredStudents = _allStudents.where((student) {
        final name = (student['name']?.toString() ?? '').toLowerCase();
        final rollNo = (student['roll_no']?.toString() ?? '').toLowerCase();
        final matchesQuery = name.contains(query) || rollNo.contains(query);

        final id = student['id'].toString();
        final isPresent = _attendanceMap[id] ?? false;

        if (_selectedFilter == 'present') {
          return matchesQuery && isPresent;
        } else if (_selectedFilter == 'absent') {
          return matchesQuery && !isPresent;
        }
        return matchesQuery;
      }).toList();
    });
  }

  void _toggleEditMode() async {
    if (_isEditing) {
      // Logic for Cancel/Reset
      setState(() {
        _isEditing = false;
        // Re-process original data to reset changes
        if (_attendanceData != null) {
          _processAttendanceData(_attendanceData!);
        }
      });
    } else {
      setState(() {
        _isEditing = true;
      });
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);
    try {
      // 1. Generate BitString
      final bitString = StringBuffer();
      
      for (final student in _allStudents) {
        final id = student['id'].toString();
        final isPresent = _attendanceMap[id] ?? false;
        bitString.write(isPresent ? '1' : '0');
      }

      AppLogger.info("Saving Attendance BitString: ${bitString.toString()}");

      // 2. Call API
      final repo = ref.read(clerkRepositoryProvider);
      final result = await repo.updateAttendance(
        widget.attendanceId,
        bitString.toString(),
      );

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attendance updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _isEditing = false;
            // Optionally refresh data to be sure
            _fetchData();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to update'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(authStoreProvider).role;
    final canEdit =
        (userRole == 'admin' || userRole == 'clerk') &&
        !_isLoading &&
        _error == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: MarkMeAppBar(
        title: "Attendance Detail",
        actions: [
          if (canEdit)
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: "Cancel",
                onPressed: _isSaving ? null : _toggleEditMode,
              )
            else
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                tooltip: "Edit Attendance",
                onPressed: _toggleEditMode,
              ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _isEditing ? _buildBottomSubmitBar() : null,
    );
  }

  Widget _buildBottomSubmitBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildSubmitButton(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Error: $_error",
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchData, child: const Text("Retry")),
          ],
        ),
      );
    }

    if (_attendanceData == null) {
      return const Center(child: Text("No data available"));
    }

    final session = _attendanceData!['session'] ?? {};
    final attendance = _attendanceData!['attendance'] ?? {};
    final teacher = _attendanceData!['teacher'] ?? {};

    final presentCount = _attendanceMap.values.where((v) => v).length;
    final totalCount = _allStudents.length;
    final absentCount = totalCount - presentCount;

    return Column(
      children: [
        // 1. Search Bar (Sticky)
        _buildSearchBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Session Info Card
                _buildSessionInfoCard(session, attendance, teacher),
                const SizedBox(height: 20),
                // 3. Filter Chips
                _buildFilterChips(presentCount, absentCount),
                const SizedBox(height: 16),
                
                // 5. Student List
                _buildStudentList(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveAttendance,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Submit Attendance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.white,
      child: AppSearchBar(
        controller: _searchController,
        hintText: 'Search students...',
        onChanged: (value) => _filterStudents(),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildFilterChips(int presentCount, int absentCount) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('all', 'All (${_allStudents.length})'),
          const SizedBox(width: 10),
          _buildFilterChip('present', 'Present ($presentCount)'),
          const SizedBox(width: 10),
          _buildFilterChip('absent', 'Absent ($absentCount)'),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(int presentCount, int absentCount) {
    return const SizedBox.shrink(); // Legacy placeholder
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionInfoCard(Map session, Map attendance, Map teacher) {
    final isException = attendance['is_exception_session'] == true;
    final subject = session['subject'] ?? 'Unknown Subject';
    final component = session['component'] ?? 'N/A';
    final program = session['program'] ?? '';
    final semester = session['semester']?.toString() ?? '';
    final date = attendance['marked_date'] ?? '';
    final time = attendance['marked_time'] ?? '';
    final teacherName = teacher['name'] ?? 'Unknown Teacher';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "$program • Sem $semester • $component",
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isException) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: Color(0xFFEF4444),
                  ),
                  SizedBox(width: 6),
                  Text(
                    "Exception Session",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 32, color: Color(0xFFF1F5F9), thickness: 1.5),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.calendar_today_rounded,
                  label: "Marked Day",
                  value: AppDateFormatters.formatDay(date),
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.calendar_month_rounded,
                  label: "Marked Date",
                  value: AppDateFormatters.formatDate(date),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.access_time_rounded,
                  label: "Marked Time",
                  value: AppDateFormatters.formatTime(time),
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.person_outline_rounded,
                  label: "Teacher",
                  value: teacherName,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildStatItem({
    required String label,
    required String count,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    if (_filteredStudents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                "No students found matching your criteria.",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        final id = student['id'].toString();
        final isPresent = _attendanceMap[id] ?? false;

        return _buildStudentTile(student, isPresent);
      },
    );
  }

  Widget _buildStudentTile(Map student, bool isPresent) {
    final name = student['name'] ?? 'Unknown';
    final rollNo = student['roll_no']?.toString() ?? 'N/A';
    final profilePic = student['profile_picture'];
    final id = student['id'].toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF1F5F9),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: ClipOval(
                child: profilePic != null && profilePic.toString().isNotEmpty
                    ? Image.network(
                        profilePic,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person, size: 20, color: Color(0xFF64748B)),
                      )
                    : const Icon(Icons.person, size: 20, color: Color(0xFF64748B)),
              ),
            ),
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPresent ? Icons.check_circle : Icons.circle_outlined,
                    size: 14,
                    color: isPresent ? Colors.green : Colors.grey,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          "ID: $rollNo",
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPresent ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            isPresent ? "Present" : "Absent",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        onTap: _isEditing
            ? () {
                setState(() {
                  _attendanceMap[id] = !isPresent;
                  _filterStudents(); // Update filtered list if needed, though toggle doesn't change query/filter status
                });
                HapticFeedback.lightImpact();
              }
            : null,
      ),
    );
  }
}
