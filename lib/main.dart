import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'data/services/notification_service.dart';
import 'data/services/schedule_service.dart';
import 'presentation/bloc/notification_bloc.dart';
import 'presentation/bloc/schedule_bloc.dart';
import 'package:provider/provider.dart'; 
import 'presentation/state/auth_provider.dart';

void main() async { 
  WidgetsFlutterBinding.ensureInitialized(); 

  await dotenv.load(fileName: "/home/deepakcodex/Desktop/MarkMeApp/.env"); 

  runApp(
    MultiProvider(
      providers: [
        BlocProvider<NotificationBloc>(
          create: (context) => NotificationBloc(
            notificationService: NotificationService(),
          ),
        ),
        BlocProvider<ScheduleBloc>(
          create: (context) => ScheduleBloc(
            scheduleService: ScheduleService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthProvider()..loadUserData(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Add navigation listener for debugging
    AppRouter.router.routerDelegate.addListener(() {
      final route = AppRouter.router.routerDelegate.currentConfiguration.uri.toString();
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