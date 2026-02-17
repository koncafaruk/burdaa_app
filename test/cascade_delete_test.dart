import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:burdaa_vibe_v1/core/database/database_helper.dart'; // Make sure this path is correct
import 'package:burdaa_vibe_v1/data/courses/models/course_model.dart';
import 'package:burdaa_vibe_v1/data/today/models/attendance_record.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Cascade delete removes attendance records when course is deleted', () async {
    // 1. Initialize Database
    final dbHelper = DatabaseHelper.instance;
    // We use inMemoryDatabasePath, BUT use the helper's create/configure logic
    // However, DatabaseHelper defaults to 'burdaa_vibe.db'.
    // We need to verify if we can inject different path or if we need to mock it.
    // Given the helper structure, it's hard to swap the path easily without changing the class.
    // For this test, let's use the actual factory but open an in-memory db manually
    // using the helper's callbacks to ensure onConfigure is run.

    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          // Manually enable foreign keys as per the helper's expected behavior
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await dbHelper.createDB(db, version);
        },
      ),
    );

    // 2. Create Course
    final course = CourseModel(
      id: 'course_to_delete',
      title: 'Physics',
      location: 'Lab 1',
      dayOfWeek: 2,
      startTime: '14:00',
      endTime: '16:00',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await db.insert('courses', course.toCourseTable());

    // 3. Create Attendance Record linked to Course
    final record = AttendanceRecord(
      courseId: course.id,
      date: DateTime.now(),
      status: AttendanceStatus.attended,
      recordedAt: DateTime.now(),
    );
    await db.insert('attendance', record.toMap());

    // Verify record exists
    var records = await db.query(
      'attendance',
      where: 'courseId = ?',
      whereArgs: [course.id],
    );
    expect(
      records.length,
      1,
      reason: 'Attendance record should exist before deletion',
    );

    // 4. Delete Course
    await db.delete('courses', where: 'id = ?', whereArgs: [course.id]);

    // 5. Verify Cascade Delete
    records = await db.query(
      'attendance',
      where: 'courseId = ?',
      whereArgs: [course.id],
    );
    expect(
      records.length,
      0,
      reason: 'Attendance record should be deleted via cascade',
    );

    await db.close();
  });
}
