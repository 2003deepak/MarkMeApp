import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';

class TeacherMenuPage extends StatelessWidget {
  final String teacherId;
  final String teacherName;

  const TeacherMenuPage({
    super.key,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: MarkMeAppBar(title: teacherName),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Teacher Actions",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(
                    context,
                    title: "Subject Performance",
                    icon: Icons.analytics_outlined,
                    color: Colors.blue,
                    onTap: () {
                      context.push(
                        '/clerk/teacher/$teacherId/performance', // Updated route path to distinguish from menu
                        extra: teacherName,
                      );
                    },
                  ),
                  _buildMenuCard(
                    context,
                    title: "Attendance History",
                    icon: Icons.history_rounded,
                    color: Colors.orange,
                    onTap: () {
                      // Placeholder
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Coming Soon")),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context,
                    title: "Profile Details",
                    icon: Icons.person_outline_rounded,
                    color: Colors.purple,
                    onTap: () {
                      // Placeholder
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Coming Soon")),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context,
                    title: "Settings & Access",
                    icon: Icons.settings_outlined,
                    color: Colors.teal,
                    onTap: () {
                      // Placeholder
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Coming Soon")),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
