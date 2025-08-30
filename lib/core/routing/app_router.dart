import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Pages
import 'package:markmeapp/presentation/pages/splash/splash_page.dart';
import 'package:markmeapp/presentation/pages/auth/login_page.dart';
import 'package:markmeapp/presentation/pages/auth/signup_page.dart';
import 'package:markmeapp/presentation/pages/auth/forgot_password_page.dart';
// import 'package:markmeapp/presentation/pages/common/landing_page.dart';
import 'package:markmeapp/presentation/pages/student/student_dashboard.dart';
import 'package:markmeapp/presentation/pages/teacher/teacher_dashboard.dart';

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
        builder: (context, state) => const TeacherDashboard(),
        routes: [
          GoRoute(
            path: 'profile',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text("Teacher Profile")),
            ),
          ),
        ],
      ),

      // ✅ Student
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentDashboard(),
        routes: [
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
