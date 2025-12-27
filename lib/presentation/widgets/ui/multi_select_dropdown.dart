import 'package:flutter/material.dart';
import 'package:multi_dropdown/multi_dropdown.dart';

class MultiSelectDropdown<T extends Object> extends StatefulWidget {
  final String label;
  final String hint;
  final List<T> items;
  final List<T> selectedValues;
  final void Function(List<T>) onChanged;
  final String Function(T)? displayText;
  final bool enabled;
  final bool isRequired;

  const MultiSelectDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.selectedValues,
    required this.onChanged,
    this.displayText,
    this.enabled = true,
    this.isRequired = false,
  });

  @override
  State<MultiSelectDropdown<T>> createState() => _MultiSelectDropdownState<T>();
}

class _MultiSelectDropdownState<T extends Object>
    extends State<MultiSelectDropdown<T>> {
  final MultiSelectController<T> _controller = MultiSelectController<T>();
  List<DropdownItem<T>> _dropdownItems = [];

  @override
  void initState() {
    super.initState();
    _scheduleSync();
  }

  @override
  void didUpdateWidget(covariant MultiSelectDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final itemsChanged = !_listEquals(oldWidget.items, widget.items);
    final selectionChanged = !_listEquals(
      oldWidget.selectedValues,
      widget.selectedValues,
    );

    if (itemsChanged || selectionChanged) {
      _scheduleSync();
    }
  }

  void _scheduleSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _dropdownItems = widget.items.map((item) {
        return DropdownItem<T>(
          label: widget.displayText?.call(item) ?? item.toString(),
          value: item,
        );
      }).toList();

      _controller.clearAll();
      _controller.setItems(_dropdownItems);

      for (final value in widget.selectedValues) {
        final index = _dropdownItems.indexWhere((e) => e.value == value);
        if (index != -1) {
          _controller.selectAtIndex(index);
        }
      }
    });
  }

  bool _listEquals(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: RichText(
              text: TextSpan(
                text: widget.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : const Color(0xFF374151),
                ),
                children: [
                  if (widget.isRequired)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: Color(0xFFEF4444)),
                    ),
                ],
              ),
            ),
          ),

        // Dropdown
        MultiDropdown<T>(
          controller: _controller,
          items: _dropdownItems,
          enabled: widget.enabled,
          onSelectionChange: widget.onChanged,

          fieldDecoration: FieldDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
              fontSize: 14,
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF2563EB),
                width: 1.6,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: const Color(0xFFD1D5DB).withOpacity(0.6),
              ),
            ),
            suffixIcon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: Color(0xFF6B7280),
            ),
          ),

          chipDecoration: ChipDecoration(
            backgroundColor: const Color(0xFF2563EB),
            labelStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            deleteIcon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 16,
            ),
            spacing: 6,
            runSpacing: 6,
            wrap: true,
          ),

          dropdownDecoration: DropdownDecoration(
            backgroundColor: isDark ? const Color(0xFF020617) : Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            elevation: 4,
            maxHeight: 260,
            marginTop: 6,
          ),

          dropdownItemDecoration: DropdownItemDecoration(
            selectedIcon: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF2563EB),
              size: 20,
            ),
            selectedTextColor: const Color(0xFF2563EB),
            selectedBackgroundColor: const Color(0xFF2563EB).withOpacity(0.12),
          ),
        ),
      ],
    );
  }
}
