import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markmeapp/presentation/widgets/ui/dropdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/data/repositories/admin_repository.dart';
import 'package:markmeapp/core/utils/snackbar_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:markmeapp/state/admin_state.dart';

class AdminReportsPage extends ConsumerStatefulWidget {
  const AdminReportsPage({super.key});

  @override
  ConsumerState<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends ConsumerState<AdminReportsPage> {
  String? _selectedDepartment;
  String? _selectedProgram;
  String? _selectedBatchYear;
  String? _selectedSemester;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminStoreProvider.notifier).fetchHierarchicalMetadata();
    });
  }

  bool _isExporting = false;
  String? _lastGeneratedUrl;
  String? _lastGeneratedType;

  List<String> _departments = [];
  List<String> _programs = [];
  List<String> _semesters = [];
  final List<String> _batchYears = ['2023', '2024', '2025', '2026'];


  // Extract year from "2021-2025" or similar
  String _getYear(String? batch) {
    if (batch == null) return "";
    return batch.split('-').last;
  }

  Future<void> _handleExport(String type) async {
    if (_selectedDepartment == null || _selectedProgram == null || _selectedBatchYear == null || _selectedSemester == null) {
      showAppSnackBar("Please select all filters", isError: true, context: context);
      return;
    }

    setState(() => _isExporting = true);

    try {
      final repo = ref.read(adminRepositoryProvider);
      final result = await repo.downloadClassReport(
        program: _selectedProgram!,
        department: _selectedDepartment!,
        semester: _selectedSemester!,
        year: _selectedBatchYear!,
        type: type.toLowerCase(),
      );

      if (result['success'] == true) {
        setState(() {
          _lastGeneratedUrl = result['file_url'];
          _lastGeneratedType = type.toUpperCase();
        });
        
        if (mounted) {
          showAppSnackBar(
            "Report generated successfully. You can now download it below.",
            context: context,
          );
        }
      } else {
        if (mounted) showAppSnackBar(result['error'] ?? "Failed to generate report", isError: true, context: context);
      }
    } catch (e) {
      if (mounted) showAppSnackBar("An error occurred: $e", isError: true, context: context);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminStoreProvider);
    final hierarchyData = adminState.hierarchyMetadata ?? {};
    
    _programs = hierarchyData.keys.toList();
    if (_selectedProgram != null && hierarchyData.containsKey(_selectedProgram)) {
      final deptMap = hierarchyData[_selectedProgram] as Map<String, dynamic>;
      _departments = deptMap.keys.toList();
      
      if (_selectedDepartment != null && deptMap.containsKey(_selectedDepartment)) {
        final semesterList = deptMap[_selectedDepartment] as List<dynamic>;
        _semesters = semesterList.map((e) => e.toString()).toList();
        _semesters.sort();
      } else {
        _semesters = [];
      }
    } else {
      _departments = [];
      _semesters = [];
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. Filter Section ---
                  _buildFilterSection(),
                  
                  const SizedBox(height: 24),
    
                  // --- 2. Action Buttons ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          label: "Export PDF",
                          icon: Icons.picture_as_pdf_outlined,
                          color: const Color(0xFF2563EB),
                          onTap: () => _handleExport("pdf"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          label: "Export Excel",
                          icon: Icons.table_chart_outlined,
                          color: const Color(0xFF2563EB),
                          onTap: () => _handleExport("excel"),
                        ),
                      ),
                    ],
                  ),
    
                  const SizedBox(height: 32),
                  
                  if (_lastGeneratedUrl != null) _buildDownloadCard(),
                ],
              ),
            ),
          ),
          if (_isExporting)
            Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      children: [
        _buildReportDropdown(
          label: "Program",
          hint: "Select Program",
          icon: Icons.school_outlined,
          items: _programs,
          value: _selectedProgram,
          onChanged: (val) => setState(() {
            _selectedProgram = val;
            _selectedDepartment = null;
            _selectedSemester = null;
            _lastGeneratedUrl = null;
          }),
        ),
        const SizedBox(height: 12),
        _buildReportDropdown(
          label: "Department",
          hint: "Select Department",
          icon: Icons.account_balance_outlined,
          items: _departments,
          value: _selectedDepartment,
          onChanged: (val) => setState(() {
            _selectedDepartment = val;
            _selectedSemester = null;
            _lastGeneratedUrl = null;
          }),
        ),
        const SizedBox(height: 12),
        _buildReportDropdown(
          label: "Batch Year",
          hint: "Select Batch Year",
          icon: Icons.calendar_today_outlined,
          items: _batchYears,
          value: _selectedBatchYear,
          onChanged: (val) => setState(() {
            _selectedBatchYear = val;
            _lastGeneratedUrl = null;
          }),
        ),
        const SizedBox(height: 12),
        _buildReportDropdown(
          label: "Semester",
          hint: "Select Semester",
          icon: Icons.auto_stories_outlined,
          items: _semesters,
          value: _selectedSemester,
          onChanged: (val) => setState(() {
            _selectedSemester = val;
            _lastGeneratedUrl = null;
          }),
        ),
      ],
    );
  }

  Widget _buildReportDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
  }) {
    return Dropdown<String>(
      label: "", 
      hint: hint,
      items: items,
      value: value,
      onChanged: onChanged,
      displayText: (val) => val,
      icon: icon,
    );
  }


  Widget _buildActionButton({required String label, required IconData icon, required Color color, VoidCallback? onTap}) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isExporting ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadCard() {
    return AnimatedScale(
      scale: _lastGeneratedUrl != null ? 1.0 : 0.8,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: _lastGeneratedUrl != null ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                blurRadius: 30,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF10B981),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Report Ready",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: const Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            "$_lastGeneratedType Document File",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => setState(() => _lastGeneratedUrl = null),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  // Action info column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your file is ready to download.",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF475569),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Download Button
                  _buildDownloadActionButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadActionButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (_lastGeneratedUrl == null) return;
            final Uri url = Uri.parse(_lastGeneratedUrl!);
            if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
              if (mounted) showAppSnackBar("Could not open report URL", isError: true, context: context);
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_download_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  "Download",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
