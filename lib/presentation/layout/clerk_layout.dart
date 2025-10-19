import 'package:flutter/material.dart';
import 'package:markmeapp/presentation/widgets/bottom_navigation.dart';

class ClerkLayout extends StatelessWidget {
  final Widget child;
  const ClerkLayout({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        leading: IconButton(
          icon: Icon(Icons.school, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('College Clerks'),
        elevation: 0,
      ),
      body: child,

      // FOOTER - Bottom Navigation
      bottomNavigationBar: const BottomNavigation(),
    );
  }
}
