import 'package:flutter/material.dart';

class FilterChipWidget extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  final bool isDark;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.onRemove,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF3B5BDB);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(16),
        splashColor: primaryColor.withOpacity(0.15),
        highlightColor: primaryColor.withOpacity(0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? primaryColor.withOpacity(0.20)
                : primaryColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryColor.withOpacity(0.30), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.close, size: 14, color: primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}
