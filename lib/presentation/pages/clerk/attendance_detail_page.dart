import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/data/repositories/clerk_repository.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';

class AttendanceDetailPage extends ConsumerStatefulWidget {
  final String attendanceId;

  // Constructor simplified to accept only ID
  const AttendanceDetailPage({super.key, required this.attendanceId});

  @override
  ConsumerState<AttendanceDetailPage> createState() =>
      _AttendanceDetailPageState();
}

class _AttendanceDetailPageState extends ConsumerState<AttendanceDetailPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _attendanceData;

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
          setState(() {
            _attendanceData = result['data']; // The entire JSON response
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light grey background
      appBar: MarkMeAppBar(title: "Attendance Detail"),
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

    // Extract sections
    final session = _attendanceData!['session'] ?? {};
    final attendance = _attendanceData!['attendance'] ?? {};
    final teacher = _attendanceData!['teacher'] ?? {};
    final students = _attendanceData!['students'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSessionInfoCard(session, attendance, teacher),
          const SizedBox(height: 16),
          _buildStatsCard(students),
          const SizedBox(height: 24),
          const Text(
            "Student List",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          _buildStudentList(students),
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
          // Header Row: Subject & Component
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

          // Details Grid
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

  Widget _buildStatsCard(Map students) {
    final total = students['total'] ?? 0;
    final present = students['present_count'] ?? 0;
    final absent = students['absent_count'] ?? 0;
    // Calculate percentage if needed, but counts are good enough.

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

  Widget _buildStudentList(Map students) {
    final presentList = List.from(students['present'] ?? []);
    final absentList = List.from(students['absent'] ?? []);
    final allStudents = [...presentList, ...absentList];

    // Sort by roll number if available or name
    allStudents.sort((a, b) {
      final rollA = int.tryParse(a['roll_no']?.toString() ?? '0') ?? 0;
      final rollB = int.tryParse(b['roll_no']?.toString() ?? '0') ?? 0;
      return rollA.compareTo(rollB);
    });

    if (allStudents.isEmpty) {
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
      itemCount: allStudents.length,
      itemBuilder: (context, index) {
        final student = allStudents[index];
        final id = student['id'];

        // Determine status by checking if ID is in present list or absent list
        // Or simpler: check if this object is in presentList via ID
        final isPresent = presentList.any((s) => s['id'] == id);

        return _buildStudentTile(student, isPresent);
      },
    );
  }

  Widget _buildStudentTile(Map student, bool isPresent) {
    final name = student['name'] ?? 'Unknown';
    final rollNo = student['roll_no']?.toString() ?? 'N/A';
    final profilePic = student['profile_picture'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: profilePic != null ? NetworkImage(profilePic) : null,
          child: profilePic == null
              ? const Icon(Icons.person, color: Colors.grey)
              : null,
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
            color: isPresent
                ? const Color(0xFFECFDF5)
                : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPresent
                  ? const Color(0xFF10B981).withOpacity(0.3)
                  : const Color(0xFFEF4444).withOpacity(0.3),
            ),
          ),
          child: Text(
            isPresent ? "Present" : "Absent",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPresent
                  ? const Color(0xFF059669)
                  : const Color(0xFFDC2626),
            ),
          ),
        ),
      ),
    );
  }
}
