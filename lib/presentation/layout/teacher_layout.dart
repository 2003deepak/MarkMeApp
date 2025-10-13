import 'package:flutter/material.dart';

class TeacherLayout extends StatelessWidget {
  final Widget child;
  const TeacherLayout({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        leading: IconButton(
          icon: Icon(Icons.school, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Teacher Dashboard'),
        elevation: 0,
      ),
      body: child,
    );
  }
}
