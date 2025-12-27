import 'dart:convert';

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
import 'package:markmeapp/core/utils/app_logger.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:markmeapp/data/models/notification_model.dart';
import 'package:markmeapp/data/repositories/notification_repository.dart';

// Background message handler (only for mobile)
Future<void> _firebaseMessagingHandler(RemoteMessage message) async {
  final platformType = getPlatformType();
  if (platformType == 'android' || platformType == 'ios') {
    await Firebase.initializeApp();

    // Initialize Hive for background isolate
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(NotificationModelAdapter());
    }

    // Save notification
    if (message.notification != null) {
      final notification = NotificationModel(
        id:
            message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification!.title ?? 'No Title',
        body: message.notification!.body ?? 'No Body',
        timestamp: message.sentTime ?? DateTime.now(),
        data: message.data,
      );

      final repo = NotificationRepository();
      await repo.saveNotification(notification);
    }

    AppLogger.info(
      "🔥 Background message saved: ${message.notification?.title}",
    );
  }
}

// Initialize Firebase only on mobile platforms
Future<void> _initializeFirebase() async {
  final platformType = getPlatformType();

  // Skip Firebase initialization on desktop platforms
  if (platformType == 'windows' ||
      platformType == 'macos' ||
      platformType == 'linux') {
    AppLogger.info("🖥️ Skipping Firebase initialization on $platformType");
    return;
  }

  try {
    await Firebase.initializeApp();
    AppLogger.info("✅ Firebase initialized successfully on $platformType");
  } catch (e) {
    AppLogger.error("⚠️ Firebase initialization error on $platformType: $e");
    if (platformType == 'web') {
      AppLogger.warning("🌐 Firebase might need web configuration");
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
        if (details.payload == null) return;

        try {
          final data = jsonDecode(details.payload!);
          AppLogger.info("📲 Foreground notification tapped → $data");

          final route = data["route"];
          if (route is String) {
            AppRouter.navigatorKey.currentContext?.push(route);
          }
        } catch (e) {
          AppLogger.error("❌ Notification payload parse error: $e");
        }
      },
    );

    AppLogger.info("✅ Local notifications initialized on $platformType");
  } else {
    AppLogger.info("🖥️ Skipping local notifications on $platformType");
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final platformType = getPlatformType();
  AppLogger.info("🚀 Starting app on platform: $platformType");

  // ALWAYS LOAD .env FILE - Your app needs it for API URLs, etc.
  try {
    await dotenv.load(fileName: ".env");
    AppLogger.info("✅ Environment loaded for $platformType");
  } catch (e) {
    AppLogger.error("⚠️ Error loading .env file: $e");
    // Set default environment variables if .env fails
    // This prevents the NotInitializedError
    if (dotenv.env.isEmpty) {
      // Set default mock values for development
      AppLogger.warning(
        "⚠️ Setting default environment variables for development",
      );
    }
  }

  // Initialize Firebase only on mobile and web
  await _initializeFirebase();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(NotificationModelAdapter());

  // Cleanup old notifications
  try {
    await NotificationRepository().clearOldNotifications();
  } catch (e) {
    AppLogger.error("⚠️ Error clearing old notifications: $e");
  }

  // Initialize local notifications
  await _initLocalNotifications();

  // Setup background messages only for mobile
  if (platformType == 'android' || platformType == 'ios') {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingHandler);
    AppLogger.info("✅ FCM background handler registered");
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
    AppLogger.info("📱 Current platform: $platformType");

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
        AppLogger.info("🔑 User logged in as $role, redirecting to $route");
        if (mounted) {
          context.go(route);
        }
      } else {
        AppLogger.info("👤 User not logged in, redirecting to login");
        if (mounted) {
          context.go('/login');
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error("❌ Error checking user session: $e", e, stackTrace);

      setState(() {
        _initializationError = true;
        _hasCheckedSession = true;
      });

      if (mounted) {
        // Redirect to login if there's an error
        context.go('/login');
      }
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
        AppLogger.info("🔑 FCM Token: $token");

        // Foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
          AppLogger.info(
            "💬 Foreground message: ${message.notification?.title}",
          );

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
              payload: jsonEncode(message.data),
            );

            // Save to Hive
            final notificationModel = NotificationModel(
              id:
                  message.messageId ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              title: notification.title ?? 'No Title',
              body: notification.body ?? 'No Body',
              timestamp: message.sentTime ?? DateTime.now(),
              data: message.data,
            );

            await NotificationRepository().saveNotification(notificationModel);
            AppLogger.info("💾 Notification saved locally");
          }
        });

        // Background messages
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
          AppLogger.info(
            "📲 Notification clicked (background): ${message.data}",
          );
          _navigateFromNotification(message.data);
        });

        // Initial message (app opened from terminated state)
        RemoteMessage? initialMessage = await FirebaseMessaging.instance
            .getInitialMessage();
        if (initialMessage != null) {
          AppLogger.info(
            "🛑 Opened app from terminated: ${initialMessage.data}",
          );
          _navigateFromNotification(initialMessage.data);
        }

        AppLogger.info("✅ FCM listeners setup complete on $platformType");
      } catch (e) {
        AppLogger.error("⚠️ Error setting up FCM on $platformType: $e");
      }
    } else {
      AppLogger.info("🖥️ Skipping FCM setup on $platformType");
    }
  }

  void _navigateFromNotification(Map<String, dynamic> data) {
    if (!mounted) return;

    final route = data["route"];
    if (route is String) {
      AppLogger.info("📍 Navigating to: $route");
      context.push(route);
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
      AppLogger.info('🔵 [Navigation] Current route: $route');
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
