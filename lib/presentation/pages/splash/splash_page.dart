import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    // Delay then navigate
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.go('/login'); // 👈 redirect to login page
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: Colors.indigo,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: isDesktop ? 120 : 80,
              height: isDesktop ? 120 : 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.school,
                  color: Colors.indigo,
                  size: isDesktop ? 60 : 40,
                ),
              ),
            ),
            SizedBox(height: isDesktop ? 40 : 24),
            Text(
              "Mark Me",
              style: TextStyle(
                fontSize: isDesktop ? 48 : 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: isDesktop ? 16 : 8),
            Text(
              "Attendance Management System",
              style: TextStyle(
                fontSize: isDesktop ? 20 : 14,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
