import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/state/auth_state.dart';
import 'package:markmeapp/core/utils/snackbar_utils.dart';

class ProtectedLayout extends ConsumerWidget {
  final Widget child;

  const ProtectedLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authStoreProvider, (previous, next) {
      // When user logs out → redirect
      if (previous?.isLoggedIn == true && next.isLoggedIn == false) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showAppSnackBar(
            'Logged out successfully',
            isError: true,
            context: context,
          );
          context.go('/login');
        });
      }
    });

    return child;
  }
}
