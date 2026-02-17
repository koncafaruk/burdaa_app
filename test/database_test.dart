import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:burdaa_vibe_v1/core/database/database_helper.dart';
import 'package:burdaa_vibe_v1/data/courses/models/course_model.dart';
import 'package:burdaa_vibe_v1/data/today/models/attendance_record.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Database schema creation and CRUD', () async {
    try {
      final dbHelper = DatabaseHelper.instance;

      // Use in-memory database for testing
      final db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await dbHelper.createDB(db, version);
          },
        ),
      );

      // 1. Verify Tables Exists
      final tables = await db.query(
        'sqlite_master',
        where: 'type = ?',
        whereArgs: ['table'],
      );
      final tableNames = tables.map((row) => row['name'] as String).toList();
      // Check for existence of key tables
      expect(tableNames, containsAll(['courses', 'attendance']));

      // 2. Insert Course
      final course = CourseModel(
        id: 'course_1',
        title: 'Mathematics',
        location: 'Room 101',
        dayOfWeek: 1, // Monday
        startTime: '10:00',
        endTime: '11:00',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 90)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Manual insert to test helper logic
      await db.insert('courses', course.toCourseTable());

      final savedCourses = await db.query('courses');
      expect(savedCourses.length, 1);
      expect(savedCourses.first['title'], 'Mathematics');
      expect(savedCourses.first['startTime'], '10:00');

      // 3. Mark Attendance (AttendanceLocalDataSource logic simulation)
      final record = AttendanceRecord(
        courseId: course.id,
        date: DateTime.now(),
        status: AttendanceStatus.attended,
        recordedAt: DateTime.now(),
      );

      await db.insert('attendance', record.toMap());

      final records = await db.query('attendance');
      expect(records.length, 1);
      expect(records.first['courseId'], course.id);
      expect(records.first['status'], 1); // 1 = attended

      // 4. Update Attendance
      final updatedRecord = record.copyWith(status: AttendanceStatus.missed);
      await db.update(
        'attendance',
        updatedRecord.toMap(),
        where: 'id = ?',
        whereArgs: [records.first['id']],
      );

      final updatedRecords = await db.query('attendance');
      expect(updatedRecords.length, 1);
      expect(updatedRecords.first['status'], 2); // 2 = missed
    } catch (e, stack) {
      print('TEST FAILED WITH ERROR: $e');
      print(stack);
      rethrow;
    }
  });
}
