import 'package:flutter/material.dart';

class AttendanceChartSkeleton extends StatelessWidget {
  final bool isDesktop;

  const AttendanceChartSkeleton({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FAFF), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Skeleton Pie Chart
          Center(
            child: SizedBox(
              height: isDesktop ? 240 : 220,
              width: isDesktop ? 240 : 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Skeleton outer ring
                  Container(
                    width: isDesktop ? 200 : 180,
                    height: isDesktop ? 200 : 180,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),

                  // Skeleton center space
                  Container(
                    width: isDesktop ? 116 : 104, // centerSpaceRadius * 2
                    height: isDesktop ? 116 : 104,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                  ),

                  // Skeleton percentage text
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: isDesktop ? 80 : 70,
                        height: isDesktop ? 32 : 28,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: isDesktop ? 60 : 50,
                        height: isDesktop ? 16 : 14,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Skeleton Legend
          _buildSkeletonLegend(),
        ],
      ),
    );
  }

  Widget _buildSkeletonLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [_buildSkeletonLegendItem(), _buildSkeletonLegendItem()],
    );
  }

  Widget _buildSkeletonLegendItem() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Skeleton color circle
        Container(
          width: isDesktop ? 14 : 12,
          height: isDesktop ? 14 : 12,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        // Skeleton text
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: isDesktop ? 60 : 50,
              height: isDesktop ? 16 : 14,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: isDesktop ? 40 : 30,
              height: isDesktop ? 12 : 10,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
