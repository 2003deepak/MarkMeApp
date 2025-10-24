import 'package:flutter/material.dart';

class StudentEditProfileSkeleton extends StatelessWidget {
  const StudentEditProfileSkeleton({super.key});

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );

  Widget _buildProfileSkeleton() {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: 120,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeaderSkeleton() {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
      child: Container(
        width: 150,
        height: 14,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildInputSkeleton({double? width}) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(12),
      ),
      width: width,
    );
  }

  Widget _buildPersonalInfoSkeleton() {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildInputSkeleton()),
              const SizedBox(width: 12),
              Expanded(child: _buildInputSkeleton()),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputSkeleton(),
          const SizedBox(height: 16),
          _buildInputSkeleton(),
          const SizedBox(height: 16),
          _buildInputSkeleton(),
          const SizedBox(height: 16),
          _buildInputSkeleton(),
        ],
      ),
    );
  }

  Widget _buildAcademicInfoSkeleton() {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInputSkeleton(),
          const SizedBox(height: 16),
          _buildInputSkeleton(),
          const SizedBox(height: 16),
          _buildInputSkeleton(),
          const SizedBox(height: 16),
          _buildInputSkeleton(),
          const SizedBox(height: 16),
          _buildInputSkeleton(),
        ],
      ),
    );
  }

  Widget _buildGallerySkeleton() {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 150,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _buildProfileSkeleton(),
          const SizedBox(height: 24),
          _sectionHeaderSkeleton(),
          _buildPersonalInfoSkeleton(),
          const SizedBox(height: 24),
          _sectionHeaderSkeleton(),
          _buildAcademicInfoSkeleton(),
          const SizedBox(height: 24),
          _sectionHeaderSkeleton(),
          _buildGallerySkeleton(),
          const SizedBox(height: 32),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}
