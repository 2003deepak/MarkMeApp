import 'package:flutter/material.dart';
import 'package:markmeapp/presentation/widgets/ui/input_field.dart';

class Calendar extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool isRequired;
  final String? hintText;
  final Function(DateTime?)? onDateSelected;
  final bool Function(DateTime)? selectableDayPredicate;

  const Calendar({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.isRequired = false,
    this.hintText,
    this.onDateSelected,
    this.selectableDayPredicate,
  });

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  DateTime? _selectedDate;
  bool _isPickingDate = false;

  Future<void> _pickDate() async {
    // Prevent multiple taps
    if (_isPickingDate) return;

    setState(() => _isPickingDate = true);

    try {
      final now = DateTime.now();
      final firstDate =
          widget.firstDate ?? DateTime(now.year, now.month, now.day);
      final lastDate =
          widget.lastDate ?? DateTime(now.year + 1, now.month, now.day);

      // Handle initial date
      DateTime? initialDate = widget.initialDate ?? _selectedDate;

      // Check if we have a predicate
      if (widget.selectableDayPredicate != null) {
        // Validation logic:
        // 1. If initialDate is null or invalid, try to find next valid date from now
        // 2. If now is invalid, try to find next valid date from firstDate

        DateTime candidate = initialDate ?? now;

        if (!widget.selectableDayPredicate!(candidate)) {
          // Find next valid date
          DateTime searchDate = candidate;
          bool found = false;
          // Search forward up to 60 days
          for (int i = 0; i < 60; i++) {
            if (widget.selectableDayPredicate!(searchDate)) {
              initialDate = searchDate;
              found = true;
              break;
            }
            searchDate = searchDate.add(const Duration(days: 1));
          }

          // If not found from candidate, try searching from firstDate
          if (!found && widget.firstDate != null) {
            searchDate = widget.firstDate!;
            for (int i = 0; i < 60; i++) {
              if (widget.selectableDayPredicate!(searchDate)) {
                initialDate = searchDate;
                found = true;
                break;
              }
              searchDate = searchDate.add(const Duration(days: 1));
            }
          }

          // If still not found, we let it be (showDatePicker might throw if no valid date found)
          // But effectively we tried our best.
          if (found) {
            // ensure initialDate is within bounds
            if (initialDate!.isBefore(firstDate)) initialDate = firstDate;
            if (initialDate.isAfter(lastDate)) initialDate = lastDate;
          }
        } else {
          initialDate = candidate;
        }
      }

      // Fallback
      initialDate ??= now;

      final picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        selectableDayPredicate: widget.selectableDayPredicate,
        helpText: 'Select Date',
        confirmText: 'SELECT',
        cancelText: 'CANCEL',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF4F46E5),
                onPrimary: Colors.white,
                onSurface: Color(0xFF111827),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4F46E5),
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null && mounted) {
        setState(() {
          _selectedDate = picked;
          widget.controller.text = _formatDate(picked);
        });

        if (widget.onDateSelected != null) {
          widget.onDateSelected!(picked);
        }
      } else if (picked == null && mounted) {
        if (widget.onDateSelected != null) {
          widget.onDateSelected!(null);
        }
      }
    } catch (e) {
      debugPrint('Error picking date: $e');
    } finally {
      if (mounted) {
        setState(() => _isPickingDate = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return InputField(
      label: widget.label,
      controller: widget.controller,
      readOnly: true,
      onTap: _pickDate,
      validator: widget.validator,
      isRequired: widget.isRequired,
      hintText: widget.hintText ?? 'Select date',
      suffixIcon: _isPickingDate
          ? Container(
              padding: const EdgeInsets.all(12),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: Color(0xFF9CA3AF),
                size: 20,
              ),
            ),
    );
  }
}
