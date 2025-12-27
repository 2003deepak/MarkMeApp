import 'package:flutter/material.dart';

enum AlertType { warning, info, error, success }

class AlertBar extends StatelessWidget {
  final AlertType type;
  final String title;
  final String message;
  final VoidCallback? onDismiss;
  final String? primaryActionText;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;

  const AlertBar({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.onDismiss,
    this.primaryActionText,
    this.onPrimaryAction,
    this.secondaryActionText,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(type);
    final icon = _getIcon(type);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderColor),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor.withAlpha(26), // 0.1
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.textColor,
                          ),
                        ),
                        if (onDismiss != null)
                          GestureDetector(
                            onTap: onDismiss,
                            child: Icon(
                              Icons.close,
                              size: 20,
                              color: colors.textColor.withAlpha(128), // 0.5
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textColor.withAlpha(204), // 0.8
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (primaryActionText != null || secondaryActionText != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (secondaryActionText != null)
                  TextButton(
                    onPressed: onSecondaryAction,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.textColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      secondaryActionText!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                if (secondaryActionText != null) const SizedBox(width: 8),
                if (primaryActionText != null)
                  ElevatedButton(
                    onPressed: onPrimaryAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primaryBtnColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      primaryActionText!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  _AlertColors _getColors(AlertType type) {
    switch (type) {
      case AlertType.warning:
        return _AlertColors(
          backgroundColor: const Color(0xFFFFFBEB),
          borderColor: const Color(0xFFFCD34D),
          shadowColor: const Color(0xFFF59E0B),
          iconColor: const Color(0xFFB45309),
          iconBgColor: const Color(0xFFFEF3C7),
          textColor: const Color(0xFF92400E),
          primaryBtnColor: const Color(0xFFD97706),
        );
      case AlertType.error:
        return _AlertColors(
          backgroundColor: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFFECACA),
          shadowColor: const Color(0xFFEF4444),
          iconColor: const Color(0xFFB91C1C),
          iconBgColor: const Color(0xFFFEE2E2),
          textColor: const Color(0xFF991B1B),
          primaryBtnColor: const Color(0xFFDC2626),
        );
      case AlertType.success:
        return _AlertColors(
          backgroundColor: const Color(0xFFECFDF5),
          borderColor: const Color(0xFFA7F3D0),
          shadowColor: const Color(0xFF10B981),
          iconColor: const Color(0xFF047857),
          iconBgColor: const Color(0xFFD1FAE5),
          textColor: const Color(0xFF065F46),
          primaryBtnColor: const Color(0xFF059669),
        );
      case AlertType.info:
        return _AlertColors(
          backgroundColor: const Color(0xFFEFF6FF),
          borderColor: const Color(0xFFBFDBFE),
          shadowColor: const Color(0xFF3B82F6),
          iconColor: const Color(0xFF1D4ED8),
          iconBgColor: const Color(0xFFDBEAFE),
          textColor: const Color(0xFF1E40AF),
          primaryBtnColor: const Color(0xFF2563EB),
        );
    }
  }

  IconData _getIcon(AlertType type) {
    switch (type) {
      case AlertType.warning:
        return Icons.warning_rounded;
      case AlertType.error:
        return Icons.error_outline_rounded;
      case AlertType.success:
        return Icons.check_circle_outline_rounded;
      case AlertType.info:
        return Icons.info_outline_rounded;
    }
  }
}

class _AlertColors {
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;
  final Color iconColor;
  final Color iconBgColor;
  final Color textColor;
  final Color primaryBtnColor;

  _AlertColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.shadowColor,
    required this.iconColor,
    required this.iconBgColor,
    required this.textColor,
    required this.primaryBtnColor,
  });
}
