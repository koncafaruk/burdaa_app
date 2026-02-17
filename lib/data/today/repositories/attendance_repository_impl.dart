import '../datasources/attendance_local_data_source.dart';
import '../models/attendance_record.dart';

abstract class AttendanceRepository {
  Future<List<AttendanceRecord>> getAttendance();
  Future<void> markAttendance(AttendanceRecord record);
  Future<void> deleteAttendance(String courseId, DateTime date);
}

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceLocalDataSource localDataSource;

  AttendanceRepositoryImpl({required this.localDataSource});

  @override
  Future<List<AttendanceRecord>> getAttendance() async {
    return await localDataSource.getAttendance();
  }

  @override
  Future<void> markAttendance(AttendanceRecord record) async {
    await localDataSource.markAttendance(record);
  }

  @override
  Future<void> deleteAttendance(String courseId, DateTime date) async {
    await localDataSource.deleteAttendance(courseId, date);
  }
}
