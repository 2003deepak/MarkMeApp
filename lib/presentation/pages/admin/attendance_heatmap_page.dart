import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';
import 'package:markmeapp/presentation/widgets/ui/dropdown.dart';
import 'package:markmeapp/data/repositories/admin_repository.dart';
import 'package:markmeapp/data/models/attendance_heatmap_model.dart';
import 'package:markmeapp/state/admin_state.dart';

class AttendanceHeatmapPage extends ConsumerStatefulWidget {
  const AttendanceHeatmapPage({super.key});

  @override
  ConsumerState<AttendanceHeatmapPage> createState() => _AttendanceHeatmapPageState();
}

class _AttendanceHeatmapPageState extends ConsumerState<AttendanceHeatmapPage> {
  bool _isLoading = false;
  String? _error;
  List<HeatmapSessionData> _heatmapData = [];

  // Filter States
  String? _selectedProgram;
  String? _selectedDepartment;
  String? _selectedSemester;
  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminStoreProvider.notifier).fetchHierarchicalMetadata();
      _fetchHeatmap();
    });
  }

  Future<void> _fetchHeatmap() async {
    setState(() {
      // Clear data to show clean empty grid immediately for the new month/year
      _heatmapData = [];
      _isLoading = true;
      _error = null;
    });

    final result = await ref.read(adminRepositoryProvider).fetchAttendanceHeatmap(
          department: _selectedDepartment,
          month: _selectedMonth,
          program: _selectedProgram,
          year: _selectedYear,
          semester: _selectedSemester != null ? int.tryParse(_selectedSemester!) : null,
        );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _heatmapData = result['data'] as List<HeatmapSessionData>;
        } else {
          final errorMsg = result['error'] as String? ?? 'Failed to load heatmap';
          // If no data, just leave it empty instead of showing a red error container
          if (errorMsg.contains('No attendance data') || errorMsg.contains('No data')) {
            _error = null;
          } else {
            _error = errorMsg;
          }
        }
      });
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HeatmapFilterSheet(
        initialProgram: _selectedProgram,
        initialDepartment: _selectedDepartment,
        initialSemester: _selectedSemester,
        initialMonth: _selectedMonth,
        initialYear: _selectedYear,
        onApply: (program, dept, sem, month, year) {
          setState(() {
            _selectedProgram = program;
            _selectedDepartment = dept;
            _selectedSemester = sem;
            _selectedMonth = month;
            _selectedYear = year;
          });
          _fetchHeatmap();
        },
      ),
    );
  }

  Color _getHeatmapColor(double attendance) {
    if (attendance == 0) return const Color(0xFFEBEDF0); // Light Grey
    if (attendance <= 40) return const Color(0xFF9BE9A8); // Very light green
    if (attendance <= 70) return const Color(0xFF40C463); // Light-medium green
    if (attendance <= 90) return const Color(0xFF30A14E); // Medium-dark green
    return const Color(0xFF216E39); // Darkest green
  }

  void _showDayDetails(DateTime date, HeatmapSessionData? data) {
    if (data == null || data.totalSessions == 0) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 12),
                Text(
                  "${date.day}/${date.month}/${date.year}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getHeatmapColor(data.averageAttendance).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _getHeatmapColor(data.averageAttendance).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Average Attendance", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(
                        "${data.averageAttendance.toStringAsFixed(1)}%",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getHeatmapColor(data.averageAttendance),
                        ),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Total Sessions", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(
                        "${data.totalSessions}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Close", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapGrid() {
    // Calculate days in month
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    final firstDayOfMonth = DateTime(_selectedYear, _selectedMonth, 1).weekday; // 1 = Mon, 7 = Sun
    
    // Create a map for quick lookup
    final Map<int, HeatmapSessionData> sessionMap = {};
    for (var session in _heatmapData) {
      if (session.date.isNotEmpty) {
        try {
          final date = DateTime.parse(session.date);
          sessionMap[date.day] = session;
        } catch (_) {} // Ignore parse errors
      }
    }

    // Days of week header
    final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month/Year Navigator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Color(0xFF64748B)),
              onPressed: () {
                setState(() {
                  if (_selectedMonth == 1) {
                    _selectedMonth = 12;
                    _selectedYear--;
                  } else {
                    _selectedMonth--;
                  }
                });
                _fetchHeatmap();
              },
            ),
            Text(
              "${_getMonthName(_selectedMonth)} $_selectedYear",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
              onPressed: () {
                setState(() {
                  if (_selectedMonth == 12) {
                    _selectedMonth = 1;
                    _selectedYear++;
                  } else {
                    _selectedMonth++;
                  }
                });
                _fetchHeatmap();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Grid Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: daysOfWeek.map((day) => Expanded(
            child: Center(
              child: Text(
                day,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 12),
        // Grid Cells
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: daysInMonth + (firstDayOfMonth - 1),
          itemBuilder: (context, index) {
            if (index < firstDayOfMonth - 1) {
              return const SizedBox.shrink(); // Empty offset spaces
            }

            final day = index - (firstDayOfMonth - 1) + 1;
            final data = sessionMap[day];
            final percent = data?.averageAttendance ?? 0.0;
            final color = _getHeatmapColor(percent);

            return GestureDetector(
              onTap: () => _showDayDetails(DateTime(_selectedYear, _selectedMonth, day), data),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    "$day",
                    style: TextStyle(
                      color: percent == 0.0 ? const Color(0xFF94A3B8) : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Less", style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(width: 8),
        _legendBox(const Color(0xFFEBEDF0)),
        const SizedBox(width: 4),
        _legendBox(const Color(0xFF9BE9A8)),
        const SizedBox(width: 4),
        _legendBox(const Color(0xFF40C463)),
        const SizedBox(width: 4),
        _legendBox(const Color(0xFF30A14E)),
        const SizedBox(width: 4),
        _legendBox(const Color(0xFF216E39)),
        const SizedBox(width: 8),
        const Text("More", style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
    return months[month - 1];
  }

  Widget _legendBox(Color color) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: MarkMeAppBar(
        title: "Attendance Heatmap",
        onBackPressed: () => context.pop(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilterSheet,
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.tune_rounded, color: Colors.white),
      ),
      body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                     
                      const SizedBox(height: 24),
                      if (_isLoading)
                        const LinearProgressIndicator(color: Color(0xFF2563EB), backgroundColor: Colors.transparent),
                      const SizedBox(height: 8),
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                        ),
                      if (_error == null) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeatmapGrid(),
                              const SizedBox(height: 24),
                              _buildLegend(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Summary Stats
                        if (_heatmapData.isNotEmpty)
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  title: "Monthly Avg",
                                  value: "${(_heatmapData.map((e) => e.averageAttendance).reduce((a, b) => a + b) / _heatmapData.length).toStringAsFixed(1)}%",
                                  icon: Icons.analytics_outlined,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  title: "Active Days",
                                  value: "${_heatmapData.where((e) => e.totalSessions > 0).length}",
                                  icon: Icons.event_available_rounded,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          )
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required MaterialColor color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color.shade500),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}

// ==========================================
// Filter Sheet Component
// ==========================================
class _HeatmapFilterSheet extends ConsumerStatefulWidget {
  final String? initialProgram;
  final String? initialDepartment;
  final String? initialSemester;
  final int initialMonth;
  final int initialYear;
  final Function(String?, String?, String?, int, int) onApply;

  const _HeatmapFilterSheet({
    this.initialProgram,
    this.initialDepartment,
    this.initialSemester,
    required this.initialMonth,
    required this.initialYear,
    required this.onApply,
  });

  @override
  ConsumerState<_HeatmapFilterSheet> createState() => _HeatmapFilterSheetState();
}

class _HeatmapFilterSheetState extends ConsumerState<_HeatmapFilterSheet> {
  String? selectedProgram;
  String? selectedDepartment;
  String? selectedSemester;
  late int selectedMonth;
  late int selectedYear;
  late int selectedBatchYear;

  @override
  void initState() {
    super.initState();
    selectedProgram = widget.initialProgram;
    selectedDepartment = widget.initialDepartment;
    selectedSemester = widget.initialSemester;
    selectedMonth = widget.initialMonth;
    selectedYear = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    final metadata = ref.watch(adminStoreProvider).hierarchyMetadata ?? {};
    final programs = metadata.keys.toList();

    List<String> departments = [];
    if (selectedProgram != null && metadata[selectedProgram] is Map) {
      departments = (metadata[selectedProgram] as Map<String, dynamic>).keys.toList();
    }

    List<String> semesters = [];
    if (selectedProgram != null &&
        selectedDepartment != null &&
        metadata[selectedProgram] is Map &&
        (metadata[selectedProgram] as Map)[selectedDepartment] is List) {
      final sems = (metadata[selectedProgram] as Map)[selectedDepartment] as List;
      semesters = sems.map((s) => s.toString()).toList();
    }

    final months = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"];
    final years = List.generate(5, (index) => (DateTime.now().year - 2 + index).toString());

    return Container(
      padding: const EdgeInsets.all(24).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Filter Heatmap", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Dropdown<String>(
              label: "Program",
              hint: "Select Program",
              items: programs.cast<String>(),
              value: selectedProgram,
              onChanged: (val) => setState(() {
                selectedProgram = val;
                selectedDepartment = null;
                selectedSemester = null;
              }),
            ),
            const SizedBox(height: 16),
            Dropdown<String>(
              label: "Department",
              hint: "Select Department",
              items: departments,
              value: selectedDepartment,
              onChanged: (val) => setState(() {
                selectedDepartment = val;
                selectedSemester = null;
              }),
            ),
            const SizedBox(height: 16),
            Dropdown<String>(
              label: "Semester",
              hint: "Select Semester",
              items: semesters,
              value: selectedSemester,
              onChanged: (val) => setState(() => selectedSemester = val),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Dropdown<String>(
                    label: "Month",
                    hint: "Month",
                    items: months,
                    value: selectedMonth.toString(),
                    onChanged: (val) => setState(() => selectedMonth = int.parse(val!)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Dropdown<String>(
                    label: "Year",
                    hint: "Year",
                    items: years,
                    value: selectedYear.toString(),
                    onChanged: (val) => setState(() => selectedYear = int.parse(val!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(selectedProgram, selectedDepartment, selectedSemester, selectedMonth, selectedYear);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Apply Filters", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
