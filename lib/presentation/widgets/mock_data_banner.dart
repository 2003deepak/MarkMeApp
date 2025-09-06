import 'package:flutter/material.dart';

/// Banner widget to show when mock data is being used
/// This helps developers and users understand when the app is running with mock data
class MockDataBanner extends StatelessWidget {
  final bool showBanner;
  final String message;

  const MockDataBanner({
    Key? key,
    this.showBanner = true,
    this.message = 'Using Mock Data - Backend Not Connected',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!showBanner) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        border: Border(
          bottom: BorderSide(
            color: Colors.orange.shade300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            color: Colors.orange.shade700,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.developer_mode,
            color: Colors.orange.shade700,
            size: 16,
          ),
        ],
      ),
    );
  }
}