import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:markmeapp/data/models/attendance_trends_model.dart';

class TrendsChartCard extends StatefulWidget {
  final List<AttendanceTrendData>? data;
  final bool isLoading;
  final String selectedPeriod;
  final Function(String) onPeriodChanged;

  const TrendsChartCard({
    super.key,
    required this.data,
    required this.isLoading,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  State<TrendsChartCard> createState() => _TrendsChartCardState();
}

class _TrendsChartCardState extends State<TrendsChartCard> {
  List<FlSpot> _generateSpots() {
    if (widget.data == null || widget.data!.isEmpty) {
      return const [];
    }
    return List.generate(widget.data!.length, (index) {
      return FlSpot(index.toDouble(), widget.data![index].attendance);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    "Weekly Overview",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    "Attendance vs. Enrollment",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: ["Week", "Month"].map((tab) => _buildChartTab(tab)).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1E293B),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)}%',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Color(0xFFF1F5F9),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final style = Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.bold,
                        );
                        final index = value.toInt();
                        if (widget.data == null || index < 0 || index >= widget.data!.length) {
                          return const SizedBox.shrink();
                        }
                        
                        // For labels like "Week 1", maybe abbreviate to "W1" to fit
                        String label = widget.data![index].label;
                        if (label.startsWith('Week ')) {
                           label = 'W${label.split(' ')[1]}';
                        } else if (label.length > 3) {
                           label = label.substring(0, 3).toUpperCase();
                        }
                        
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(label, style: style),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (widget.data == null || widget.data!.isEmpty) ? 0 : (widget.data!.length - 1).toDouble(),
                minY: 0,
                maxY: 100, // Assuming 100% is the maximum attendance
                lineBarsData: [
                  if (widget.data != null && widget.data!.isNotEmpty)
                    LineChartBarData(
                      spots: _generateSpots(),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: const Color(0xFF2563EB),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2563EB).withOpacity(0.1),
                          const Color(0xFF3B82F6).withOpacity(0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTab(String label) {
    // Map "Week" -> "week", "Month" -> "month"
    final apiRange = label.toLowerCase();
    final isActive = widget.selectedPeriod == apiRange;
    return GestureDetector(
      onTap: () => widget.onPeriodChanged(apiRange),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isActive ? const Color(0xFF1E293B) : const Color(0xFF64748B),
              ),
        ),
      ),
    );
  }
}
