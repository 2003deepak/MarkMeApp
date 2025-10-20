import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/presentation/layout/student_layout.dart';
import 'package:markmeapp/presentation/layout/teacher_layout.dart';
import 'package:markmeapp/presentation/layout/clerk_layout.dart';
import 'package:markmeapp/presentation//layout/guest_layout.dart';
import 'package:markmeapp/providers/auth_provider.dart';

class RoleBasedLayout extends ConsumerWidget {
  final Widget child;

  const RoleBasedLayout({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStoreProvider);

    print('🎭 [RoleBasedLayout] Building layout for role: ${auth.role}');

    switch (auth.role) {
      case 'student':
        return StudentLayout(child: child);
      case 'teacher':
        return TeacherLayout(child: child);
      case 'clerk':
        return ClerkLayout(child: child);
      case 'admin':
        return Scaffold(body: child);
      case 'null':
        return GuestLayout(child: child);

      default:
        return GuestLayout(child: child);
    }
  }
}
