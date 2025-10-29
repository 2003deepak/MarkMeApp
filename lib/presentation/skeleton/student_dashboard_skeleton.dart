import 'package:flutter/material.dart';

class DashboardSkeleton extends StatelessWidget {
  final bool isDesktop;

  const DashboardSkeleton({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subject Selector Skeleton
        _buildSubjectSelectorSkeleton(),

        const SizedBox(height: 24),

        // Chart Skeleton
        _buildChartSkeleton(),

        const SizedBox(height: 24),

        // Stats Skeleton
        _buildStatsSkeleton(),

        const SizedBox(height: 24),

        // Upcoming Lectures Skeleton
        _buildUpcomingLecturesSkeleton(),

        const SizedBox(height: 24),

        // Recent Activity Skeleton
        _buildRecentActivitySkeleton(),
      ],
    );
  }

  Widget _buildSubjectSelectorSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterSectionSkeleton(
              chips: [
                _buildChipSkeleton(width: 120),
                _buildChipSkeleton(width: 110),
                _buildChipSkeleton(width: 90),
              ],
            ),
            _buildFilterSectionSkeleton(
              chips: [
                _buildChipSkeleton(width: 140),
                _buildChipSkeleton(width: 130),
                _buildChipSkeleton(width: 150),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSectionSkeleton({required List<Widget> chips}) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  Widget _buildChipSkeleton({required double width}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 12,
        vertical: isDesktop ? 10 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isDesktop ? 16 : 14,
            height: isDesktop ? 16 : 14,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: width - (isDesktop ? 40 : 36),
            height: isDesktop ? 16 : 14,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSkeleton() {
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
          Center(
            child: SizedBox(
              height: isDesktop ? 240 : 220,
              width: isDesktop ? 240 : 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: isDesktop ? 200 : 180,
                    height: isDesktop ? 200 : 180,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: isDesktop ? 116 : 104,
                    height: isDesktop ? 116 : 104,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                  ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [_buildLegendItemSkeleton(), _buildLegendItemSkeleton()],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItemSkeleton() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isDesktop ? 14 : 12,
          height: isDesktop ? 14 : 12,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
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

  Widget _buildStatsSkeleton() {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatItemSkeleton()),
          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.5)),
          Expanded(child: _buildStatItemSkeleton()),
          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.5)),
          Expanded(child: _buildStatItemSkeleton()),
        ],
      ),
    );
  }

  Widget _buildStatItemSkeleton() {
    return Column(
      children: [
        Container(
          width: isDesktop ? 28 : 24,
          height: isDesktop ? 28 : 24,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: isDesktop ? 60 : 50,
          height: isDesktop ? 28 : 24,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 6),
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

  Widget _buildUpcomingLecturesSkeleton() {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isDesktop ? 200 : 150,
            height: isDesktop ? 24 : 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(3, (index) => _buildLectureItemSkeleton()),
        ],
      ),
    );
  }

  Widget _buildLectureItemSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: isDesktop ? 48 : 40,
            height: isDesktop ? 48 : 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: isDesktop ? 200 : 150,
                  height: isDesktop ? 18 : 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: isDesktop ? 120 : 100,
                  height: isDesktop ? 14 : 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: isDesktop ? 80 : 60,
            height: isDesktop ? 32 : 28,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySkeleton() {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isDesktop ? 180 : 140,
            height: isDesktop ? 24 : 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(4, (index) => _buildActivityItemSkeleton()),
        ],
      ),
    );
  }

  Widget _buildActivityItemSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: isDesktop ? 40 : 32,
            height: isDesktop ? 40 : 32,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: isDesktop ? 250 : 200,
                  height: isDesktop ? 16 : 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: isDesktop ? 150 : 120,
                  height: isDesktop ? 14 : 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: isDesktop ? 80 : 60,
            height: isDesktop ? 24 : 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}
