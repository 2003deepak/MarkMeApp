import 'package:flutter/material.dart';

class SubjectSelectorWidget extends StatelessWidget {
  final Map<String, Map<String, dynamic>> subjectData;
  final String? selectedSubject;
  final Function(String?) onSubjectSelected;
  final bool isDesktop;

  const SubjectSelectorWidget({
    super.key,
    required this.subjectData,
    required this.selectedSubject,
    required this.onSubjectSelected,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildSubjectChip('All Subjects', null),
            ...subjectData.keys.map(
              (subject) => _buildSubjectChip(subject, subject),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectChip(String label, String? value) {
    final isSelected = selectedSubject == value;

    return GestureDetector(
      onTap: () => onSubjectSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 20 : 16,
          vertical: isDesktop ? 12 : 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade600 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
