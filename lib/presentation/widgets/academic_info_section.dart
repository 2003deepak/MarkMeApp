import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markmeapp/presentation/widgets/ui/input_field.dart';
import 'package:markmeapp/presentation/widgets/ui/dropdown.dart';
import 'package:markmeapp/presentation/widgets/ui/batch_year_selector.dart';

class AcademicInfoSection extends StatelessWidget {
  final TextEditingController rollCtrl;
  final TextEditingController batchYearCtrl;
  final String program;
  final String department;
  final int semester;
  final Function(String) onProgramChanged;
  final Function(String) onDepartmentChanged;
  final Function(int) onSemesterChanged;
  final BoxDecoration cardDecoration;

  const AcademicInfoSection({
    Key? key,
    required this.rollCtrl,
    required this.batchYearCtrl,
    required this.program,
    required this.department,
    required this.semester,
    required this.onProgramChanged,
    required this.onDepartmentChanged,
    required this.onSemesterChanged,
    required this.cardDecoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          InputField(
            label: 'Roll number',
            controller: rollCtrl,
            isRequired: true,
            maxLength: 3,
            hintText: '3 digits',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              final val = v?.trim() ?? '';
              if (val.length != 3) return 'Enter exactly 3 digits';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Dropdown<String>(
            label: 'Program',
            hint: 'Select program',
            items: const ['MCA', 'MBA', 'B.TECH', 'M.TECH'],
            value: program,
            isRequired: true,
            onChanged: (v) => onProgramChanged(v!),
          ),
          const SizedBox(height: 16),
          Dropdown<String>(
            label: 'Department',
            hint: 'Select department',
            items: const ['BTECH', 'MTECH', 'COMPUTER SCIENCE', 'ELECTRICAL'],
            value: department,
            isRequired: true,
            onChanged: (v) => onDepartmentChanged(v!),
          ),
          const SizedBox(height: 16),
          Dropdown<int>(
            label: 'Semester',
            hint: 'Select semester',
            items: const [1, 2, 3, 4, 5, 6, 7, 8],
            value: semester,
            isRequired: true,
            onChanged: (v) => onSemesterChanged(v!),
          ),
          const SizedBox(height: 16),
          // BatchYearSelector(
          //   controller: batchYearCtrl,
          //   label: 'Batch year',
          //   isRequired: true,
          //   validator: (v) {
          //     final year = int.tryParse((v ?? '').trim());
          //     if (year == null || year < 2000) return 'Select a valid year';
          //     return null;
          //   },
          // ),
        ],
      ),
    );
  }
}
