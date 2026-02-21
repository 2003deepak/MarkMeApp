import 'package:flutter/material.dart';
import 'package:markmeapp/presentation/widgets/ui/custom_bottom_sheet_layout.dart';
import 'package:markmeapp/presentation/widgets/ui/dropdown.dart';

class AdminFilterSheet extends StatefulWidget {
  final Map<String, String?> initialFilters;
  final void Function(Map<String, String?>) onApply;

  const AdminFilterSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<AdminFilterSheet> createState() => _AdminFilterSheetState();
}

class _AdminFilterSheetState extends State<AdminFilterSheet> {
  late String? selectedDepartment;
  late String? selectedSubject;
  late String? selectedTeacher;

  @override
  void initState() {
    super.initState();
    selectedDepartment = widget.initialFilters['Department'];
    selectedSubject = widget.initialFilters['Subject'];
    selectedTeacher = widget.initialFilters['Teacher'];
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheetLayout(
      title: "Filter Options",
      onReset: () {
        setState(() {
          selectedDepartment = null;
          selectedSubject = null;
          selectedTeacher = null;
        });
      },
      onApply: () {
        widget.onApply({
          'Department': selectedDepartment,
          'Subject': selectedSubject,
          'Teacher': selectedTeacher,
        });
        Navigator.pop(context);
      },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Dropdown<String>(
            label: "Department",
            hint: "Select Department",
            items: const ["Computer Science", "Mechanical", "Electrical", "Civil"],
            value: selectedDepartment,
            onChanged: (val) => setState(() => selectedDepartment = val),
          ),
          const SizedBox(height: 20),
          Dropdown<String>(
            label: "Subject",
            hint: "Select Subject",
            items: const ["Algorithms", "Databases", "Mathematics", "History"],
            value: selectedSubject,
            onChanged: (val) => setState(() => selectedSubject = val),
          ),
          const SizedBox(height: 20),
          Dropdown<String>(
            label: "Teacher",
            hint: "Select Teacher",
            items: const ["Alan Turing", "Ada Lovelace", "John von Neumann"],
            value: selectedTeacher,
            onChanged: (val) => setState(() => selectedTeacher = val),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
