import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Pages
import 'package:markmeapp/presentation/pages/splash/splash_page.dart';
import 'package:markmeapp/presentation/pages/auth/login_page.dart';
import 'package:markmeapp/presentation/pages/auth/signup_page.dart';
import 'package:markmeapp/presentation/pages/auth/forgot_password_page.dart';
// import 'package:markmeapp/presentation/pages/common/landing_page.dart';
import 'package:markmeapp/presentation/pages/home_page.dart';
import 'package:markmeapp/presentation/pages/notification_page.dart';
import 'package:markmeapp/presentation/pages/schedule_page.dart';
import 'package:markmeapp/presentation/pages/teacher/teacher_dashboard_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),

      // ✅ Teacher
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherDashboardPage(),
        routes: [
          GoRoute(
            path: 'profile',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text("Teacher Profile")),
            ),
          ),
        ],
      ),

      // ✅ Student - Main Home Page with Bottom Navigation
      GoRoute(
        path: '/student',
        builder: (context, state) => const HomePage(),
        routes: [
          // Individual pages accessible via deep links
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationPage(),
          ),
          GoRoute(
            path: 'schedule',
            builder: (context, state) => const SchedulePage(),
          ),
          GoRoute(
            path: 'attendance',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text("Student Attendance")),
            ),
          ),
        ],
      ),
    ],
  );
}
