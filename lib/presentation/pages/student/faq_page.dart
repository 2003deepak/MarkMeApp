import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: MarkMeAppBar(
        title: 'Help & Support',
        onBackPressed: () => context.pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Find answers to common questions about using the app.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 32),
              
              _buildFaqItem(
                context,
                question: 'How do I check my attendance?',
                answer: 'You can view your detailed attendance from the Dashboard. Tap on the circular attendance chart to see subject-wise breakdowns, or view your total percentage at a glance.',
              ),
              const SizedBox(height: 16),
              
              _buildFaqItem(
                context,
                question: 'What happens if I miss a class?',
                answer: 'Your attendance for that class will be marked as absent. If you believe there was an error, you can raise an exception request from the Attendance details screen within 48 hours of the class.',
              ),
              const SizedBox(height: 16),
              
              _buildFaqItem(
                context,
                question: 'How do I find my daily schedule?',
                answer: 'Navigate to the "Timetable" tab from the bottom navigation bar. You can view your classes for today, or select any day of the week from the top selector.',
              ),
              const SizedBox(height: 16),
              
              _buildFaqItem(
                context,
                question: 'Can I change my profile picture?',
                answer: 'Yes, go to the Profile tab, tap on "Edit Profile", and tap your current picture to upload a new one from your gallery or take a new photo.',
              ),
              const SizedBox(height: 16),
              
              _buildFaqItem(
                context,
                question: 'Who do I contact for technical issues?',
                answer: 'If you are experiencing technical difficulties that are not answered here, please reach out to the IT department at it-support@example.edu or visit the IT helpdesk in the administrative block.',
              ),
              const SizedBox(height: 32),
              
              // Contact Support Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEFF6FF), Color(0xFFF0F9FF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE0F2FE),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withAlpha(20),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Still need help?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Our support team is always ready to assist you with any issues.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening Support Chat...')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Contact Support',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, {required String question, required String answer}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10), // 0.04
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // Removes the divider line
        ),
        child: ExpansionTile(
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          iconColor: const Color(0xFF3B82F6),
          collapsedIconColor: const Color(0xFF94A3B8),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          children: [
            Text(
              answer,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
