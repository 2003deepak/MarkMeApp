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

  bool _hasData() {
    return attendances.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasData = _hasData();
    
    // ✅ Group subjects with their components (only if has data)
    final Map<String, List<String>> subjectComponents = {};
    final List<String> allSubjects = [];
    final List<String> lectureSubjects = [];
    final List<String> labSubjects = [];

    if (hasData) {
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
      child: !hasData
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: 24,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  Text(
                    'No Subjects Found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enroll in subjects to start tracking',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Global filters section (always show these)
                  _buildFilterSection(
                    chips: [
                      _buildSubjectChip(
                        'All Subjects',
                        null,
                        'Lecture',
                        true,
                      ),
                      _buildSubjectChip(
                        'All Lectures',
                        'all-lectures',
                        'Lecture',
                        true,
                      ),
                      _buildSubjectChip(
                        'All Labs',
                        'all-labs',
                        'Lab',
                        true,
                      ),
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
                          true,
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
                          true,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
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

  Widget _buildSubjectChip(String label, String? value, String? component, bool hasData) {
    final isSelected = selectedSubject == value && hasData;
    final isLab = component == 'Lab' || value == 'all-labs';
    final isLecture =
        component == 'Lecture' ||
        value == 'all-lectures' ||
        value == null;

    Color backgroundColor = Colors.transparent;
    Color textColor = hasData ? Colors.grey.shade700 : Colors.grey.shade400;
    Color borderColor = hasData ? Colors.grey.shade300 : Colors.grey.shade200;

    if (hasData) {
      if (isSelected) {
        if (isLab) {
          backgroundColor = const Color.fromARGB(255, 224, 89, 48);
          textColor = Colors.white;
          borderColor = const Color(0xFFD84315);
        } else if (isLecture) {
          backgroundColor = const Color(0xFF1565C0);
          textColor = Colors.white;
          borderColor = const Color(0xFF1565C0);
        }
      } else {
        if (isLab) {
          backgroundColor = const Color(0xFFFFF3E0);
          textColor = const Color(0xFFE64A19);
          borderColor = const Color(0xFFFFCCBC);
        } else if (isLecture) {
          backgroundColor = const Color(0xFFE3F2FD);
          textColor = const Color(0xFF1976D2);
          borderColor = const Color(0xFFBBDEFB);
        }
      }
    } else {
      // Empty state styling - all chips are greyed out
      backgroundColor = Colors.grey.shade50;
      textColor = Colors.grey.shade400;
      borderColor = Colors.grey.shade300;
    }

    return MouseRegion(
      cursor: hasData ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        key: Key(value ?? 'all'),
        onTap: hasData ? () => onSubjectSelected(value) : null,
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
            boxShadow: (hasData && isSelected)
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
                Icon(
                  Icons.school, 
                  size: isDesktop ? 16 : 14, 
                  color: textColor,
                ),
                const SizedBox(width: 6),
              ],

              Text(
                label,
                style: TextStyle(
                  fontSize: isDesktop ? 14 : 12,
                  fontWeight: (hasData && isSelected) ? FontWeight.w600 : FontWeight.w500,
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