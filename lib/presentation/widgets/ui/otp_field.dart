import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OTPField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final bool autoFocus;
  final bool enabled;
  final TextStyle? textStyle;
  final double fieldWidth;
  final double fieldHeight;
  final Color cursorColor;
  final Color borderColor;
  final Color focusedBorderColor;
  final Color disabledBorderColor;
  final BorderRadius borderRadius;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const OTPField({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.autoFocus = false,
    this.enabled = true,
    this.textStyle,
    this.fieldWidth = 50,
    this.fieldHeight = 60,
    this.cursorColor = Colors.blue,
    this.borderColor = Colors.grey,
    this.focusedBorderColor = Colors.blue,
    this.disabledBorderColor = Colors.grey,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.keyboardType = TextInputType.number,
    this.inputFormatters,
  });

  @override
  State<OTPField> createState() => OTPFieldState();
}

class OTPFieldState extends State<OTPField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late List<String> _otp;

  @override
  void initState() {
    super.initState();
    _initializeOTPFields();
  }

  void _initializeOTPFields() {
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
    _otp = List.generate(widget.length, (index) => '');

    // Add listeners to each controller
    for (int i = 0; i < widget.length; i++) {
      _controllers[i].addListener(() => _onTextChanged(i));
      _focusNodes[i].addListener(() => _onFocusChanged(i));
    }
  }

  void _onTextChanged(int index) {
    String text = _controllers[index].text;

    // Handle paste operation
    if (text.length > 1) {
      _handlePaste(text, index);
      return;
    }

    // Update OTP value
    if (text.isNotEmpty) {
      _otp[index] = text;

      // Move to next field if available
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      }
    } else {
      _otp[index] = '';
    }

    // Check if OTP is complete
    _checkOTPCompletion();
  }

  void _handlePaste(String pastedText, int startIndex) {
    // Clear all fields first
    for (int i = 0; i < widget.length; i++) {
      _controllers[i].text = '';
      _otp[i] = '';
    }

    // Fill fields with pasted text
    for (int i = 0; i < pastedText.length && i < widget.length; i++) {
      _controllers[i].text = pastedText[i];
      _otp[i] = pastedText[i];
    }

    // Move focus to last filled field or last field
    int lastIndex = pastedText.length < widget.length
        ? pastedText.length
        : widget.length - 1;
    _focusNodes[lastIndex].requestFocus();

    _checkOTPCompletion();
  }

  void _onFocusChanged(int index) {
    // Select all text when field gains focus
    if (_focusNodes[index].hasFocus) {
      _controllers[index].selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controllers[index].text.length,
      );
    }
  }

  void _checkOTPCompletion() {
    String otpString = _otp.join('');
    if (otpString.length == widget.length) {
      widget.onCompleted(otpString);
    }
  }

  void _onKeyPressed(KeyEvent event, int index) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controllers[index].text.isEmpty && index > 0) {
          // Move to previous field if current is empty
          _focusNodes[index - 1].requestFocus();
          _controllers[index - 1].text = '';
          _otp[index - 1] = '';
        }
      }
    }
  }

  Widget _buildOTPField(int index) {
    return Container(
      width: widget.fieldWidth,
      height: widget.fieldHeight,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: KeyboardListener(
        focusNode: FocusNode(), // This internal focus node captures key events
        onKeyEvent: (event) => _onKeyPressed(event, index),
        child: TextFormField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: widget.keyboardType,
          inputFormatters:
              widget.inputFormatters ??
              [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
          style:
              widget.textStyle ??
              const TextStyle(fontSize: 18, color: Colors.black),
          enabled: widget.enabled,
          autofocus: widget.autoFocus && index == 0,
          cursorColor: widget.cursorColor,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: widget.borderRadius,
              borderSide: BorderSide(color: widget.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: widget.borderRadius,
              borderSide: BorderSide(color: widget.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: widget.borderRadius,
              borderSide: BorderSide(
                color: widget.focusedBorderColor,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: widget.borderRadius,
              borderSide: BorderSide(color: widget.disabledBorderColor),
            ),
            counterText: '',
          ),
        ),
      ),
    );
  }

  // Method to set initial value
  void setInitialValue(String value) {
    if (value.length == widget.length) {
      for (int i = 0; i < widget.length; i++) {
        _controllers[i].text = value[i];
        _otp[i] = value[i];
      }
      _checkOTPCompletion();
    }
  }

  void clear() {
    for (int i = 0; i < widget.length; i++) {
      _controllers[i].clear();
      _otp[i] = '';
    }
    _focusNodes[0].requestFocus();
  }

  String get value => _otp.join('');

  bool get isComplete => _otp.join('').length == widget.length;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.length,
          (index) => _buildOTPField(index),
        ),
      ),
    );
  }
}
