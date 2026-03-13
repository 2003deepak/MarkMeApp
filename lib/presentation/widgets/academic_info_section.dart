import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/presentation/widgets/ui/input_field.dart';
import 'package:markmeapp/presentation/widgets/ui/dropdown.dart';
import 'package:markmeapp/presentation/widgets/ui/batch_year_selector.dart';
import 'package:markmeapp/state/admin_state.dart';

class AcademicInfoSection extends ConsumerWidget {
  final TextEditingController rollCtrl;
  final TextEditingController batchYearCtrl;
  final String program;
  final String department;
  final int semester;
  final Function(String?) onProgramChanged;
  final Function(String?) onDepartmentChanged;
  final Function(int?) onSemesterChanged;
  final BoxDecoration cardDecoration;
  final String? Function(String?)? validateRollNumber;
  final String? Function(String?)? validateBatchYear;
  final String? Function(String?)? validateSemester;

  const AcademicInfoSection({
    super.key,
    required this.rollCtrl,
    required this.batchYearCtrl,
    required this.program,
    required this.department,
    required this.semester,
    required this.onProgramChanged,
    required this.onDepartmentChanged,
    required this.onSemesterChanged,
    required this.cardDecoration,
    this.validateRollNumber,
    this.validateBatchYear,
    this.validateSemester,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminStoreProvider);
    final hierarchyData = adminState.hierarchyMetadata ?? {};
    
    final List<String> programs = hierarchyData.keys.toList();
    final List<String> departments = program.isNotEmpty && hierarchyData.containsKey(program)
        ? (hierarchyData[program] as Map<String, dynamic>).keys.toList()
        : [];
        
    final List<int> semesters = program.isNotEmpty && 
                                department.isNotEmpty && 
                                hierarchyData.containsKey(program) && 
                                (hierarchyData[program] as Map<String, dynamic>).containsKey(department)
        ? List<int>.from((hierarchyData[program] as Map<String, dynamic>)[department])
        : [1, 2, 3, 4, 5, 6, 7, 8]; // Fallback if no specific semesters found

    return Container(
      decoration: cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          InputField(
            label: 'Roll number',
            controller: rollCtrl,
            isRequired: true,
            hintText: 'Enter your roll number',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            validator:
                validateRollNumber ??
                (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return 'Roll number is required';
                  if (val.length != 3) return 'Enter exactly 3 digits';
                  return null;
                },
          ),
          const SizedBox(height: 16),
          Dropdown<String>(
            label: 'Program',
            hint: 'Select program',
            items: programs.isEmpty ? [program].where((e) => e.isNotEmpty).toList() : programs,
            value: program.isEmpty ? null : program,
            isRequired: true,
            onChanged: onProgramChanged,
          ),
          const SizedBox(height: 16),
          Dropdown<String>(
            label: 'Department',
            hint: 'Select department',
            items: departments.isEmpty ? [department].where((e) => e.isNotEmpty).toList() : departments,
            value: department.isEmpty ? null : department,
            isRequired: true,
            onChanged: onDepartmentChanged,
          ),
          const SizedBox(height: 16),
          Dropdown<int>(
            label: 'Semester',
            hint: 'Select semester',
            items: semesters,
            value: semester == 0 ? null : semester,
            isRequired: true,
            onChanged: onSemesterChanged,
          ),
          const SizedBox(height: 16),
          BatchYearSelector(
            controller: batchYearCtrl,
            label: 'Batch year',
            isRequired: true,
            hintText: 'Select batch year',
            validator:
                validateBatchYear ??
                (v) {
                  final year = int.tryParse((v ?? '').trim());
                  if (year == null) return 'Batch year is required';
                  final currentYear = DateTime.now().year;
                  if (year < 2000 || year > currentYear + 1) {
                    return 'Please enter a valid batch year';
                  }
                  return null;
                },
          ),
        ],
      ),
    );
  }
}
