import 'package:flutter/material.dart';

class SaveButtonSection extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback? onClearError;
  final bool isSaveEnabled;
  final bool isLoading;

  const SaveButtonSection({
    super.key,
    required this.onSave,
    this.onClearError,
    this.isSaveEnabled = true,
    this.isLoading = false, // Default to false
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilledButton(
          onPressed: (isSaveEnabled && !isLoading) ? onSave : null,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
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
