import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/data/models/clerk_analytics_model.dart';
import 'package:markmeapp/data/repositories/clerk_repository.dart';

class InsightsPanel extends ConsumerStatefulWidget {
  final String teacherId;
  final String subjectId;

  const InsightsPanel({
    super.key,
    required this.teacherId,
    required this.subjectId,
  });

  @override
  ConsumerState<InsightsPanel> createState() => _InsightsPanelState();
}

class _InsightsPanelState extends ConsumerState<InsightsPanel> {
  bool _isLoading = true;
  String? _error;
  ClerkSubjectInsightsModel? _data;

  @override
  void initState() {
    super.initState();
    _fetchInsights();
  }

  Future<void> _fetchInsights() async {
    try {
      final repo = ref.read(clerkRepositoryProvider);
      final result = await repo.fetchSubjectInsights(
        widget.teacherId,
        widget.subjectId,
      );

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _data = ClerkSubjectInsightsModel.fromJson(result);
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = result['error'] ?? 'Failed to load insights';
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
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_error != null) {
      // Return simpler error view for embedded panel
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text("Unable to load insights: $_error"),
      );
    }

    if (_data == null || _data!.insights.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Automated Insights",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            if (_data!.metrics != null)
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.blue),
                tooltip: "View raw metrics",
                onPressed: () => _showMetricsDialog(context, _data!.metrics!),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ..._data!.insights.map((insight) => _buildInsightCard(insight)),
      ],
    );
  }

  Widget _buildInsightCard(AnalysisInsight insight) {
    Color bg;
    Color border;
    IconData icon;
    Color iconColor;

    switch (insight.severity) {
      case 'CRITICAL': // Red
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFCA5A5);
        icon = Icons.error_outline;
        iconColor = const Color(0xFFEF4444);
        break;
      case 'WARNING': // Yellow
        bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFFCD34D);
        icon = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFF59E0B);
        break;
      case 'INFO':
      default: // Blue
        bg = const Color(0xFFEFF6FF);
        border = const Color(0xFFBFDBFE);
        icon = Icons.info_outline;
        iconColor = const Color(0xFF3B82F6);
        break;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight.text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF334155),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMetricsDialog(BuildContext context, InsightMetrics metrics) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Raw Metrics (Admin/Debug)"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricRow("Min Attendance", "${metrics.minAttendance}%"),
            _buildMetricRow("Max Attendance", "${metrics.maxAttendance}%"),
            _buildMetricRow("Volatility", "${metrics.volatility}%"),
            _buildMetricRow("Last 5 Avg", "${metrics.last5Avg}%"),
            _buildMetricRow("Prev 5 Avg", "${metrics.previous5Avg}%"),
            _buildMetricRow(
              "Trend Delta",
              "${metrics.trendDelta}%",
              isDelta: true,
            ),
            _buildMetricRow(
              "Low Attendance Sessions",
              "${metrics.lowAttendanceSessions}",
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {bool isDelta = false}) {
    Color? color;
    if (isDelta) {
      final val = double.tryParse(value.replaceAll('%', '')) ?? 0;
      if (val > 0)
        color = Colors.green;
      else if (val < 0)
        color = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
