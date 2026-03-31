import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/presentation/widgets/ui/custom_bottom_sheet_layout.dart';
import 'package:markmeapp/presentation/widgets/ui/dropdown.dart';
import 'package:markmeapp/state/admin_state.dart';

class AdminFilterSheet extends ConsumerStatefulWidget {
  final Map<String, String?> initialFilters;
  final void Function(Map<String, String?>) onApply;

  const AdminFilterSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  ConsumerState<AdminFilterSheet> createState() => _AdminFilterSheetState();
}

class _AdminFilterSheetState extends ConsumerState<AdminFilterSheet> {
  String? selectedProgram;
  String? selectedDepartment;
  String? selectedSemester;

  @override
  void initState() {
    super.initState();
    selectedProgram = widget.initialFilters['Program'];
    selectedDepartment = widget.initialFilters['Department'];
    selectedSemester = widget.initialFilters['Semester'];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminStoreProvider.notifier).fetchHierarchicalMetadata();
    });
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

    return CustomBottomSheetLayout(
      title: "Filter Options",
      onReset: () {
        setState(() {
          selectedProgram = null;
          selectedDepartment = null;
          selectedSemester = null;
        });
      },
      onApply: () {
        widget.onApply(<String, String?>{
          'Program': selectedProgram,
          'Department': selectedDepartment,
          'Semester': selectedSemester,
        });
        Navigator.pop(context);
      },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Dropdown<String>(
            label: "Program",
            hint: "Select Program",
            items: programs.cast<String>(),
            value: selectedProgram,
            onChanged: (val) {
              setState(() {
                selectedProgram = val;
                selectedDepartment = null;
                selectedSemester = null;
              });
            },
          ),
          const SizedBox(height: 20),
          Dropdown<String>(
            label: "Department",
            hint: "Select Department",
            items: departments,
            value: selectedDepartment,
            onChanged: (val) {
              setState(() {
                selectedDepartment = val;
                selectedSemester = null;
              });
            },
          ),
          const SizedBox(height: 20),
          Dropdown<String>(
            label: "Semester",
            hint: "Select Semester",
            items: semesters,
            value: selectedSemester,
            onChanged: (val) {
              setState(() {
                selectedSemester = val;
              });
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

