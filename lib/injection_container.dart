import 'package:get_it/get_it.dart';
import 'core/database/database_helper.dart';
import 'data/courses/datasources/course_local_data_source.dart';
import 'data/courses/repositories/course_repository_impl.dart';
import 'presentation/courses/bloc/courses_bloc.dart';
import 'data/today/datasources/attendance_local_data_source.dart';
import 'data/today/repositories/attendance_repository_impl.dart';
import 'presentation/today/bloc/attendance_bloc.dart';
import 'core/util/notification_service.dart';

final sl = GetIt.instance; // sl is service locator

Future<void> init() async {
  // Database
  final databaseHelper = DatabaseHelper.instance;
  sl.registerLazySingleton(() => databaseHelper);

  // Data Sources
  sl.registerLazySingleton<CourseLocalDataSource>(
    () => CourseLocalDataSourceImpl(databaseHelper: sl()),
  );
  sl.registerLazySingleton<AttendanceLocalDataSource>(
    () => AttendanceLocalDataSourceImpl(databaseHelper: sl()),
  );

  // Repositories
  sl.registerLazySingleton<CourseRepository>(
    () => CourseRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(localDataSource: sl()),
  );

  // Blocs
  // Blocs
  sl.registerFactory(
    () => CoursesBloc(repository: sl(), notificationService: sl()),
  );
  sl.registerFactory(() => AttendanceBloc(repository: sl()));

  //! Core
  sl.registerLazySingleton(() => NotificationService());

  //! External
}
