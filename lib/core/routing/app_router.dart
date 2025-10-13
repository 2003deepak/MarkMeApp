import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/presentation/layout/role_based_layout.dart';
import 'package:markmeapp/presentation/pages/student/edit_profile.dart';
import 'package:markmeapp/presentation/pages/student/profile_page.dart';
import 'package:markmeapp/presentation/pages/student/student_dashboard.dart';

// ⬇️ Auth + Layout imports
import 'package:markmeapp/providers/auth_provider.dart';

// ⬇️ Page imports
import 'package:markmeapp/presentation/pages/splash/splash_page.dart';
import 'package:markmeapp/presentation/pages/auth/login_page.dart';
import 'package:markmeapp/presentation/pages/auth/signup_page.dart';
import 'package:markmeapp/presentation/pages/auth/forgot_password_page.dart';
import 'package:markmeapp/presentation/pages/auth/reset_password_page.dart';
import 'package:markmeapp/presentation/pages/teacher/teacher_dashboard_page.dart';
import 'package:markmeapp/presentation/pages/clerk/clerk_dashboard_page.dart';

class AppRouter {
  static final routerProvider = Provider<GoRouter>((ref) {
    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,

      redirect: (context, state) {
        final auth = ref.read(authStoreProvider);
        final goingToLogin = state.uri.toString() == '/login';

        // If not logged in, redirect to login
        if (!auth.isLoggedIn && !goingToLogin) return '/login';

        // If logged in and going to public routes, redirect to dashboard
        if (auth.isLoggedIn) {
          const publicRoutes = [
            '/',
            '/login',
            '/signup',
            '/forgot-password',
            '/reset-password',
          ];
          if (publicRoutes.contains(state.uri.toString())) {
            switch (auth.role) {
              case 'teacher':
                return '/teacher';
              case 'clerk':
                return '/clerk';
              case 'admin':
                return '/admin';
              default:
                return '/student';
            }
          }
        }

        return null; // no redirect
      },

      routes: [
        // ==========================
        // Public routes
        // ==========================
        GoRoute(path: '/', builder: (context, state) => const SplashPage()),
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupPage(),
        ),
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

        // ==========================
        // Authenticated routes with bottom nav (ShellRoute)
        // ==========================
        ShellRoute(
          builder: (context, state, child) => RoleBasedLayout(child: child),
          routes: [
            // Student routes
            GoRoute(
              path: '/student',
              name: 'student_dashboard',
              builder: (context, state) => const StudentDashboard(),
            ),
            GoRoute(
              path: '/student/profile',
              name: 'student_profile',
              builder: (context, state) => const ProfilePage(),
            ),

            // Teacher routes
            GoRoute(
              path: '/teacher',
              name: 'teacher_dashboard',
              builder: (context, state) => const TeacherDashboardPage(),
            ),
            GoRoute(
              path: '/teacher/profile',
              name: 'teacher_profile',
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Teacher Profile'))),
            ),

            // Clerk routes
            GoRoute(
              path: '/clerk',
              name: 'clerk_dashboard',
              builder: (context, state) => const ClerkDashboardPage(),
            ),

            // Admin routes
            GoRoute(
              path: '/admin',
              name: 'admin_dashboard',
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Admin Dashboard'))),
            ),
          ],
        ),

        // ==========================
        // Edit Profile route (no bottom nav)
        // ==========================
        GoRoute(
          path: '/student/edit-profile',
          name: 'edit_profile',
          builder: (context, state) => const EditProfilePage(),
        ),
      ],
    );
  });
}
