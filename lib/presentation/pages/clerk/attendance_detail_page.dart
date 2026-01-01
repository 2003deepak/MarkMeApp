import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/core/utils/app_logger.dart';
import 'package:markmeapp/data/repositories/clerk_repository.dart';
import 'package:markmeapp/state/auth_state.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchData();
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
      // Ensure specific order if required by backend, usually sorted by roll number or ID
      // Assuming _allStudents is already sorted from _processAttendanceData
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
      appBar: AppBar(
        title: const Text(
          "Attendance Detail",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: const Color(0xFF1E293B),
        actions: [
          if (canEdit)
            if (_isEditing) ...[
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                tooltip: "Cancel",
                onPressed: _isSaving ? null : _toggleEditMode,
              ),
              IconButton(
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check, color: Color(0xFF2563EB)),
                tooltip: "Save",
                onPressed: _isSaving ? null : _saveAttendance,
              ),
            ] else
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB)),
                tooltip: "Edit Attendance",
                onPressed: _toggleEditMode,
              ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSessionInfoCard(session, attendance, teacher),
          const SizedBox(height: 16),
          _buildStatsCard(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Student List",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              if (_isEditing)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Text(
                    "Tap to toggle",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStudentList(),
        ],
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$program • Sem $semester • $component",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isException)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Color(0xFFEF4444),
                      ),
                      SizedBox(width: 4),
                      Text(
                        "Exception",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Divider(height: 32, color: Color(0xFFE2E8F0)),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.calendar_today_rounded,
                  label: "Date",
                  value: date,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.access_time_rounded,
                  label: "Marked At",
                  value: time,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
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

  Widget _buildStatsCard() {
    final total = _allStudents.length;
    final present = _attendanceMap.values.where((v) => v).length;
    final absent = total - present;

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            label: "Total Students",
            count: total.toString(),
            color: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            label: "Present",
            count: present.toString(),
            color: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            label: "Absent",
            count: absent.toString(),
            color: const Color(0xFFEF4444),
            bgColor: const Color(0xFFFEF2F2),
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
    if (_allStudents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text("No students recorded."),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _allStudents.length,
      itemBuilder: (context, index) {
        final student = _allStudents[index];
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

    // Visual styles for present/absent
    final Color statusColor = isPresent
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final Color bgColor = isPresent
        ? const Color(0xFFECFDF5)
        : const Color(0xFFFEF2F2);
    final Color borderColor = isPresent
        ? const Color(0xFFA7F3D0)
        : const Color(0xFFFECACA);

    return GestureDetector(
      onTap: _isEditing
          ? () {
              setState(() {
                _attendanceMap[id] = !isPresent;
              });
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isEditing
                ? (isPresent ? const Color(0xFF2563EB) : Colors.grey.shade300)
                : Colors.grey.shade200,
            width: _isEditing && isPresent ? 2 : 1,
          ),
          boxShadow: [
            if (_isEditing && isPresent)
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: profilePic != null
                    ? NetworkImage(profilePic)
                    : null,
                child: profilePic == null
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
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
            "Roll No: $rollNo",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              isPresent ? "Present" : "Absent",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
