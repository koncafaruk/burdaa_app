import '../datasources/course_local_data_source.dart';
import '../models/course_model.dart';

abstract class CourseRepository {
  Future<List<CourseModel>> getCourses();
  Future<void> addCourse(CourseModel course);
  Future<void> deleteCourse(String id);
}

class CourseRepositoryImpl implements CourseRepository {
  final CourseLocalDataSource localDataSource;

  CourseRepositoryImpl({required this.localDataSource});

  @override
  Future<List<CourseModel>> getCourses() async {
    return await localDataSource.getCourses();
  }

  @override
  Future<void> addCourse(CourseModel course) async {
    await localDataSource.addCourse(course);
  }

  @override
  Future<void> deleteCourse(String id) async {
    await localDataSource.deleteCourse(id);
  }
}
