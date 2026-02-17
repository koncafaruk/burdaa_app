import '../../../core/database/database_helper.dart';
import '../models/attendance_record.dart';

abstract class AttendanceLocalDataSource {
  Future<List<AttendanceRecord>> getAttendance();
  Future<void> markAttendance(AttendanceRecord record);
  Future<void> deleteAttendance(String courseId, DateTime date);
}

class AttendanceLocalDataSourceImpl implements AttendanceLocalDataSource {
  final DatabaseHelper databaseHelper;

  AttendanceLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<AttendanceRecord>> getAttendance() async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('attendance');
    return List.generate(maps.length, (i) => AttendanceRecord.fromMap(maps[i]));
  }

  @override
  Future<void> markAttendance(AttendanceRecord record) async {
    final db = await databaseHelper.database;

    // Check if record exists for this course and date
    final existingRecords = await db.query(
      'attendance',
      where: 'courseId = ? AND date = ?',
      whereArgs: [
        record.courseId,
        record.date.toIso8601String().substring(0, 10),
      ], // Simple date string check if possible, or usually we store YYYY-MM-DD
    );

    // Note: The schema definition says date is TEXT. Ideally YYYY-MM-DD.
    // The record.date is DateTime. We should standardize on storing just the date part for 'date' column.

    // Let's assume record.toMap() handles formatting or we do it here.
    // Ideally AttendanceRecord should handle it. Let's see AttendanceRecord.

    if (existingRecords.isNotEmpty) {
      await db.update(
        'attendance',
        record.toMap(),
        where: 'id = ?',
        whereArgs: [existingRecords.first['id']],
      );
    } else {
      await db.insert('attendance', record.toMap());
    }
  }

  @override
  Future<void> deleteAttendance(String courseId, DateTime date) async {
    final db = await databaseHelper.database;
    await db.delete(
      'attendance',
      where: 'courseId = ? AND date = ?',
      whereArgs: [courseId, date.toIso8601String().substring(0, 10)],
    );
  }
}
