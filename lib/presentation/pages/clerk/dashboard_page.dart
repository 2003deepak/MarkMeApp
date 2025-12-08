import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/presentation/widgets/dashboard_action_card.dart';
import 'package:markmeapp/presentation/widgets/recent_activity.dart';

class ClerkDashboardPage extends StatefulWidget {
  const ClerkDashboardPage({super.key});

  @override
  State<ClerkDashboardPage> createState() => _ClerkDashboardPageState();
}

class _ClerkDashboardPageState extends State<ClerkDashboardPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildDashboardContent());
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 24),
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                buildRecentActivitySection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.people_alt_outlined,
            label: 'Total Students',
            value: '245',
            color: Colors.blue.shade600,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.person_outline,
            label: 'Students Present',
            value: '198',
            color: Colors.green.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        DashboardActionCard(
          icon: Icons.person_add_alt_1_outlined,
          title: "Add Student",
          onTap: () {
            context.push('/clerk/new-student');
          },
          color: const Color(0xFF64B5F6),
          index: 0,
        ),
        DashboardActionCard(
          icon: Icons.person_add_alt_outlined,
          title: "Add Teacher",
          onTap: () {
            context.push('/clerk/add-teacher');
          },
          color: const Color(0xFF81C784),
          index: 1,
        ),
        DashboardActionCard(
          icon: Icons.assignment_outlined,
          title: "Add Subject",
          onTap: () {
            context.push('/clerk/add-subject');
          },
          color: const Color(0xFFBA68C8),
          index: 2,
        ),
        DashboardActionCard(
          icon: Icons.calendar_month_outlined,
          title: "Set Timetable",
          onTap: () {
            context.push('/clerk/add-time-table');
          },
          color: const Color(0xFFFFB74D),
          index: 3,
        ),
      ],
    );
  }
}
