import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputField extends StatefulWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final bool readOnly;
  final bool obscureText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final int? maxLength;
  final bool showCounter;
  final bool isRequired;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;

  const InputField({
    Key? key,
    required this.label,
    this.hintText,
    this.controller,
    this.readOnly = false,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.onTap,
    this.suffixIcon,
    this.maxLength,
    this.showCounter = false,
    this.isRequired = false,
    this.focusNode,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
  }) : super(key: key);

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            if (widget.isRequired)
              const Text(
                '*',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          readOnly: widget.readOnly,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onTap: widget.onTap,
          maxLength: widget.maxLength,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          decoration: InputDecoration(
            hintText: widget.hintText,
            counterText: widget.showCounter ? null : '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: widget.readOnly,
            fillColor: widget.readOnly ? const Color(0xFFF9FAFB) : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: widget.suffixIcon,
          ),
        ),
      ],
    );
  }
}
