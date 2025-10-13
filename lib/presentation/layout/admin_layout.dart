import 'package:flutter/material.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;
  const AdminLayout({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        leading: IconButton(
          icon: Icon(Icons.school, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('College Admin'),
        elevation: 0,
      ),
      body: child,
    );
  }
}
