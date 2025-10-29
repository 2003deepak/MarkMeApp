import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Layouts
import 'package:markmeapp/presentation/layout/guest_layout.dart';
import 'package:markmeapp/presentation/layout/role_based_layout.dart';
import 'package:markmeapp/presentation/layout/protected_layout.dart';

// Auth Pages
import 'package:markmeapp/presentation/pages/splash/splash_page.dart';
import 'package:markmeapp/presentation/pages/auth/login_page.dart';
import 'package:markmeapp/presentation/pages/auth/signup_page.dart';
import 'package:markmeapp/presentation/pages/auth/forgot_password_page.dart';
import 'package:markmeapp/presentation/pages/auth/reset_password_page.dart';
import 'package:markmeapp/presentation/pages/student/change_password.dart';

// Student Pages
import 'package:markmeapp/presentation/pages/student/student_dashboard.dart';
import 'package:markmeapp/presentation/pages/student/profile_page.dart'
    as StudentProfile;
import 'package:markmeapp/presentation/pages/student/edit_profile.dart';
import 'package:markmeapp/presentation/pages/student/timetable.dart';

// Clerk Pages
import 'package:markmeapp/presentation/pages/clerk/dashboard_page.dart';
import 'package:markmeapp/presentation/pages/clerk/profile_page.dart'
    as ClerkProfile;
import 'package:markmeapp/presentation/pages/clerk/add_subject_page.dart';
import 'package:markmeapp/presentation/pages/clerk/add_teacher_page.dart';

// Teacher & Admin Pages
import 'package:markmeapp/presentation/pages/teacher/teacher_dashboard_page.dart';

// State
import 'package:markmeapp/state/auth_state.dart';

/// =============================================================
/// 🚀 APP ROUTER
/// =============================================================
class AppRouter {
  static final routerProvider = Provider<GoRouter>((ref) {
    return GoRouter(
      debugLogDiagnostics: true,
      initialLocation: '/',

      // =========================================================
      // 🔁 GLOBAL REDIRECT LOGIC (auth-aware)
      // =========================================================
      redirect: (context, state) {
        final auth = ref.read(authStoreProvider);

        const publicRoutes = [
          '/',
          '/login',
          '/signup',
          '/forgot-password',
          '/reset-password',
        ];

        final current = state.uri.toString();
        final isPublic = publicRoutes.contains(current);

        // 1️⃣ Splash screen before auth load
        if (!auth.hasLoaded) {
          return current == '/' ? null : '/';
        }

        // 2️⃣ Block access if not logged in
        if (!auth.isLoggedIn && !isPublic) {
          return '/login';
        }

        // 3️⃣ Prevent logged-in users from accessing public routes
        if (auth.isLoggedIn && isPublic) {
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

        return null;
      },

      // =========================================================
      // 🗺️ ROUTE DEFINITIONS
      // =========================================================
      routes: [
        // --------------------------------------------------------
        // 🧭 PUBLIC ROUTES
        // --------------------------------------------------------
        GoRoute(
          path: '/',
          name: 'splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const GuestLayout(child: LoginPage()),
        ),
        GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (context, state) => const GuestLayout(child: SignupPage()),
        ),
        GoRoute(
          path: '/forgot-password',
          name: 'forgot_password',
          builder: (context, state) =>
              const GuestLayout(child: ForgotPasswordPage()),
        ),
        GoRoute(
          path: '/reset-password',
          name: 'reset_password',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final email = extra?['email'] as String? ?? '';
            final role = extra?['role'] as String? ?? '';
            return GuestLayout(
              child: ResetPasswordPage(email: email, role: role),
            );
          },
        ),

        // --------------------------------------------------------
        // 🧱 PROTECTED ROUTES (with ProtectedLayout)
        // --------------------------------------------------------
        ShellRoute(
          builder: (context, state, child) =>
              ProtectedLayout(child: RoleBasedLayout(child: child)),
          routes: [
            // =======================
            // 🧑‍🎓 STUDENT ROUTES
            // =======================
            GoRoute(
              path: '/student',
              name: 'student_dashboard',
              builder: (context, state) => const StudentDashboard(),
            ),
            GoRoute(
              path: '/student/timetable',
              name: 'student_timetable',
              builder: (context, state) => const TimeTablePage(),
            ),
            GoRoute(
              path: '/student/profile',
              name: 'student_profile',
              builder: (context, state) => StudentProfile.ProfilePage(),
            ),

            // =======================
            // 👨‍🏫 TEACHER ROUTES
            // =======================
            GoRoute(
              path: '/teacher',
              name: 'teacher_dashboard',
              builder: (context, state) => const TeacherDashboardPage(),
            ),
            GoRoute(
              path: '/teacher/profile',
              name: 'teacher_profile',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Teacher Profile Page')),
              ),
            ),

            // =======================
            // 🧾 CLERK ROUTES
            // =======================
            GoRoute(
              path: '/clerk',
              name: 'clerk_dashboard',
              builder: (context, state) => const ClerkDashboardPage(),
            ),
            GoRoute(
              path: '/clerk/profile',
              name: 'clerk_profile',
              builder: (context, state) => ClerkProfile.ProfilePage(),
            ),

            // =======================
            // 🛡️ ADMIN ROUTES
            // =======================
            GoRoute(
              path: '/admin',
              name: 'admin_dashboard',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Admin Dashboard Page')),
              ),
            ),
          ],
        ),

        // --------------------------------------------------------
        // ✏️ OUTSIDE-PROTECTED ROUTES (single-purpose pages)
        // --------------------------------------------------------
        GoRoute(
          path: '/student/edit-profile',
          name: 'edit_profile',
          builder: (context, state) => const EditProfilePage(),
        ),
        GoRoute(
          path: '/student/change-password',
          name: 'change_password',
          builder: (context, state) => const ChangePasswordPage(),
        ),
        GoRoute(
          path: '/clerk/add-teacher',
          name: 'add_teacher',
          builder: (context, state) => const AddTeacherPage(),
        ),
        GoRoute(
          path: '/clerk/add-subject',
          name: 'add_subject',
          builder: (context, state) => const AddSubjectPage(),
        ),
      ],
    );
  });
}
