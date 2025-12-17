import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/data/models/clerk_analytics_model.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';
import 'package:markmeapp/data/repositories/clerk_repository.dart';
import 'package:markmeapp/presentation/widgets/clerk/insights_panel.dart';

class SubjectAnalyticsDetailPage extends ConsumerStatefulWidget {
  final String teacherId;
  final String subjectId;

  const SubjectAnalyticsDetailPage({
    super.key,
    required this.teacherId,
    required this.subjectId,
  });

  @override
  ConsumerState<SubjectAnalyticsDetailPage> createState() =>
      _SubjectAnalyticsDetailPageState();
}

class _SubjectAnalyticsDetailPageState
    extends ConsumerState<SubjectAnalyticsDetailPage> {
  bool _isLoading = true;
  String? _error;
  ClerkSubjectDetailModel? _data;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final repo = ref.read(clerkRepositoryProvider);
      final result = await repo.fetchSubjectPerformanceDetail(
        widget.teacherId,
        widget.subjectId,
      );

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _data = ClerkSubjectDetailModel.fromJson(result);
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = result['error'] ?? 'Failed to load details';
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
    if (_data == null && _isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Safety check if data load failed
    final subjectName = _data?.subjectInfo.subjectName ?? "Subject Detail";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: MarkMeAppBar(title: subjectName),
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
          _buildHeader(),
          const SizedBox(height: 16),
          _buildKPIStrip(),
          const SizedBox(height: 24),
          _buildMainContent(),
          const SizedBox(height: 24),
          InsightsPanel(
            teacherId: widget.teacherId,
            subjectId: widget.subjectId,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final info = _data!.subjectInfo;
    final statusColor = _getStatusColor(info.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            info.subjectName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  info.component,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(info.status),
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Status: ${info.status}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
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

  Widget _buildKPIStrip() {
    final kpis = _data!.kpis;
    return Row(
      children: [
        Expanded(
          child: _buildMiniKPICard(
            "Avg Attendance",
            "${kpis.averageAttendance.toStringAsFixed(1)}%",
            _getAttendanceColor(kpis.averageAttendance),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniKPICard(
            "Sessions Conducted",
            "${kpis.totalSessions}",
            Colors.blueGrey,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniKPICard(
            "Risk Students",
            "${kpis.riskStudents}",
            kpis.riskStudents > 0 ? Colors.red : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniKPICard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    // Determine layout based on width: here usually mobile so simple Column.
    // Spec asks for Left Column (Chart) & Right Column (Session Health).
    // On mobile this will be stacked. Left -> Top, Right -> Bottom.
    return Column(
      children: [
        _buildAttendanceChart(),
        const SizedBox(height: 24),
        _buildSessionHealth(),
      ],
    );
  }

  Widget _buildAttendanceChart() {
    // Process trend data
    final spots = _data!.attendanceTrend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.attendance);
    }).toList();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Attendance Trend",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                  // Add a threshold line at 60%?
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 60),
                      FlSpot(
                        (spots.isEmpty ? 1 : spots.length - 1).toDouble(),
                        60,
                      ),
                    ],
                    isCurved: false,
                    color: Colors.red.withOpacity(0.5),
                    barWidth: 1,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: false),
                  ),
                ],
                minY: 0,
                maxY: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionHealth() {
    final health = _data!.sessionHealth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Session Health",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          children: [
            _buildHealthCard(
              "Weekly Slots",
              "${health.weeklySlots}",
              Colors.blue,
              Icons.calendar_view_week,
            ),
            _buildHealthCard(
              "Conducted",
              "${health.conductedSessions}",
              Colors.green,
              Icons.check_circle_outline,
            ),
            _buildHealthCard(
              "Cancelled",
              "${health.cancelledSessions}",
              Colors.red,
              Icons.cancel_outlined,
              isWarning: health.cancelledSessions > 2,
            ),
            _buildHealthCard(
              "Rescheduled",
              "${health.rescheduledSessions}",
              Colors.orange,
              Icons.update,
              isWarning: health.rescheduledSessions > 2,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthCard(
    String title,
    String value,
    Color color,
    IconData icon, {
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning ? Colors.red.shade200 : Colors.grey.shade200,
          width: isWarning ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              if (isWarning)
                const Icon(Icons.warning, color: Colors.red, size: 16),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
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

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'WARNING':
        return Icons.warning_amber_rounded;
      case 'CRITICAL':
        return Icons.error_outline;
      case 'GOOD':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  Color _getAttendanceColor(double attendance) {
    if (attendance >= 80) return const Color(0xFF10B981);
    if (attendance >= 65) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}
