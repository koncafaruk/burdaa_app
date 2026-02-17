import '../../../core/database/database_helper.dart';
import '../models/course_model.dart';

abstract class CourseLocalDataSource {
  Future<List<CourseModel>> getCourses();
  Future<void> addCourse(CourseModel course);
  Future<void> deleteCourse(String id);
}

class CourseLocalDataSourceImpl implements CourseLocalDataSource {
  final DatabaseHelper databaseHelper;

  CourseLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<CourseModel>> getCourses() async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('courses');
    return List.generate(maps.length, (i) => CourseModel.fromMap(maps[i]));
  }

  @override
  Future<void> addCourse(CourseModel course) async {
    final db = await databaseHelper.database;
    await db.insert('courses', course.toCourseTable());
  }

  @override
  Future<void> deleteCourse(String id) async {
    final db = await databaseHelper.database;
    await db.delete('courses', where: 'id = ?', whereArgs: [id]);
  }
}
