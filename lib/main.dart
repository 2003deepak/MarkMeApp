import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/state/auth_state.dart';
import 'core/routing/app_router.dart';

Future<void> _firebaseMessagingHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    throw Exception('Error loading .env file: $e');
  }

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingHandler);

  runApp(const ProviderScope(child: MyApp()));
}

/// Root Widget
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _hasCheckedSession = false;

  @override
  void initState() {
    super.initState();

    // ✅ Wait for build to complete before using context
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authStore = ref.read(authStoreProvider.notifier);
      await authStore.loadUserData(ref, context);

      setState(() {
        _hasCheckedSession = true;
      });

      // ✅ Navigate only when context is ready
      final authState = ref.read(authStoreProvider);

      if (authState.isLoggedIn) {
        final role = authState.role ?? "student"; // or "teacher" etc.

        if (role == "student") {
          context.go('/student/dashboard');
        } else if (role == "teacher") {
          context.go('/teacher/dashboard');
        } else {
          context.go('/login');
        }
      } else {
        context.go('/login');
      }
    });

    // FCM Permissions
    late FirebaseMessaging messaging;
    messaging = FirebaseMessaging.instance;
    messaging.requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(AppRouter.routerProvider);

    // Optional debug listener
    router.routerDelegate.addListener(() {
      final route = router.routerDelegate.currentConfiguration.uri.toString();
      print('🔵 [Navigation] Current route: $route');
    });

    if (!_hasCheckedSession) {
      // ✅ Simple splash/loading screen until session check completes
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp.router(
      title: 'Mark Me',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
