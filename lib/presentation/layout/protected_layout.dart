import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/state/auth_state.dart';

/// A wrapper that protects routes behind authentication.
/// If user logs out, it redirects to login and shows a snackbar.
class ProtectedLayout extends ConsumerWidget {
  final Widget child;

  const ProtectedLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authStoreProvider, (previous, next) {
      // When user logs out → redirect
      if (previous?.isLoggedIn == true && next.isLoggedIn == false) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // ✅ Ensure a Scaffold exists before showing snackbar
          final messenger = ScaffoldMessenger.maybeOf(context);
          if (messenger != null) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Session expired. Please log in again.'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          context.go('/login');
        });
      }
    });

    return child;
  }
}
