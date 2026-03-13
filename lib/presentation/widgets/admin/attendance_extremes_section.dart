import 'package:flutter/material.dart';
import 'package:markmeapp/data/models/attendance_extremes_model.dart';
import 'package:markmeapp/presentation/widgets/admin/extreme_stat_card.dart';
import 'package:markmeapp/presentation/skeleton/widgets/attendance_extremes_skeleton.dart';

class AttendanceExtremesSection extends StatelessWidget {
  final AttendanceExtremesResponse? extremes;
  final bool isLoading;
  final String selectedPeriod;
  final Function(String) onPeriodChanged;

  const AttendanceExtremesSection({
    super.key,
    required this.extremes,
    required this.isLoading,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Attendance Extremes",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
              ),
              _buildPeriodToggle(),
            ],
          ),
        ),
        if (isLoading)
          const AttendanceExtremesSkeleton()
        else if (extremes != null) ...[
          ExtremeStatCard(
            subject: extremes!.highest.subject,
            dateTime: extremes!.highest.date,
            percentage: extremes!.highest.attendance.toStringAsFixed(1),
            isHighest: true,
          ),
          ExtremeStatCard(
            subject: extremes!.lowest.subject,
            dateTime: extremes!.lowest.date,
            percentage: extremes!.lowest.attendance.toStringAsFixed(1),
            isHighest: false,
          ),
        ] else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text("Unable to load extremes")),
          ),
      ],
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PeriodButton(
            label: "Week",
            isSelected: selectedPeriod == 'weekly',
            onTap: () => onPeriodChanged('weekly'),
          ),
          _PeriodButton(
            label: "Month",
            isSelected: selectedPeriod == 'monthly',
            onTap: () => onPeriodChanged('monthly'),
          ),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
