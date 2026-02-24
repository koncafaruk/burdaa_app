import 'package:flutter/material.dart';
import 'injection_container.dart' as di;
import 'core/util/notification_service.dart';
import 'presentation/home/pages/main_screen.dart';
import 'presentation/courses/bloc/courses_bloc.dart';
import 'presentation/today/bloc/attendance_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  await NotificationService().init();
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => di.sl<CoursesBloc>()..add(LoadCourses()),
        ),
        BlocProvider(
          create: (context) => di.sl<AttendanceBloc>()..add(LoadAttendance()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Burdaa Vibe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1C1B1F),
      ),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}
