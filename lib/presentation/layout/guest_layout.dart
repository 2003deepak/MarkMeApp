import 'package:flutter/material.dart';

class GuestLayout extends StatelessWidget {
  final Widget child;
  const GuestLayout({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        toolbarHeight: 20
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(child: child),
    );
  }
}
