import 'package:flutter/material.dart';

class SwapConfirmationAlert extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const SwapConfirmationAlert({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Swap Approval'),
      content: const Text(
        'If you approve this request, your lecture will be swapped with the requesting teacher.\nThis change will apply only for the selected date.',
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm & Approve'),
        ),
      ],
    );
  }
}
