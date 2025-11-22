import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/state/auth_state.dart';
import 'core/routing/app_router.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> _firebaseMessagingHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔥 Background message: ${message.notification?.title}");
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _initLocalNotifications() async {
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
}

// =======================================================
// MAIN
// =======================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    throw Exception('Error loading .env file: $e');
  }

  await Firebase.initializeApp();
  await _initLocalNotifications();

  // Background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingHandler);

  runApp(const ProviderScope(child: MyApp()));
}

// =======================================================
// APP ROOT
// =======================================================
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

    _setupFCMListeners(); // 🔥 Add FCM integration here

    // ------------------- EXISTING USER SESSION LOGIC -------------------
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authStore = ref.read(authStoreProvider.notifier);
      await authStore.loadUserData(ref, context);

      setState(() {
        _hasCheckedSession = true;
      });

      final authState = ref.read(authStoreProvider);

      if (authState.isLoggedIn) {
        final role = authState.role ?? "student";

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

    // FCM Permission
    FirebaseMessaging.instance.requestPermission();
    // ------------------------------------------------------
  }

  // =======================================================
  // FCM LISTENERS (FOREGROUND, BACKGROUND, TERMINATED)
  // =======================================================
  Future<void> _setupFCMListeners() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Print FCM token
    final token = await messaging.getToken();
    print("🔑 FCM Token: $token");

    // -------------------- FOREGROUND MESSAGES --------------------
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("💬 Foreground message: ${message.notification?.title}");

      final notification = message.notification;

      // Show as local notification
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

    // -------------------- CLICKED FROM BACKGROUND --------------------
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("📲 Notification clicked (background): ${message.data}");
      _navigateFromNotification(message.data);
    });

    // -------------------- OPENED FROM TERMINATED --------------------
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();

    if (initialMessage != null) {
      print("🛑 Opened app from terminated: ${initialMessage.data}");
      _navigateFromNotification(initialMessage.data);
    }
  }

  // =======================================================
  // HANDLE NAVIGATION WHEN USER TAPS NOTIFICATION
  // =======================================================
  void _navigateFromNotification(Map<String, dynamic> data) {
    if (!mounted) return;

    final route = data["screen"];
    if (route != null && route is String) {
      context.go(route);
    }
  }

  // =======================================================
  // UI
  // =======================================================
  @override
  Widget build(BuildContext context) {
    final router = ref.watch(AppRouter.routerProvider);

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
