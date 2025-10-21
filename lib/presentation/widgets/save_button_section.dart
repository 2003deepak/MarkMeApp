import 'package:flutter/material.dart';

class SaveButtonSection extends StatelessWidget {
  final String? errorMessage;
  final bool isUpdating;
  final VoidCallback onSave;
  final VoidCallback onClearError;

  const SaveButtonSection({
    Key? key,
    required this.errorMessage,
    required this.isUpdating,
    required this.onSave,
    required this.onClearError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: onClearError,
                ),
              ],
            ),
          ),
        if (errorMessage != null) const SizedBox(height: 16),
        FilledButton(
          onPressed: isUpdating ? null : onSave,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isUpdating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Save Changes',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
        ),
      ],
    );
  }
}
