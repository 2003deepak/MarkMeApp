import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:markmeapp/core/routing/app_router.dart';
import 'package:markmeapp/core/utils/app_logger.dart';
import 'package:markmeapp/core/utils/get_device_info.dart';
import 'package:markmeapp/data/models/notification_model.dart';
import 'package:markmeapp/data/repositories/notification_repository.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// 🔥 BACKGROUND FCM HANDLER (MOBILE ONLY)

Future<void> _firebaseMessagingHandler(RemoteMessage message) async {
  final platformType = getPlatformType();
  if (platformType != 'android' && platformType != 'ios') return;

  await Firebase.initializeApp();

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(NotificationModelAdapter());
  }

  if (message.notification != null) {
    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification!.title ?? 'No Title',
      body: message.notification!.body ?? 'No Body',
      timestamp: message.sentTime ?? DateTime.now(),
      data: message.data,
    );

    await NotificationRepository().saveNotification(notification);
  }

  AppLogger.info(
    "🔥 Background notification saved: ${message.notification?.title}",
  );
}

/// 🔥 FIREBASE INIT

Future<void> _initializeFirebase() async {
  final platformType = getPlatformType();

  if (platformType == 'windows' ||
      platformType == 'macos' ||
      platformType == 'linux') {
    AppLogger.info("🖥️ Skipping Firebase on $platformType");
    return;
  }

  try {
    await Firebase.initializeApp();
    AppLogger.info("✅ Firebase initialized on $platformType");
  } catch (e) {
    AppLogger.error("❌ Firebase init failed: $e");
  }
}

/// 🔔 LOCAL NOTIFICATIONS INIT

Future<void> _initLocalNotifications() async {
  final platformType = getPlatformType();

  if (platformType != 'android' && platformType != 'ios') {
    AppLogger.info("🖥️ Skipping local notifications on $platformType");
    return;
  }

  // Android channel
  if (platformType == 'android') {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'default_channel',
      'Notifications',
      description: 'App notifications',
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

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
        final route = data['route'];
        if (route is String) {
          AppRouter.navigatorKey.currentContext?.push(route);
        }
      } catch (e) {
        AppLogger.error("❌ Notification payload error: $e");
      }
    },
  );

  AppLogger.info("✅ Local notifications initialized");
}

/// 🚀 MAIN
///
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final platformType = getPlatformType();
  AppLogger.info("🚀 App starting on $platformType");

  // env
  try {
    await dotenv.load(fileName: ".env");
    AppLogger.info("✅ .env loaded");
  } catch (e) {
    AppLogger.warning("⚠️ .env load failed: $e");
  }

  // firebase
  await _initializeFirebase();

  // hive
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(NotificationModelAdapter());
  }

  try {
    await NotificationRepository().clearOldNotifications();
  } catch (e) {
    AppLogger.warning("⚠️ Cleanup failed: $e");
  }

  // notifications
  await _initLocalNotifications();

  // background fcm
  if (platformType == 'android' || platformType == 'ios') {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingHandler);
  }

  runApp(const ProviderScope(child: MyApp()));
}

/// 🧠 APP ROOT
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final String platformType;

  @override
  void initState() {
    super.initState();
    platformType = getPlatformType();
    AppLogger.info("📱 Platform: $platformType");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupFCMListeners();
    });
  }

  /// 🔔 FCM LISTENERS (FOREGROUND / BACKGROUND / TERMINATED)
  Future<void> _setupFCMListeners() async {
    if (platformType != 'android' && platformType != 'ios') return;

    try {
      final messaging = FirebaseMessaging.instance;

      final token = await messaging.getToken();
      AppLogger.info("🔑 FCM Token: $token");

      // foreground
      FirebaseMessaging.onMessage.listen((message) async {
        final notification = message.notification;
        if (notification == null) return;

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

        final model = NotificationModel(
          id:
              message.messageId ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          title: notification.title ?? 'No Title',
          body: notification.body ?? 'No Body',
          timestamp: message.sentTime ?? DateTime.now(),
          data: message.data,
        );

        await NotificationRepository().saveNotification(model);
      });

      // background click
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _navigateFromNotification(message.data);
      });

      // terminated
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _navigateFromNotification(initialMessage.data);
      }

      AppLogger.info("✅ FCM listeners ready");
    } catch (e) {
      AppLogger.error("❌ FCM setup failed: $e");
    }
  }

  void _navigateFromNotification(Map<String, dynamic> data) {
    final route = data['route'];
    if (route is String) {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(AppRouter.routerProvider);

    return MaterialApp.router(
      title: 'Mark Me',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
