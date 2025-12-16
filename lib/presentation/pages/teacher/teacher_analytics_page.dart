import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TeacherAnalyticsPage extends StatefulWidget {
  const TeacherAnalyticsPage({super.key});

  @override
  State<TeacherAnalyticsPage> createState() => _TeacherAnalyticsPageState();
}

class _TeacherAnalyticsPageState extends State<TeacherAnalyticsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _chartController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _chartAnimation;

  String selectedPeriod = 'This Month';
  String selectedSubject = 'All Subjects';

  // Mock analytics data
  final Map<String, List<FlSpot>> attendanceData = {
    'This Week': [
      FlSpot(0, 85),
      FlSpot(1, 88),
      FlSpot(2, 82),
      FlSpot(3, 90),
      FlSpot(4, 87),
      FlSpot(5, 85),
      FlSpot(6, 89),
    ],
    'This Month': [
      FlSpot(0, 85),
      FlSpot(1, 87),
      FlSpot(2, 89),
      FlSpot(3, 86),
      FlSpot(4, 88),
      FlSpot(5, 90),
      FlSpot(6, 87),
      FlSpot(7, 89),
      FlSpot(8, 91),
      FlSpot(9, 88),
    ],
  };

  final Map<String, Map<String, dynamic>> subjectStats = {
    'Data Structures': {
      'totalStudents': 45,
      'averageAttendance': 87.5,
      'totalLectures': 28,
      'completedLectures': 25,
      'color': Colors.blue,
    },
    'Algorithms': {
      'totalStudents': 42,
      'averageAttendance': 82.3,
      'totalLectures': 30,
      'completedLectures': 27,
      'color': Colors.green,
    },
    'Database Systems': {
      'totalStudents': 38,
      'averageAttendance': 90.1,
      'totalLectures': 26,
      'completedLectures': 24,
      'color': Colors.orange,
    },
  };

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chartController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _chartController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.grey.shade700,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Student Analytics',
          style: TextStyle(
            fontSize: isDesktop ? 24 : 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics,
                  size: isDesktop ? 24 : 20,
                  color: Colors.blue.shade600,
                ),
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterSection(isDesktop),
              const SizedBox(height: 24),
              _buildOverviewCards(isDesktop),
              const SizedBox(height: 24),
              _buildAttendanceTrendChart(isDesktop),
              const SizedBox(height: 24),
              _buildSubjectPerformance(isDesktop),
              const SizedBox(height: 24),
              _buildStudentDistribution(isDesktop),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics Filters',
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  'Period',
                  selectedPeriod,
                  ['This Week', 'This Month', 'This Semester'],
                  (value) => setState(() => selectedPeriod = value!),
                  isDesktop,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  'Subject',
                  selectedSubject,
                  [
                    'All Subjects',
                    'Data Structures',
                    'Algorithms',
                    'Database Systems',
                  ],
                  (value) => setState(() => selectedSubject = value!),
                  isDesktop,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 14 : 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : 12,
                      color: Colors.black87,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCards(bool isDesktop) {
    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            'Total Students',
            '125',
            Icons.people,
            Colors.blue,
            '+5 this month',
            isDesktop,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Avg Attendance',
            '86.3%',
            Icons.trending_up,
            Colors.green,
            '+2.1% from last month',
            isDesktop,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Total Lectures',
            '84',
            Icons.school,
            Colors.orange,
            '12 this week',
            isDesktop,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
    bool isDesktop,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: Container(
            padding: EdgeInsets.all(isDesktop ? 20 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: isDesktop ? 24 : 20,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: isDesktop ? 24 : 20,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isDesktop ? 12 : 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceTrendChart(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart,
                color: Colors.blue.shade600,
                size: isDesktop ? 28 : 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Attendance Trend',
                style: TextStyle(
                  fontSize: isDesktop ? 20 : 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _chartAnimation,
            builder: (context, child) {
              return SizedBox(
                height: isDesktop ? 300 : 250,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 10,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            const style = TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            );
                            Widget text;
                            switch (value.toInt()) {
                              case 0:
                                text = const Text('Mon', style: style);
                                break;
                              case 1:
                                text = const Text('Tue', style: style);
                                break;
                              case 2:
                                text = const Text('Wed', style: style);
                                break;
                              case 3:
                                text = const Text('Thu', style: style);
                                break;
                              case 4:
                                text = const Text('Fri', style: style);
                                break;
                              case 5:
                                text = const Text('Sat', style: style);
                                break;
                              case 6:
                                text = const Text('Sun', style: style);
                                break;
                              default:
                                text = const Text('', style: style);
                                break;
                            }
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: text,
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 10,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Text(
                              '${value.toInt()}%',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            );
                          },
                          reservedSize: 42,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: 6,
                    minY: 70,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: attendanceData[selectedPeriod]!
                            .take(7)
                            .map(
                              (spot) => FlSpot(
                                spot.x,
                                spot.y * _chartAnimation.value +
                                    70 * (1 - _chartAnimation.value),
                              ),
                            )
                            .toList(),
                        isCurved: true,
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: Colors.blue.shade600,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade100.withValues(alpha: 0.3),
                              Colors.blue.shade50.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectPerformance(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.subject,
                color: Colors.green.shade600,
                size: isDesktop ? 28 : 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Subject Performance',
                style: TextStyle(
                  fontSize: isDesktop ? 20 : 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...subjectStats.entries.map((entry) {
            return _buildSubjectCard(entry.key, entry.value, isDesktop);
          }),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(
    String subject,
    Map<String, dynamic> stats,
    bool isDesktop,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isDesktop ? 16 : 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: stats['color'],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  subject,
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                '${stats['averageAttendance'].toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.w700,
                  color: stats['color'],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip(
                '${stats['totalStudents']} Students',
                Icons.people,
                Colors.blue,
                isDesktop,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                '${stats['completedLectures']}/${stats['totalLectures']} Lectures',
                Icons.school,
                Colors.orange,
                isDesktop,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    String text,
    IconData icon,
    Color color,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 12 : 10,
        vertical: isDesktop ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isDesktop ? 14 : 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: isDesktop ? 12 : 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentDistribution(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart,
                color: Colors.purple.shade600,
                size: isDesktop ? 28 : 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Attendance Distribution',
                style: TextStyle(
                  fontSize: isDesktop ? 20 : 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AnimatedBuilder(
                  animation: _chartAnimation,
                  builder: (context, child) {
                    return SizedBox(
                      height: isDesktop ? 200 : 150,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: isDesktop ? 40 : 30,
                          sections: [
                            PieChartSectionData(
                              color: Colors.green,
                              value: 65 * _chartAnimation.value,
                              title: '65%',
                              radius: isDesktop ? 50 : 40,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              color: Colors.yellow.shade600,
                              value: 25 * _chartAnimation.value,
                              title: '25%',
                              radius: isDesktop ? 50 : 40,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              color: Colors.red,
                              value: 10 * _chartAnimation.value,
                              title: '10%',
                              radius: isDesktop ? 50 : 40,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildLegendItem(
                      'Excellent (>85%)',
                      Colors.green,
                      '81 Students',
                      isDesktop,
                    ),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                      'Good (70-85%)',
                      Colors.yellow.shade600,
                      '31 Students',
                      isDesktop,
                    ),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                      'Poor (<70%)',
                      Colors.red,
                      '13 Students',
                      isDesktop,
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

  Widget _buildLegendItem(
    String label,
    Color color,
    String count,
    bool isDesktop,
  ) {
    return Row(
      children: [
        Container(
          width: isDesktop ? 16 : 12,
          height: isDesktop ? 16 : 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isDesktop ? 14 : 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          count,
          style: TextStyle(
            fontSize: isDesktop ? 14 : 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
