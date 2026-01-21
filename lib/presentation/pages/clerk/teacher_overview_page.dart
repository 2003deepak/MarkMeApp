import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/models/clerk_analytics_model.dart';
import 'package:markmeapp/data/repositories/clerk_repository.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';

class TeacherOverviewPage extends ConsumerStatefulWidget {
  final String teacherId;
  final String teacherName;

  const TeacherOverviewPage({
    super.key,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  ConsumerState<TeacherOverviewPage> createState() =>
      _TeacherOverviewPageState();
}

class _TeacherOverviewPageState extends ConsumerState<TeacherOverviewPage> {
  bool _isLoading = true;
  String? _error;
  ClerkTeacherPerformanceModel? _data;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final repo = ref.read(clerkRepositoryProvider);
      final result = await repo.fetchTeacherSubjectPerformance(
        widget.teacherId,
      );

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _data = ClerkTeacherPerformanceModel.fromJson(result);
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: MarkMeAppBar(title: widget.teacherName),
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
            Text("Error: $_error", style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _fetchData, child: const Text("Retry")),
          ],
        ),
      );
    }

    if (_data == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKPISection(_data!.kpis),
          const SizedBox(height: 24),
          const Text(
            "Subject Performance",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          _buildSubjectList(_data!.subjects),
        ],
      ),
    );
  }

  Widget _buildKPISection(TeacherKPIs kpis) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                "Subjects",
                kpis.subjectsCount.toString(),
                Icons.book_outlined,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                "Avg Attendance",
                "${kpis.averageAttendance.toStringAsFixed(1)}%",
                Icons.people_outline,
                _getAttendanceColor(kpis.averageAttendance),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                "Total Sessions",
                kpis.totalSessions.toString(),
                Icons.calendar_today_outlined,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                "Risk Students",
                kpis.riskStudents.toString(),
                Icons.warning_amber_rounded,
                kpis.riskStudents > 0 ? Colors.red : Colors.green,
                showWarning: kpis.riskStudents > 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool showWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              if (showWarning)
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectList(List<TeacherSubject> subjects) {
    if (subjects.isEmpty) {
      return const Center(child: Text("No subjects found"));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        return _buildSubjectCard(subject);
      },
    );
  }

  Widget _buildSubjectCard(TeacherSubject subject) {
    final statusColor = _getStatusColor(subject.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            context.push(
              '/clerk/teacher/${widget.teacherId}/subject/${subject.subjectId}',
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.class_outlined, color: statusColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.subjectName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${subject.component} • ${subject.totalSessions} Sessions",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${subject.averageAttendance.toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getAttendanceColor(subject.averageAttendance),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        subject.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getAttendanceColor(double attendance) {
    if (attendance >= 80) return const Color(0xFF10B981); // Green
    if (attendance >= 65) return const Color(0xFFF59E0B); // Yellow
    return const Color(0xFFEF4444); // Red
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'WARNING':
        return Colors.orange;
      case 'CRITICAL':
        return Colors.red;
      case 'GOOD':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
