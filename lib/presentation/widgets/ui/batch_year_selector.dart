import 'package:flutter/material.dart';
import 'package:markmeapp/presentation/widgets/ui/input_field.dart';

class BatchYearSelector extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String label;
  final bool isRequired;
  final String? hintText;

  const BatchYearSelector({
    super.key,
    required this.controller,
    this.validator,
    required this.label,
    this.isRequired = false,
    this.hintText,
  });

  @override
  State<BatchYearSelector> createState() => _BatchYearSelectorState();
}

class _BatchYearSelectorState extends State<BatchYearSelector> {
  Future<void> _pickBatchYear() async {
    final now = DateTime.now();
    final selectedYear = await showDialog<int>(
      context: context,
      builder: (context) {
        int tempYear = int.tryParse(widget.controller.text) ?? now.year;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Batch Year',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: YearPicker(
                      firstDate: DateTime(now.year - 20),
                      lastDate: DateTime(now.year + 1),
                      selectedDate: DateTime(tempYear),
                      onChanged: (DateTime dateTime) {
                        Navigator.of(context).pop(dateTime.year);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF6B7280),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final currentYear = DateTime.now().year;
                            Navigator.of(context).pop(currentYear);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Current Year'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selectedYear != null && mounted) {
      widget.controller.text = selectedYear.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InputField(
      label: widget.label,
      controller: widget.controller,
      readOnly: true,
      onTap: _pickBatchYear,
      validator: widget.validator,
      isRequired: widget.isRequired,
      hintText: widget.hintText ?? 'Select batch year',
      suffixIcon: Container(
        padding: const EdgeInsets.all(12),
        child: const Icon(
          Icons.calendar_month_rounded,
          color: Color(0xFF9CA3AF),
          size: 20,
        ),
      ),
    );
  }
}
