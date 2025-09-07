import 'package:flutter/material.dart';

class TeacherReportsPage extends StatefulWidget {
  const TeacherReportsPage({super.key});

  @override
  State<TeacherReportsPage> createState() => _TeacherReportsPageState();
}

class _TeacherReportsPageState extends State<TeacherReportsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String selectedReportType = 'Attendance Report';
  String selectedPeriod = 'This Month';
  String selectedSubject = 'All Subjects';

  // Mock report data
  final List<Map<String, dynamic>> attendanceReports = [
    {
      'student_name': 'John Doe',
      'roll_number': 'CSE21001',
      'total_lectures': 30,
      'attended': 28,
      'percentage': 93.3,
      'status': 'Excellent',
    },
    {
      'student_name': 'Jane Smith',
      'roll_number': 'CSE21002',
      'total_lectures': 30,
      'attended': 25,
      'percentage': 83.3,
      'status': 'Good',
    },
    {
      'student_name': 'Mike Johnson',
      'roll_number': 'CSE21003',
      'total_lectures': 30,
      'attended': 20,
      'percentage': 66.7,
      'status': 'Average',
    },
    {
      'student_name': 'Sarah Wilson',
      'roll_number': 'CSE21004',
      'total_lectures': 30,
      'attended': 18,
      'percentage': 60.0,
      'status': 'Poor',
    },
    {
      'student_name': 'David Brown',
      'roll_number': 'CSE21005',
      'total_lectures': 30,
      'attended': 27,
      'percentage': 90.0,
      'status': 'Excellent',
    },
  ];

  final List<Map<String, dynamic>> performanceReports = [
    {
      'subject': 'Data Structures',
      'total_students': 45,
      'avg_attendance': 87.5,
      'lectures_completed': 25,
      'total_lectures': 28,
      'performance': 'Good',
    },
    {
      'subject': 'Algorithms',
      'total_students': 42,
      'avg_attendance': 82.3,
      'lectures_completed': 27,
      'total_lectures': 30,
      'performance': 'Average',
    },
    {
      'subject': 'Database Systems',
      'total_students': 38,
      'avg_attendance': 90.1,
      'lectures_completed': 24,
      'total_lectures': 26,
      'performance': 'Excellent',
    },
  ];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
          'View Reports',
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
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.file_download,
                  size: isDesktop ? 24 : 20,
                  color: Colors.green.shade600,
                ),
              ),
              onPressed: _exportReport,
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReportFilters(isDesktop),
                const SizedBox(height: 24),
                _buildReportSummary(isDesktop),
                const SizedBox(height: 24),
                _buildReportContent(isDesktop),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportFilters(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                Icons.filter_list,
                color: Colors.blue.shade600,
                size: isDesktop ? 28 : 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Report Filters',
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
                child: _buildFilterDropdown(
                  'Report Type',
                  selectedReportType,
                  ['Attendance Report', 'Performance Report', 'Subject Report'],
                  (value) => setState(() => selectedReportType = value!),
                  isDesktop,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown(
                  'Period',
                  selectedPeriod,
                  ['This Week', 'This Month', 'This Semester', 'Custom Range'],
                  (value) => setState(() => selectedPeriod = value!),
                  isDesktop,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Subject',
                  selectedSubject,
                  ['All Subjects', 'Data Structures', 'Algorithms', 'Database Systems'],
                  (value) => setState(() => selectedSubject = value!),
                  isDesktop,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: isDesktop ? 48 : 44,
                  child: ElevatedButton.icon(
                    onPressed: _generateReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      Icons.refresh,
                      size: isDesktop ? 20 : 18,
                    ),
                    label: Text(
                      'Generate Report',
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
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
          height: isDesktop ? 48 : 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
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

  Widget _buildReportSummary(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade700],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Summary',
            style: TextStyle(
              fontSize: isDesktop ? 20 : 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Records',
                  '125',
                  Icons.description,
                  isDesktop,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Average Score',
                  '86.3%',
                  Icons.trending_up,
                  isDesktop,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Generated On',
                  'Dec 7, 2024',
                  Icons.calendar_today,
                  isDesktop,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, bool isDesktop) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: isDesktop ? 28 : 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isDesktop ? 20 : 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 12 : 10,
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildReportContent(bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 24 : 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.table_chart,
                  color: Colors.green.shade600,
                  size: isDesktop ? 28 : 24,
                ),
                const SizedBox(width: 12),
                Text(
                  selectedReportType,
                  style: TextStyle(
                    fontSize: isDesktop ? 20 : 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 12 : 10,
                    vertical: isDesktop ? 6 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${attendanceReports.length} Records',
                    style: TextStyle(
                      fontSize: isDesktop ? 12 : 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (selectedReportType == 'Attendance Report')
            _buildAttendanceTable(isDesktop)
          else if (selectedReportType == 'Performance Report')
            _buildPerformanceTable(isDesktop)
          else
            _buildSubjectTable(isDesktop),
        ],
      ),
    );
  }

  Widget _buildAttendanceTable(bool isDesktop) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: isDesktop ? 40 : 20,
        headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
        columns: [
          DataColumn(
            label: Text(
              'Student Name',
              style: TextStyle(
                fontSize: isDesktop ? 14 : 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Roll Number',
              style: TextStyle(
                fontSize: isDesktop ? 14 : 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Attended',
              style: TextStyle(
                fontSize: isDesktop ? 14 : 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Total',
              style: TextStyle(
                fontSize: isDesktop ? 14 : 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Percentage',
              style: TextStyle(
                fontSize: isDesktop ? 14 : 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Status',
              style: TextStyle(
                fontSize: isDesktop ? 14 : 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
        rows: attendanceReports.map((report) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  report['student_name'],
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 12,
                    color: Colors.black87,
                  ),
                ),
              ),
              DataCell(
                Text(
                  report['roll_number'],
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${report['attended']}',
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 12,
                    color: Colors.black87,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${report['total_lectures']}',
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 12,
                    color: Colors.black87,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${report['percentage'].toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 12,
                    fontWeight: FontWeight.w600,
                    color: _getPercentageColor(report['percentage']),
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 8 : 6,
                    vertical: isDesktop ? 4 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(report['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report['status'],
                    style: TextStyle(
                      fontSize: isDesktop ? 12 : 10,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(report['status']),
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPerformanceTable(bool isDesktop) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: isDesktop ? 40 : 20,
        headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
        columns: [
          DataColumn(
            label: Text(
              'Subject',
              style: TextStyle(
                fontSize: isDesktop ? 14 : 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Students',
              style: TextStyle(
                fontSize: isDesktop ? 14 : 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Avg Attendance',
              style: TextStyle(
                fontSize: isDesktop ? 14 : 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Lectures',
              style: TextStyle(
                fontSize: isDesktop ? 14 : 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Performance',
              style: TextStyle(
                fontSize: isDesktop ? 14 : 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
        rows: performanceReports.map((report) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  report['subject'],
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${report['total_students']}',
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 12,
                    color: Colors.black87,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${report['avg_attendance'].toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 12,
                    fontWeight: FontWeight.w600,
                    color: _getPercentageColor(report['avg_attendance']),
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${report['lectures_completed']}/${report['total_lectures']}',
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 12,
                    color: Colors.black87,
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 8 : 6,
                    vertical: isDesktop ? 4 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(report['performance']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report['performance'],
                    style: TextStyle(
                      fontSize: isDesktop ? 12 : 10,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(report['performance']),
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubjectTable(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.construction,
              size: isDesktop ? 64 : 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Subject Report',
              style: TextStyle(
                fontSize: isDesktop ? 18 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: isDesktop ? 14 : 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'average':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _generateReport() {
    // Simulate report generation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text('Report generated for $selectedReportType'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _exportReport() {
    // Simulate report export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.download_done,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text('Report exported successfully!'),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}