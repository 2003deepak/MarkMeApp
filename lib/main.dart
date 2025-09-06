import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'data/services/notification_service.dart';
import 'data/services/schedule_service.dart';
import 'presentation/bloc/notification_bloc.dart';
import 'presentation/bloc/schedule_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Notification BLoC Provider
        BlocProvider<NotificationBloc>(
          create: (context) => NotificationBloc(
            notificationService: NotificationService(),
          ),
        ),
        
        // Schedule BLoC Provider
        BlocProvider<ScheduleBloc>(
          create: (context) => ScheduleBloc(
            scheduleService: ScheduleService(),
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'Mark Me',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router, 
      ),
    );
  }
}
