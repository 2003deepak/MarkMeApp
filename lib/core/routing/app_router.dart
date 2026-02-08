import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Layouts
import 'package:markmeapp/presentation/layout/guest_layout.dart';
import 'package:markmeapp/presentation/layout/role_based_layout.dart';
import 'package:markmeapp/presentation/layout/protected_layout.dart';
import 'package:markmeapp/presentation/pages/clerk/add_time_table_page.dart';
import 'package:markmeapp/presentation/pages/clerk/attendance_detail_page.dart';
import 'package:markmeapp/presentation/pages/clerk/student_list_page.dart';
import 'package:markmeapp/presentation/pages/clerk/teacher_list_page.dart';
import 'package:markmeapp/presentation/pages/clerk/teacher_overview_page.dart';
import 'package:markmeapp/presentation/pages/clerk/subject_analytics_detail_page.dart';
import 'package:markmeapp/presentation/pages/clerk/teacher_menu_page.dart';

// Auth Pages
import 'package:markmeapp/presentation/pages/splash/splash_page.dart';
import 'package:markmeapp/presentation/pages/auth/login_page.dart';
import 'package:markmeapp/presentation/pages/auth/signup_page.dart';
import 'package:markmeapp/presentation/pages/auth/otp_verification_page.dart';
import 'package:markmeapp/presentation/pages/auth/forgot_password_page.dart';
import 'package:markmeapp/presentation/pages/auth/reset_password_page.dart';
import 'package:markmeapp/presentation/pages/student/attendance_history_page.dart';
import 'package:markmeapp/presentation/pages/student/change_password.dart';

// Student Pages
import 'package:markmeapp/presentation/pages/student/student_dashboard.dart';
import 'package:markmeapp/presentation/pages/student/profile_page.dart'
    as student_profile;
import 'package:markmeapp/presentation/pages/student/edit_profile.dart';
import 'package:markmeapp/presentation/pages/student/timetable.dart';
import 'package:markmeapp/presentation/pages/student/notification_page.dart';

// Clerk Pages
import 'package:markmeapp/presentation/pages/clerk/dashboard_page.dart';
import 'package:markmeapp/presentation/pages/clerk/profile_page.dart'
    as clerk_profile;
import 'package:markmeapp/presentation/pages/clerk/edit_profile.dart' as clerk_edit_profile;
import 'package:markmeapp/presentation/pages/clerk/add_subject_page.dart';
import 'package:markmeapp/presentation/pages/clerk/add_teacher_page.dart';
import 'package:markmeapp/presentation/pages/clerk/add_student_page.dart';
import 'package:markmeapp/presentation/pages/clerk/defaulters_page.dart';
import 'package:markmeapp/presentation/pages/clerk/defaulters_page.dart';
import 'package:markmeapp/presentation/pages/student/weekly_bunk_safety_page.dart';
import 'package:markmeapp/presentation/pages/teacher/attendance_camera_page.dart';
import 'package:markmeapp/presentation/pages/teacher/attendance_marking_page.dart';
import 'package:markmeapp/presentation/pages/teacher/push_notification_page.dart';
import 'package:markmeapp/presentation/pages/teacher/raise_exception_page.dart';
import 'package:markmeapp/presentation/pages/teacher/request_details_page.dart';
import 'package:markmeapp/presentation/pages/teacher/requests_page.dart';
import 'package:markmeapp/presentation/pages/teacher/session_page.dart';

// Teacher Pages
import 'package:markmeapp/presentation/pages/teacher/teacher_dashboard_page.dart';
import 'package:markmeapp/presentation/pages/teacher/profile_page.dart'
    as teacher_profile;
import 'package:markmeapp/presentation/pages/teacher/timetable.dart'
    as teacher_time_table;
import 'package:markmeapp/presentation/pages/teacher/edit_profile.dart'
    as teacher_edit_profile;

// Admin Pages
import 'package:markmeapp/presentation/pages/admin/dashboard_page.dart';
import 'package:markmeapp/presentation/pages/admin/profile_page.dart'
    as admin_profile;
import 'package:markmeapp/presentation/pages/admin/defaulter_teacher_page.dart';

// State
import 'package:markmeapp/state/auth_state.dart';

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authStoreProvider, (_, __) {
      notifyListeners();
    });
  }
}

