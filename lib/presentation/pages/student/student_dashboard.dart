import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Student Dashboard',
          style: TextStyle(fontSize: isDesktop ? 24 : 20),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, size: isDesktop ? 28 : 24),
            onPressed: () {
              context.go('/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 48.0 : 24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 600 : double.infinity,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school,
                  size: isDesktop ? 120 : 80,
                  color: Colors.blue,
                ),
                SizedBox(height: isDesktop ? 32 : 20),
                Text(
                  'Welcome to Student Dashboard',
                  style: TextStyle(
                    fontSize: isDesktop ? 32 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isDesktop ? 16 : 10),
                Text(
                  'You have successfully logged in as a student',
                  style: TextStyle(
                    fontSize: isDesktop ? 20 : 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 