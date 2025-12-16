import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceCalendar extends StatelessWidget {
  final DateTime selectedMonth;
  final DateTime? selectedDay;
  final Map<int, dynamic> dayStatusMap;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final Function(int) onDaySelected;

  const AttendanceCalendar({
    super.key,
    required this.selectedMonth,
    required this.selectedDay,
    required this.dayStatusMap,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _CalendarHeader(
            month: selectedMonth,
            onPrev: onPrevMonth,
            onNext: onNextMonth,
          ),
          const SizedBox(height: 20),
          const _WeekDaysRow(),
          const SizedBox(height: 12),
          _CalendarGrid(
            month: selectedMonth,
            selectedDay: selectedDay,
            dayStatusMap: dayStatusMap,
            onDaySelected: onDaySelected,
          ),
        ],
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _CalendarHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        Text(
          DateFormat('MMMM yyyy').format(month),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _WeekDaysRow extends StatelessWidget {
  const _WeekDaysRow();

  @override
  Widget build(BuildContext context) {
    const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Row(
      children: days
          .map(
            (d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final DateTime? selectedDay;
  final Map<int, dynamic> dayStatusMap;
  final Function(int) onDaySelected;

  const _CalendarGrid({
    required this.month,
    required this.selectedDay,
    required this.dayStatusMap,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmpty = firstDay.weekday - 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: leadingEmpty + daysInMonth,
      itemBuilder: (context, index) {
        if (index < leadingEmpty) return const SizedBox();

        final day = index - leadingEmpty + 1;
        final isSelected = selectedDay?.day == day;
        final hasAttendance = dayStatusMap.containsKey(day);

        return GestureDetector(
          onTap: () => onDaySelected(day),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : hasAttendance
                  ? const Color(0xFFE2E8F0)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
