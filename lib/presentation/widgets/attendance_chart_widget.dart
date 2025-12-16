import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AttendanceChartWidget extends StatefulWidget {
  final Map<String, dynamic>? selectedData;
  final String? selectedSubject;
  final bool isDesktop;

  const AttendanceChartWidget({
    super.key,
    required this.selectedData,
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

  static const Color _bgStart = Color(0xFFF8FAFF);
  static const Color _bgEnd = Color(0xFFFFFFFF);
  static const Color _cardBorder = Color(0xFFE5E7EB);
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

  Color _getAttendanceColor(double percentage) {
    if (percentage == 0) return _absentColor; // Return absent color for 0%
    if (percentage >= 75) return const Color(0xFF10B981); // green
    if (percentage >= 60) return const Color(0xFFF59E0B); // amber
    if (percentage >= 45) return const Color(0xFFFB923C); // orange
    return const Color(0xFFEF4444); // red
  }

  ({int attended, int total, int missed, double percentage, Color color})
  _currentStats() {
    final data = widget.selectedData;

    if (data == null) {
      return (
        attended: 0,
        total: 0,
        missed: 0,
        percentage: 0.0,
        color: _getAttendanceColor(0.0),
      );
    }

    final attended = data['attendedLectures'] as int? ?? 0;
    final total = data['totalLectures'] as int? ?? 0;
    final missed = (total - attended).clamp(0, total);
    final percentage = data['percentage'] as double? ?? 0.0;

    return (
      attended: attended,
      total: total,
      missed: missed,
      percentage: percentage,
      color: _getAttendanceColor(percentage),
    );
  }

  List<PieChartSectionData> _getPieChartSections({
    required double percentage,
    required int attended,
    required int missed,
    required Color presentColor,
  }) {
    final bool isDesktop = widget.isDesktop;
    final double ringThickness = isDesktop ? 20 : 18;
    final double centerSpaceRadius = isDesktop ? 45 : 40;
    final double baseRadius = centerSpaceRadius + ringThickness;
    final double touchedRadius = baseRadius + (isDesktop ? 5 : 4);

    // When attendance is 0%, show only one section for absent
    if (attended == 0 && missed > 0) {
      return [
        PieChartSectionData(
          color: _absentColor,
          value: missed.toDouble(),
          title: '',
          radius: touchedIndex == 0 ? touchedRadius : baseRadius,
        ),
      ];
    }

    // When both attended and missed are 0, show a single absent section
    if (attended == 0 && missed == 0) {
      return [
        PieChartSectionData(
          color: _absentColor,
          value: 1.0, // Use a small value to ensure the circle is drawn
          title: '',
          radius: touchedIndex == 0 ? touchedRadius : baseRadius,
        ),
      ];
    }

    // Normal case with both present and absent
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
    // When attendance is 0%, only show absent in legend
    if (attended == 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem('Present', presentColor, sub: '$attended'),
          _buildLegendItem('Absent', _absentColor, sub: '$missed'),
        ],
      );
    }

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
    if (_scaleController == null) {
      _initializeAnimations();
    }

    final stats = _currentStats();

    final bool isDesktop = widget.isDesktop;
    final double centerSpaceRadius = isDesktop ? 52 : 46;
    final double sectionsSpace = isDesktop ? 5 : 4;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_bgStart, _bgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          Center(
            child: _scaleController == null || _scaleAnimation == null
                ? SizedBox(
                    height: isDesktop ? 240 : 220,
                    width: isDesktop ? 240 : 220,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : AnimatedBuilder(
                    animation: _scaleController!,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation!.value,
                        child: SizedBox(
                          height: isDesktop ? 240 : 200,
                          width: isDesktop ? 240 : 200,
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
                                  sectionsSpace: sectionsSpace,
                                  centerSpaceRadius: centerSpaceRadius,
                                  sections: _getPieChartSections(
                                    percentage: stats.percentage,
                                    attended: stats.attended,
                                    missed: stats.missed,
                                    presentColor: stats.color,
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${stats.percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 26 : 22,
                                      fontWeight: FontWeight.w800,
                                      color: stats.attended == 0
                                          ? _absentColor
                                          : stats.color,
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

          const SizedBox(height: 40),

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
