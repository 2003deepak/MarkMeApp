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
  final IconData? icon;

  const Dropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.value,
    required this.onChanged,
    this.validator,
    this.isRequired = false,
    this.displayText,
    this.enabled = true,
    this.icon,
  });

  @override
  State<Dropdown<T>> createState() => _DropdownState<T>();
}

class _DropdownState<T> extends State<Dropdown<T>> {

  final TextEditingController _controller = TextEditingController();

  @override
  void didUpdateWidget(covariant Dropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != oldWidget.value) {
      if (widget.value == null) {
        _controller.clear();
      } else {
        _controller.text =
            widget.displayText?.call(widget.value as T) ??
            widget.value.toString();
      }
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.value != null) {
      _controller.text =
          widget.displayText?.call(widget.value as T) ??
          widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        if (widget.label.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
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
        ],

        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              decoration: BoxDecoration(
                color: widget.enabled
                    ? Colors.white
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: DropdownMenu<T>(
                width: constraints.maxWidth,
                controller: _controller,
                enabled: widget.enabled,
                hintText: widget.hint,

                leadingIcon: widget.icon != null
                    ? Padding(
                        padding: const EdgeInsets.only(left: 14, right: 10),
                        child: Icon(
                          widget.icon,
                          size: 22,
                          color: const Color(0xFF2563EB),
                        ),
                      )
                    : null,

                inputDecorationTheme: const InputDecorationTheme(
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12),
                  hintStyle: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),

                menuHeight: 300,

                trailingIcon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),

                dropdownMenuEntries: widget.items.map((item) {
                  return DropdownMenuEntry<T>(
                    value: item,
                    label: widget.displayText?.call(item) ??
                        item.toString(),
                    style: MenuItemButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  );
                }).toList(),

                onSelected: widget.onChanged,
              ),
            );
          },
        ),
      ],
    );
  }
}