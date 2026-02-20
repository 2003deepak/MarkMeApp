import 'package:flutter/material.dart';

class UpcomingLecturesSkeleton extends StatelessWidget {
  final bool isDesktop;

  const UpcomingLecturesSkeleton({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title skeleton
          Container(
            width: isDesktop ? 200 : 150,
            height: isDesktop ? 24 : 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 16),

          // Cards skeleton
          if (isDesktop) _buildDesktopSkeleton() else _buildMobileSkeleton(),
        ],
      ),
    );
  }

  Widget _buildDesktopSkeleton() {
    return Row(
      children: [
        Expanded(child: _buildCardSkeleton()),
        const SizedBox(width: 12),
        Expanded(child: _buildCardSkeleton()),
        const SizedBox(width: 12),
        Expanded(child: _buildCardSkeleton()),
      ],
    );
  }

  Widget _buildMobileSkeleton() {
    return Column(
      children: [
        _buildCardSkeleton(),
        const SizedBox(height: 12),
        _buildCardSkeleton(),
      ],
    );
  }

  Widget _buildCardSkeleton() {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject and component skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: isDesktop ? 120 : 100,
                height: isDesktop ? 20 : 18,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: isDesktop ? 60 : 50,
                height: isDesktop ? 24 : 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Teacher skeleton
          Container(
            width: isDesktop ? 80 : 70,
            height: isDesktop ? 16 : 14,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          // Time and countdown skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: isDesktop ? 100 : 80,
                height: isDesktop ? 16 : 14,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: isDesktop ? 50 : 40,
                height: isDesktop ? 24 : 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
