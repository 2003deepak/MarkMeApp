import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AttendanceChartWidget extends StatefulWidget {
  final Map<String, Map<String, dynamic>> subjectData;
  final String? selectedSubject;
  final bool isDesktop;

  const AttendanceChartWidget({
    super.key,
    required this.subjectData,
    required this.selectedSubject,
    required this.isDesktop,
  });

  @override
  State<AttendanceChartWidget> createState() => _AttendanceChartWidgetState();
}

class _AttendanceChartWidgetState extends State<AttendanceChartWidget>
    with TickerProviderStateMixin {
  AnimationController? _scaleController;
  Animation<double>? _scaleAnimation;

  int touchedIndex = -1;

  // <CHANGE> soft palette + UI tokens
  static const Color _bgStart = Color(0xFFF8FAFF);
  static const Color _bgEnd = Color(0xFFFFFFFF);
  static const Color _cardBorder = Color(0xFFE5E7EB);
  static const Color _iconTint = Color(0xFFE0EAFF);
  static const Color _absentColor = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _scaleController!, curve: Curves.elasticOut),
    );
  }

  // <CHANGE> refined color mapping for attendance
  Color _getAttendanceColor(double percentage) {
    if (percentage >= 75) return const Color(0xFF10B981); // emerald
    if (percentage >= 60) return const Color(0xFFF59E0B); // amber
    if (percentage >= 45) return const Color(0xFFFB923C); // orange
    return const Color(0xFFEF4444); // red
  }

  // <CHANGE> helper to compute current stats once
  ({int attended, int total, int missed, double percentage, Color color})
  _currentStats() {
    if (widget.selectedSubject != null) {
      final data = widget.subjectData[widget.selectedSubject]!;
      final attended = data['attendedLectures'] as int;
      final total = data['totalLectures'] as int;
      final missed = (total - attended).clamp(0, total);
      final percentage = total == 0 ? 0.0 : (attended / total) * 100.0;
      return (
        attended: attended,
        total: total,
        missed: missed,
        percentage: percentage,
        color: _getAttendanceColor(percentage),
      );
    } else {
      int totalLectures = 0;
      int totalAttended = 0;
      for (var subject in widget.subjectData.values) {
        totalLectures += subject['totalLectures'] as int;
        totalAttended += subject['attendedLectures'] as int;
      }
      final missed = (totalLectures - totalAttended).clamp(0, totalLectures);
      final overallPercentage = totalLectures == 0
          ? 0.0
          : (totalAttended / totalLectures) * 100.0;
      return (
        attended: totalAttended,
        total: totalLectures,
        missed: missed,
        percentage: overallPercentage,
        color: _getAttendanceColor(overallPercentage),
      );
    }
  }

  // <CHANGE> consistent ring sizing: base radius is always larger than center
  List<PieChartSectionData> _getPieChartSections({
    required double percentage,
    required int attended,
    required int missed,
    required Color presentColor,
  }) {
    final bool isDesktop = widget.isDesktop;
    final double chartSize = isDesktop ? 180 : 160;

    // ring thickness target
    final double ringThickness = isDesktop ? 20 : 18;
    // choose a center space that leaves room for label
    final double centerSpaceRadius = isDesktop ? 58 : 52;
    // derive base radius from center + thickness
    final double baseRadius = centerSpaceRadius + ringThickness;
    final double touchedRadius = baseRadius + (isDesktop ? 6 : 5);

    // titles kept empty for a cleaner donut, we show the main % in the center
    return [
      PieChartSectionData(
        color: presentColor,
        value: attended.toDouble(),
        title: '',
        radius: touchedIndex == 0 ? touchedRadius : baseRadius,
      ),
      PieChartSectionData(
        color: _absentColor,
        value: missed.toDouble(),
        title: '',
        radius: touchedIndex == 1 ? touchedRadius : baseRadius,
      ),
    ];
  }

  @override
  void dispose() {
    _scaleController?.dispose();
    super.dispose();
  }

  Widget _buildLegendItem(String label, Color color, {String? sub}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: widget.isDesktop ? 14 : 12,
          height: widget.isDesktop ? 14 : 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          sub == null ? label : '$label ($sub)',
          style: TextStyle(
            fontSize: widget.isDesktop ? 15 : 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend({
    required int attended,
    required int missed,
    required Color presentColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('Present', presentColor, sub: '$attended'),
        _buildLegendItem('Absent', _absentColor, sub: '$missed'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Initialize animations if they haven't been initialized yet
    if (_scaleController == null) {
      _initializeAnimations();
    }

    final stats = _currentStats();

    final bool isDesktop = widget.isDesktop;
    final double centerSpaceRadius = isDesktop ? 58 : 52;
    final double sectionsSpace = isDesktop ? 6 : 5;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        // <CHANGE> soft gradient + thin border + subtle shadow
        gradient: const LinearGradient(
          colors: [_bgStart, _bgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          Center(
            child: _scaleController == null || _scaleAnimation == null
                ? SizedBox(
                    height: isDesktop ? 200 : 180,
                    width: isDesktop ? 240 : 220,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : AnimatedBuilder(
                    animation: _scaleController!,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation!.value,
                        child: SizedBox(
                          height: isDesktop ? 240 : 220,
                          width: isDesktop ? 240 : 220,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    touchCallback:
                                        (FlTouchEvent event, pieTouchResponse) {
                                          setState(() {
                                            if (!event
                                                    .isInterestedForInteractions ||
                                                pieTouchResponse == null ||
                                                pieTouchResponse
                                                        .touchedSection ==
                                                    null) {
                                              touchedIndex = -1;
                                              _scaleController!.reverse();
                                              return;
                                            }
                                            touchedIndex = pieTouchResponse
                                                .touchedSection!
                                                .touchedSectionIndex;
                                            _scaleController!.forward();
                                          });
                                        },
                                  ),
                                  borderData: FlBorderData(show: false),
                                  // <CHANGE> wider spacing for a crisp separation
                                  sectionsSpace: sectionsSpace,
                                  // <CHANGE> consistent center space; sections radii are derived above
                                  centerSpaceRadius: centerSpaceRadius,
                                  sections: _getPieChartSections(
                                    percentage: stats.percentage,
                                    attended: stats.attended,
                                    missed: stats.missed,
                                    presentColor: stats.color,
                                  ),
                                ),
                              ),
                              // <CHANGE> Center content (main percentage)
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${stats.percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 28 : 24,
                                      fontWeight: FontWeight.w800,
                                      color: stats.color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'present',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 13 : 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 30),

          // <CHANGE> Better legend with counts
          _buildLegend(
            attended: stats.attended,
            missed: stats.missed,
            presentColor: stats.color,
          ),
        ],
      ),
    );
  }
}
