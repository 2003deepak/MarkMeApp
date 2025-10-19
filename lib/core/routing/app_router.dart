import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/presentation/layout/role_based_layout.dart';
import 'package:markmeapp/presentation/pages/student/edit_profile.dart';
import 'package:markmeapp/presentation/pages/student/profile_page.dart';
import 'package:markmeapp/presentation/pages/student/student_dashboard.dart';
import 'package:markmeapp/providers/auth_provider.dart';
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
      debugLogDiagnostics: true,
      initialLocation: '/',

      redirect: (context, state) {
        final auth = ref.read(authStoreProvider);

        // Public routes
        const publicRoutes = [
          '/',
          '/login',
          '/signup',
          '/forgot-password',
          '/reset-password',
        ];

        // Use state.uri.toString() or state.matchedLocation
        final currentLocation = state.uri.toString();
        final goingToPublicRoute = publicRoutes.contains(currentLocation);

        // 1️⃣ Splash screen logic: show only on first load
        if (!auth.hasLoaded) {
          return currentLocation == '/' ? null : '/';
        }

        // 2️⃣ Not logged in → redirect to login for private routes
        if (!auth.isLoggedIn && !goingToPublicRoute) {
          return '/login';
        }

        // 3️⃣ Logged in → redirect away from public routes
        if (auth.isLoggedIn && goingToPublicRoute) {
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

        // 4️⃣ No redirect needed
        return null;
      },

      routes: [
        // ==========================
        // Public routes
        // ==========================
        GoRoute(
          path: '/', 
          name: 'splash',
          builder: (context, state) => const SplashPage()
        ),
        GoRoute(
          path: '/login', 
          name: 'login',
          builder: (context, state) => const LoginPage()
        ),
        GoRoute(
          path: '/signup', 
          name: 'signup',
          builder: (context, state) => const SignupPage()
        ),
        GoRoute(
          path: '/forgot-password', 
          name: 'forgot_password',
          builder: (context, state) => const ForgotPasswordPage()
        ),
        GoRoute(
          path: '/reset-password',
          name: 'reset_password',
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