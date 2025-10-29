import 'package:flutter/material.dart';

class SubjectSelectorAnimatedSkeleton extends StatefulWidget {
  final bool isDesktop;

  const SubjectSelectorAnimatedSkeleton({super.key, required this.isDesktop});

  @override
  State<SubjectSelectorAnimatedSkeleton> createState() =>
      _SubjectSelectorAnimatedSkeletonState();
}

class _SubjectSelectorAnimatedSkeletonState
    extends State<SubjectSelectorAnimatedSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = ColorTween(
      begin: Colors.grey.shade300,
      end: Colors.grey.shade200,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildAnimatedFilterSection(
                      chips: [
                        _buildAnimatedChipSkeleton(width: 120),
                        _buildAnimatedChipSkeleton(width: 110),
                        _buildAnimatedChipSkeleton(width: 90),
                      ],
                    ),
                    _buildAnimatedFilterSection(
                      chips: [
                        _buildAnimatedChipSkeleton(width: 140),
                        _buildAnimatedChipSkeleton(width: 130),
                        _buildAnimatedChipSkeleton(width: 150),
                      ],
                    ),
                    _buildAnimatedFilterSection(
                      chips: [
                        _buildAnimatedChipSkeleton(width: 120),
                        _buildAnimatedChipSkeleton(width: 110),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedFilterSection({required List<Widget> chips}) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Wrap(spacing: 8, runSpacing: 8, children: chips)],
      ),
    );
  }

  Widget _buildAnimatedChipSkeleton({required double width}) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isDesktop ? 16 : 12,
            vertical: widget.isDesktop ? 10 : 8,
          ),
          decoration: BoxDecoration(
            color: _animation.value,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade400, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated skeleton icon
              Container(
                width: widget.isDesktop ? 16 : 14,
                height: widget.isDesktop ? 16 : 14,
                decoration: BoxDecoration(
                  color: _animation.value,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              // Animated skeleton text
              Container(
                width: width - (widget.isDesktop ? 40 : 36),
                height: widget.isDesktop ? 16 : 14,
                decoration: BoxDecoration(
                  color: _animation.value,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
