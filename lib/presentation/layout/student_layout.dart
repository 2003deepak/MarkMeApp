import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/presentation/widgets/bottom_navigation.dart';
import 'package:markmeapp/presentation/widgets/ui/notification_badge.dart';
import 'package:markmeapp/state/auth_state.dart';

class StudentLayout extends ConsumerStatefulWidget {
  final Widget child;

  const StudentLayout({required this.child, super.key});

  @override
  ConsumerState<StudentLayout> createState() => _StudentLayoutState();
}

class _StudentLayoutState extends ConsumerState<StudentLayout> {
  @override
  void initState() {
    super.initState();

    // 🔥 Listen to changes in the auth state once the widget is mounted
    Future.microtask(() {
      ref.listen<AuthState>(authStoreProvider, (previous, next) {
        final wasLoggedIn = previous?.isLoggedIn ?? false;
        final isNowLoggedIn = next.isLoggedIn;

        // If user was logged in and now is logged out → redirect + snackbar
        if (wasLoggedIn && !isNowLoggedIn) {
          debugPrint('🔴 [Auth] Logged out → Redirecting to /login');

          // Show snackbar before navigation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Session expired. Please log in again.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );

          // Navigate to login after short delay (so snackbar is visible)
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) context.go('/login');
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // HEADER - AppBar
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        leading: IconButton(
          icon: const Icon(Icons.school, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mark Me',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 6,
                top: 6,
                child: NotificationBadge(
                  count: 12,
                  backgroundColor: Colors.red.shade600,
                  borderColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),

      // MAIN CONTENT - Child
      body: widget.child,

      // FOOTER - Bottom Navigation
      bottomNavigationBar: const BottomNavigation(userRole: 'student'),
    );
  }
}
