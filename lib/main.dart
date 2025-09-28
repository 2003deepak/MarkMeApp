import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'data/services/notification_service.dart';
import 'data/services/schedule_service.dart';
import 'presentation/bloc/notification_bloc.dart';
import 'presentation/bloc/schedule_bloc.dart';
import 'stores/auth_store.dart';
import 'state/auth_state.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env"); // Load environment variables
  } catch (e) {
    throw Exception('Error loading .env file: $e'); // Print error if any
  }

  runApp(
    ProviderScope(
      // 👈 Riverpod root
      child: MultiBlocProvider(
        providers: [
          BlocProvider<NotificationBloc>(
            create: (context) =>
                NotificationBloc(notificationService: NotificationService()),
          ),
          BlocProvider<ScheduleBloc>(
            create: (context) =>
                ScheduleBloc(scheduleService: ScheduleService()),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();

    // Load user data once
    Future.microtask(() {
      ref.read(authStoreProvider.notifier).loadUserData();
    });

    // Debug navigation
    AppRouter.router.routerDelegate.addListener(() {
      final route = AppRouter.router.routerDelegate.currentConfiguration.uri
          .toString();
      print('🔵 [Navigation] Current route: $route');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mark Me',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
    );
  }
}
