import 'package:flutter/material.dart';

class MultiSelectDropdown<T> extends StatefulWidget {
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

class _MultiSelectDropdownState<T> extends State<MultiSelectDropdown<T>>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _toggleDropdown() {
    if (!widget.enabled) return;

    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _showOverlay();
    _animationController.forward();
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    _animationController.reverse().then((_) {
      _removeOverlay();
      setState(() {
        _isOpen = false;
      });
    });
  }

  void _showOverlay() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Close when tapping outside
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 8),
            child: Material(
              color: Colors.transparent,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SizeTransition(
                  axisAlignment: -1,
                  sizeFactor: _expandAnimation,
                  child: Container(
                    width: size.width,
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shrinkWrap: true,
                        itemCount: widget.items.length,
                        itemBuilder: (context, index) {
                          final item = widget.items[index];
                          final isSelected = widget.selectedValues.contains(
                            item,
                          );
                          final text =
                              widget.displayText?.call(item) ?? item.toString();

                          return _DropdownItem(
                            text: text,
                            isSelected: isSelected,
                            onTap: () {
                              final newValues = List<T>.from(
                                widget.selectedValues,
                              );
                              if (isSelected) {
                                newValues.remove(item);
                              } else {
                                newValues.add(item);
                              }
                              widget.onChanged(newValues);
                              _overlayEntry?.markNeedsBuild();
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    // Generate display text for selected items
    String selectedText = widget.hint;
    if (widget.selectedValues.isNotEmpty) {
      if (widget.selectedValues.length == 1) {
        selectedText =
            widget.displayText?.call(widget.selectedValues.first) ??
            widget.selectedValues.first.toString();
      } else {
        selectedText = "${widget.selectedValues.length} selected";
      }
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          if (widget.label.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 8),
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
          ],

          // Trigger Field
          GestureDetector(
            onTap: _toggleDropdown,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: widget.enabled ? Colors.white : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isOpen
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFD1D5DB),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isOpen
                        ? const Color(0xFF3B82F6).withOpacity(0.15)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      selectedText,
                      style: TextStyle(
                        color: widget.selectedValues.isEmpty
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF111827),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: widget.enabled
                          ? (_isOpen
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF6B7280))
                          : const Color(0xFF9CA3AF),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownItem extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _DropdownItem({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
        child: Row(
          children: [
            // Animated Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFD1D5DB),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected
                      ? const Color(0xFF1E40AF)
                      : const Color(0xFF111827),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
