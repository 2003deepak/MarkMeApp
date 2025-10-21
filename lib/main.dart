import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/state/auth_state.dart';

import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    throw Exception('Error loading .env file: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

/// Root Widget
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final authStore = ref.read(authStoreProvider.notifier);
      authStore.loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(AppRouter.routerProvider);

    // Add navigation listener for debugging
    router.routerDelegate.addListener(() {
      final route = router.routerDelegate.currentConfiguration.uri.toString();
      final fullPath = router.routerDelegate.currentConfiguration.fullPath;
      print('🔵 [Navigation] Current route: $route');
      print('🔵 [Navigation] Full path: $fullPath');
    });

    return MaterialApp.router(
      title: 'Mark Me',
      debugShowCheckedModeBanner: false,
      // theme: AppTheme.lightTheme,
      // darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
