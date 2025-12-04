import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/core/utils/get_device_info.dart';
import 'package:markmeapp/state/auth_state.dart';
import 'package:markmeapp/core/routing/app_router.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Background message handler (only for mobile)
Future<void> _firebaseMessagingHandler(RemoteMessage message) async {
  final platformType = getPlatformType();
  if (platformType == 'android' || platformType == 'ios') {
    await Firebase.initializeApp();
    print("🔥 Background message: ${message.notification?.title}");
  }
}

// Initialize Firebase only on mobile platforms
// Initialize Firebase only on mobile platforms
Future<void> _initializeFirebase() async {
  final platformType = getPlatformType();

  // Skip Firebase initialization on desktop platforms
  if (platformType == 'windows' ||
      platformType == 'macos' ||
      platformType == 'linux') {
    print("🖥️ Skipping Firebase initialization on $platformType");
    return;
  }

  try {
    await Firebase.initializeApp();
    print("✅ Firebase initialized successfully on $platformType");
  } catch (e) {
    print("⚠️ Firebase initialization error on $platformType: $e");
    if (platformType == 'web') {
      print("🌐 Firebase might need web configuration");
    }
  }
}

// Initialize local notifications only on mobile
Future<void> _initLocalNotifications() async {
  final platformType = getPlatformType();

  if (platformType == 'android' || platformType == 'ios') {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        print("📲 Notification clicked (foreground): ${details.payload}");
      },
    );
    print("✅ Local notifications initialized on $platformType");
  } else {
    print("🖥️ Skipping local notifications on $platformType");
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final platformType = getPlatformType();
  print("🚀 Starting app on platform: $platformType");

  // ALWAYS LOAD .env FILE - Your app needs it for API URLs, etc.
  try {
    await dotenv.load(fileName: ".env");
    print("✅ Environment loaded for $platformType");
  } catch (e) {
    print("⚠️ Error loading .env file: $e");
    // Set default environment variables if .env fails
    // This prevents the NotInitializedError
    if (dotenv.env.isEmpty) {
      // Set default mock values for development
      print("⚠️ Setting default environment variables for development");
    }
  }

  // Initialize Firebase only on mobile and web
  await _initializeFirebase();

  // Initialize local notifications
  await _initLocalNotifications();

  // Setup background messages only for mobile
  if (platformType == 'android' || platformType == 'ios') {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingHandler);
    print("✅ FCM background handler registered");
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _hasCheckedSession = false;
  String platformType = 'unknown';
  bool _initializationError = false;

  @override
  void initState() {
    super.initState();
    platformType = getPlatformType();
    print("📱 Current platform: $platformType");

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkUserSession();
    });
  }

  Future<void> _checkUserSession() async {
    try {
      final authStore = ref.read(authStoreProvider.notifier);
      await authStore.loadUserData(ref, context);

      setState(() {
        _hasCheckedSession = true;
      });

      final authState = ref.read(authStoreProvider);

      if (authState.isLoggedIn) {
        final role = authState.role ?? "student";
        final route = _getDashboardRoute(role);
        print("🔑 User logged in as $role, redirecting to $route");
        context.go(route);
      } else {
        print("👤 User not logged in, redirecting to login");
        context.go('/login');
      }
    } catch (e, stackTrace) {
      print("❌ Error checking user session: $e");
      print("Stack trace: $stackTrace");

      setState(() {
        _initializationError = true;
        _hasCheckedSession = true;
      });

      // Redirect to login if there's an error
      context.go('/login');
    }
  }

  String _getDashboardRoute(String role) {
    return switch (role) {
      'teacher' => '/teacher',
      'clerk' => '/clerk',
      'admin' => '/admin',
      _ => '/student',
    };
  }

  // Setup FCM listeners only for mobile
  Future<void> _setupFCMListeners() async {
    if (platformType == 'android' || platformType == 'ios') {
      try {
        FirebaseMessaging messaging = FirebaseMessaging.instance;

        // Print FCM token
        final token = await messaging.getToken();
        print("🔑 FCM Token: $token");

        // Foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print("💬 Foreground message: ${message.notification?.title}");

          final notification = message.notification;
          if (notification != null) {
            flutterLocalNotificationsPlugin.show(
              notification.hashCode,
              notification.title,
              notification.body,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'default_channel',
                  'Notifications',
                  importance: Importance.max,
                  priority: Priority.high,
                ),
              ),
              payload: message.data.toString(),
            );
          }
        });

        // Background messages
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
          print("📲 Notification clicked (background): ${message.data}");
          _navigateFromNotification(message.data);
        });

        // Initial message (app opened from terminated state)
        RemoteMessage? initialMessage = await FirebaseMessaging.instance
            .getInitialMessage();
        if (initialMessage != null) {
          print("🛑 Opened app from terminated: ${initialMessage.data}");
          _navigateFromNotification(initialMessage.data);
        }

        print("✅ FCM listeners setup complete on $platformType");
      } catch (e) {
        print("⚠️ Error setting up FCM on $platformType: $e");
      }
    } else {
      print("🖥️ Skipping FCM setup on $platformType");
    }
  }

  void _navigateFromNotification(Map<String, dynamic> data) {
    if (!mounted) return;

    final route = data["screen"];
    if (route != null && route is String) {
      print("📍 Navigating to: $route from notification");
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(AppRouter.routerProvider);

    // Setup FCM listeners once app is built
    if (!_initializationError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setupFCMListeners();
      });
    }

    // Log route changes
    router.routerDelegate.addListener(() {
      final route = router.routerDelegate.currentConfiguration.uri.toString();
      print('🔵 [Navigation] Current route: $route');
    });

    if (!_hasCheckedSession) {
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
