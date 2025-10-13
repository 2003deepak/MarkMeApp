import 'package:flutter/material.dart';

class GuestLayout extends StatelessWidget {
  final Widget child;
  const GuestLayout({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: child));
  }
}
