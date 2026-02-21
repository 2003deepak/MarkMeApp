import 'package:flutter/material.dart';

class ConfirmationCard extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback? onDismiss;
  final bool isError;

  const ConfirmationCard({
    super.key,
    required this.title,
    required this.message,
    this.onDismiss,
    this.isError = false,
  });

  @override
  State<ConfirmationCard> createState() => _ConfirmationCardState();
}

class _ConfirmationCardState extends State<ConfirmationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Colors based on isError state
    final backgroundColor =
        widget.isError ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4); // red-50 : green-50
    final borderColor =
        widget.isError ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0); // red-200 : green-200
    final shadowColor =
        widget.isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A); // red-600 : green-600
    final circleColor =
        widget.isError ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7); // red-100 : green-100
    final iconColor =
        widget.isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A); // red-600 : green-600
    final titleColor =
        widget.isError ? const Color(0xFFB91C1C) : const Color(0xFF15803D); // red-700 : green-700
    final bodyColor =
        widget.isError ? const Color(0xFF991B1B) : const Color(0xFF166534); // red-800 : green-800
    final iconData =
        widget.isError ? Icons.error_outline_rounded : Icons.check_circle_rounded;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                widget.message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: bodyColor,
                      height: 1.4,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
