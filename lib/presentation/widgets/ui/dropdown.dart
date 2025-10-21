import 'package:flutter/material.dart';

class Dropdown<T> extends StatefulWidget {
  final String label;
  final String hint;
  final List<T> items;
  final T? value;
  final String? Function(T?)? validator;
  final void Function(T?)? onChanged;
  final bool isRequired;
  final String Function(T)? displayText;
  final bool enabled;

  const Dropdown({
    Key? key,
    required this.label,
    required this.hint,
    required this.items,
    required this.value,
    required this.onChanged,
    this.validator,
    this.isRequired = false,
    this.displayText,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<Dropdown<T>> createState() => _DropdownState<T>();
}

class _DropdownState<T> extends State<Dropdown<T>> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with required indicator
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Row(
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                  letterSpacing: 0.2,
                ),
              ),
              if (widget.isRequired)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    '*',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Dropdown Container
        Container(
          decoration: BoxDecoration(
            color: widget.enabled ? Colors.white : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<T>(
            value: widget.value,
            hint: Text(
              widget.hint,
              style: TextStyle(
                color: const Color(0xFF6B7280),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              filled: !widget.enabled,
              fillColor: const Color(0xFFF9FAFB),
            ),
            items: widget.items.map((T item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  widget.displayText?.call(item) ?? item.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: widget.enabled ? widget.onChanged : null,
            validator: widget.validator,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            icon: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: widget.enabled
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF9CA3AF),
                size: 20,
              ),
            ),
            isExpanded: true,
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 4,
            menuMaxHeight: 300,
            selectedItemBuilder: (BuildContext context) {
              return widget.items.map<Widget>((T item) {
                return Text(
                  widget.displayText?.call(item) ?? item.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                  overflow: TextOverflow.ellipsis,
                );
              }).toList();
            },
          ),
        ),
      ],
    );
  }
}