/// =============================================================
/// 🚀 APP ROUTER
/// =============================================================
class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final routerProvider = Provider<GoRouter>((ref) {
    final refreshNotifier = RouterRefreshNotifier(ref);

    return GoRouter(
      navigatorKey: navigatorKey,
      refreshListenable: refreshNotifier,
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
          '/otp-verification',
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
          builder: (context, state) {
            return GuestLayout(child: LoginPage());
          },
        ),

        GoRoute(
          path: '/otp-verification',
          name: 'otp_verification',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final email = extra['email'] as String? ?? '';
            final role = extra['role'] as String? ?? 'student';
            return GuestLayout(
              child: OTPVerificationPage(email: email, role: role),
            );
          },
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
        // 🧱 PROTECTED ROUTES WITH BOTTOM NAVIGATION
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
              path: '/student/attendance-history',
              name: 'student_attendance_history',
              builder: (context, state) => const AttendanceHistoryPage(),
            ),

            GoRoute(
              path: '/student/profile',
              name: 'student_profile',
              builder: (context, state) => student_profile.ProfilePage(),
            ),

            // =======================
            // 👨‍🏫 TEACHER ROUTES
            // =======================
            GoRoute(
              path: '/teacher',
              name: 'teacher_dashboard',
              builder: (context, state) => const TeacherDashboard(),
            ),
            GoRoute(
              path: '/teacher/profile',
              name: 'teacher_profile',
              builder: (context, state) => const teacher_profile.ProfilePage(),
            ),
            GoRoute(
              path: '/teacher/timetable',
              name: 'teacher_timetable',
              builder: (context, state) =>
                  const teacher_time_table.TimeTablePage(),
            ),
            GoRoute(
              path: '/teacher/attendance-history',
              name: 'teacher_attendance_history',
              builder: (context, state) => const AttendanceHistoryPage(),
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
              builder: (context, state) => clerk_profile.ProfilePage(),
            ),
            GoRoute(
              path: '/clerk/student-list',
              name: 'student_list',
              builder: (context, state) => StudentListPage(),
            ),
            GoRoute(
              path: '/clerk/teacher-list',
              name: 'teacher_list',
              builder: (context, state) => TeacherListPage(),
            ),

            // =======================
            // 🛡️ ADMIN ROUTES
            // =======================
            GoRoute(
              path: '/admin',
              name: 'admin_dashboard',
              builder: (context, state) => const AdminDashboardPage(),
            ),
            GoRoute(
              path: '/admin/profile',
              name: 'admin_profile',
              builder: (context, state) => const admin_profile.ProfilePage(),
            )
          ],
        ),

        // --------------------------------------------------------
        // 🔒 PROTECTED ROUTES WITHOUT BOTTOM NAVIGATION
        // --------------------------------------------------------
        ShellRoute(
          builder: (context, state, child) => ProtectedLayout(child: child),
          routes: [
            GoRoute(
              path: '/student/edit-profile',
              name: 'edit_profile',
              builder: (context, state) => const EditProfilePage(),
            ),
            GoRoute(
              path: '/change-password',
              name: 'change_password',
              builder: (context, state) => const ChangePasswordPage(),
            ),
            GoRoute(
              path: '/notifications',
              name: 'notifications',
              builder: (context, state) => const NotificationPage(),
            ),
            GoRoute(
              path: '/student/weekly-bunk-safety',
              name: 'student_weekly_bunk_safety',
              builder: (context, state) => const WeeklyBunkSafetyPage(),
            ),
            GoRoute(
              path: '/clerk/add-teacher',
              name: 'add_teacher',
              builder: (context, state) => const AddTeacherPage(),
            ),
             GoRoute(
              path: '/clerk/edit-profile',
              name: 'clerk_edit_profile',
              builder: (context, state) => const clerk_edit_profile.ClerkEditProfilePage(),
            ),
            GoRoute(
              path: '/clerk/attendance-history',
              name: 'clerk_attendance_history',
              builder: (context, state) => const AttendanceHistoryPage(),
            ),
            GoRoute(
              path: '/clerk/new-student',
              name: 'add_student',
              builder: (context, state) => const AddStudentPage(),
            ),
            GoRoute(
              path: '/clerk/add-subject',
              name: 'add_subject',
              builder: (context, state) => const AddSubjectPage(),
            ),
            GoRoute(
              path: '/clerk/add-time-table',
              name: 'time-table',
              builder: (context, state) => const AddTimeTablePage(),
            ),
            GoRoute(
              path: '/clerk/defaulters',
              name: 'clerk_defaulters',
              builder: (context, state) => const DefaultersPage(),
            ),
            GoRoute(
              path: '/:role/attendance-detail/:id',
              name: 'attendance-detail',
              builder: (context, state) {
                final attendanceId = state.pathParameters['id']!;
                return AttendanceDetailPage(attendanceId: attendanceId);
              },
            ),
            GoRoute(
              path: '/teacher/push-notification',
              name: 'push_notification',
              builder: (context, state) => const PushNotificationPage(),
            ),
            GoRoute(
              path: '/teacher/requests',
              name: 'teacher_requests',
              builder: (context, state) => const RequestsPage(),
            ),
            GoRoute(
              path: '/teacher/request/:id',
              name: 'teacher_request_details',
              builder: (context, state) => RequestDetailsPage(
                requestId: state.pathParameters['id'] ?? '',
              ),
            ),
            GoRoute(
              path: '/teacher/session/capture',
              name: 'capture_attendance',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>? ?? {};
                final sessionData =
                    extra['sessionData'] as Map<String, dynamic>? ?? {};

                return CameraCaptureScreen(sessionData: sessionData);
              },
            ),
            GoRoute(
              path: '/teacher/session/:id',
              name: 'start_session',
              builder: (context, state) {
                final sessionData = state.extra as Map<String, dynamic>? ?? {};
                return SessionPage(sessionData: sessionData);
              },
            ),
            GoRoute(
              path: '/teacher/new-exception-request',
              name: 'new_exception_request',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>? ?? {};
                final sessionData =
                    extra['session_data'] as Map<String, dynamic>? ?? {};

                return RaiseExceptionPage(sessionData: sessionData);
              },
            ),

            GoRoute(
              path: '/teacher/mark-attendance',
              name: 'mark-attendance',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>? ?? {};
                final sessionData =
                    extra['session_data'] as Map<String, dynamic>? ?? {};
                final images = extra['images'] as List<XFile>? ?? [];
                final attendanceId = extra['attendance_id'] as String? ?? '';

                return AttendanceMarkingPage(
                  attendanceId: attendanceId,
                  sessionData: sessionData,
                  images: images,
                );
              },
            ),


            // Teacher Profile Edit
            GoRoute(
              path: '/teacher/edit-profile',
              name: 'teacher_edit_profile',
              builder:
                  (context, state) =>
                      const teacher_edit_profile.TeacherEditProfilePage(),
            ),

            // Clerk Analytics Routes

            // 1. Menu Page (Landing)
            GoRoute(
              path: '/clerk/teacher/:teacherId',
              name: 'clerk_teacher_menu',
              builder: (context, state) {
                final teacherId = state.pathParameters['teacherId']!;
                final teacherName = state.extra as String? ?? 'Teacher Actions';
                return TeacherMenuPage(
                  teacherId: teacherId,
                  teacherName: teacherName,
                );
              },
            ),

            // 2. Performance Overview (Analysis)
            GoRoute(
              path: '/clerk/teacher/:teacherId/performance',
              name: 'clerk_teacher_performance',
              builder: (context, state) {
                final teacherId = state.pathParameters['teacherId']!;
                final teacherName =
                    state.extra as String? ?? 'Performance Analysis';
                return TeacherOverviewPage(
                  teacherId: teacherId,
                  teacherName: teacherName,
                );
              },
            ),

            // 3. Subject Detail
            GoRoute(
              path: '/clerk/teacher/:teacherId/subject/:subjectId',
              name: 'clerk_subject_analytics',
              builder: (context, state) {
                final teacherId = state.pathParameters['teacherId']!;
                final subjectId = state.pathParameters['subjectId']!;
                return SubjectAnalyticsDetailPage(
                  teacherId: teacherId,
                  subjectId: subjectId,
                );
              },
            ),


            // Admin Page
            GoRoute(
              path: '/admin/defaulter-teachers',
              name: 'admin_defaulter_teachers',
              builder: (context, state) => const AdminDefaulterTeacherPage(),
            ),
          ],
        ),
      ],
    );
  });
}
