import 'package:flutter/material.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String label;
  final String hint;
  final List<T> items;
  final T? value;
  final String? Function(T?)? validator;
  final void Function(T?)? onChanged;

  const CustomDropdown({
    Key? key,
    required this.label,
    required this.hint,
    required this.items,
    required this.value,
    required this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<T>(
            value: value,
            hint: Text(hint),
            decoration: _dropdownDecoration(),
            items: items.map((T item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(item.toString()),
              );
            }).toList(),
            onChanged: onChanged,
            validator: validator,
          ),
        ),
      ],
    );
  }

  InputDecoration _dropdownDecoration() {
    return const InputDecoration(
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: InputBorder.none,
    );
  }
}
