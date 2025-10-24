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

  const Calendar({
    Key? key,
    required this.controller,
    required this.label,
    this.validator,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.isRequired = false,
    this.hintText,
    this.onDateSelected,
  }) : super(key: key);

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = widget.firstDate ?? DateTime(now.year - 80);
    final lastDate = widget.lastDate ?? DateTime(now.year - 10);
    final initialDate = widget.initialDate ?? DateTime(now.year - 20);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Date of Birth',
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

      // Call the callback function if provided
      if (widget.onDateSelected != null) {
        widget.onDateSelected!(picked);
      }
    } else if (picked == null && mounted) {
      // Call the callback with null if date selection was cancelled
      if (widget.onDateSelected != null) {
        widget.onDateSelected!(null);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
      suffixIcon: Container(
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
