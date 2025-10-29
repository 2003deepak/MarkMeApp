import 'package:flutter/material.dart';

class AttendanceStatsSkeleton extends StatelessWidget {
  final bool isDesktop;

  const AttendanceStatsSkeleton({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(child: _buildSkeletonItem()),
          _divider(),
          Expanded(child: _buildSkeletonItem()),
          _divider(),
          Expanded(child: _buildSkeletonItem()),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 50, color: Colors.white.withOpacity(0.5));

  Widget _buildSkeletonItem() {
    return Column(
      children: [
        // Skeleton icon
        Container(
          width: isDesktop ? 28 : 24,
          height: isDesktop ? 28 : 24,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        // Skeleton value
        Container(
          width: isDesktop ? 60 : 50,
          height: isDesktop ? 28 : 24,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 6),
        // Skeleton label
        Container(
          width: isDesktop ? 80 : 70,
          height: isDesktop ? 16 : 14,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
