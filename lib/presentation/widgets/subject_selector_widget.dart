import 'package:flutter/material.dart';

class SubjectSelectorWidget extends StatelessWidget {
  final List<Map<String, dynamic>> attendances;
  final String? selectedSubject;
  final Function(String?) onSubjectSelected;
  final bool isDesktop;

  const SubjectSelectorWidget({
    super.key,
    required this.attendances,
    required this.selectedSubject,
    required this.onSubjectSelected,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Group subjects with their components
    final Map<String, List<String>> subjectComponents = {};
    final List<String> allSubjects = [];
    final List<String> lectureSubjects = [];
    final List<String> labSubjects = [];

    for (var att in attendances) {
      final subject = att['subject_name'] as String? ?? 'Unknown';
      final component = att['component'] as String? ?? 'Lecture';

      if (!subjectComponents.containsKey(subject)) {
        subjectComponents[subject] = [];
        allSubjects.add(subject);
      }

      if (!subjectComponents[subject]!.contains(component)) {
        subjectComponents[subject]!.add(component);

        if (component == 'Lecture') {
          lectureSubjects.add(subject);
        } else if (component == 'Lab') {
          labSubjects.add(subject);
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scrollable chips container
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Global filters section
                _buildFilterSection(
                  chips: [
                    _buildSubjectChip(
                      'All Subjects',
                      null,
                      'Lecture',
                    ), // Use Lecture behavior
                    _buildSubjectChip(
                      'All Lectures',
                      'all-lectures',
                      'Lecture', // Treat as Lecture type
                    ),
                    _buildSubjectChip(
                      'All Labs',
                      'all-labs',
                      'Lab',
                    ), // Treat as Lab type
                  ],
                ),

                // Lectures section
                if (lectureSubjects.isNotEmpty) ...[
                  _buildFilterSection(
                    chips: lectureSubjects.map((subject) {
                      return _buildSubjectChip(
                        subject,
                        "$subject - Lecture",
                        'Lecture',
                      );
                    }).toList(),
                  ),
                ],

                // Labs section
                if (labSubjects.isNotEmpty) ...[
                  _buildFilterSection(
                    chips: labSubjects.map((subject) {
                      return _buildSubjectChip(
                        subject,
                        "$subject - Lab",
                        'Lab',
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({required List<Widget> chips}) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Wrap(spacing: 8, runSpacing: 8, children: chips)],
      ),
    );
  }

  Widget _buildSubjectChip(String label, String? value, String? component) {
    final isSelected = selectedSubject == value;
    final isLab = component == 'Lab' || value == 'all-labs';
    final isLecture =
        component == 'Lecture' ||
        value == 'all-lectures' ||
        value == null; // All Subjects uses Lecture behavior

    Color backgroundColor = Colors.transparent;
    Color textColor = Colors.grey.shade700;
    Color borderColor = Colors.grey.shade300;

    if (isSelected) {
      if (isLab) {
        backgroundColor = const Color.fromARGB(
          255,
          224,
          89,
          48,
        ); // Professional dark orange
        textColor = Colors.white;
        borderColor = const Color(0xFFD84315);
      } else if (isLecture) {
        backgroundColor = const Color(0xFF1565C0); // Professional dark blue
        textColor = Colors.white;
        borderColor = const Color(0xFF1565C0);
      }
    } else {
      if (isLab) {
        backgroundColor = const Color(0xFFFFF3E0); // Light orange
        textColor = const Color(0xFFE64A19);
        borderColor = const Color(0xFFFFCCBC);
      } else if (isLecture) {
        backgroundColor = const Color(0xFFE3F2FD); // Light blue
        textColor = const Color(0xFF1976D2);
        borderColor = const Color(0xFFBBDEFB);
      }
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: Key(value ?? 'all'),
        onTap: () => onSubjectSelected(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 16 : 12,
            vertical: isDesktop ? 10 : 8,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: backgroundColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icons based on type
              if (isLab) ...[
                Icon(
                  Icons.science,
                  size: isDesktop ? 16 : 14,
                  color: textColor,
                ),
                const SizedBox(width: 6),
              ] else if (isLecture) ...[
                Icon(Icons.school, size: isDesktop ? 16 : 14, color: textColor),
                const SizedBox(width: 6),
              ],

              Text(
                label,
                style: TextStyle(
                  fontSize: isDesktop ? 14 : 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
