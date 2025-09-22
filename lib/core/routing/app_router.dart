import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/presentation/pages/auth/reset_password_page.dart';

// Pages
import 'package:markmeapp/presentation/pages/splash/splash_page.dart';
import 'package:markmeapp/presentation/pages/auth/login_page.dart';
import 'package:markmeapp/presentation/pages/auth/signup_page.dart';
import 'package:markmeapp/presentation/pages/auth/forgot_password_page.dart';
import 'package:markmeapp/presentation/pages/home_page.dart';
import 'package:markmeapp/presentation/pages/notification_page.dart';
import 'package:markmeapp/presentation/pages/schedule_page.dart';
import 'package:markmeapp/presentation/pages/teacher/teacher_dashboard_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] as String? ?? '';
          final role = extra?['role'] as String? ?? '';

          return ResetPasswordPage(email: email, role: role);
        },
      ),

      // Teacher routes
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherDashboardPage(),
        routes: [
          GoRoute(
            path: 'profile',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text("Teacher Profile"))),
          ),
        ],
      ),

      // Student routes
      GoRoute(
        path: '/student',
        builder: (context, state) => const HomePage(),
        routes: [
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
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text("Student Attendance"))),
          ),
        ],
      ),

      // Admin routes (add these if needed)
      GoRoute(
        path: '/admin-dashboard',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text("Admin Dashboard"))),
      ),
    ],
  );
}
