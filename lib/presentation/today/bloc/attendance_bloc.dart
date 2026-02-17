import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:burdaa_vibe_v1/data/today/models/attendance_record.dart';
import 'package:burdaa_vibe_v1/data/today/repositories/attendance_repository_impl.dart';

// Events
abstract class AttendanceEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadAttendance extends AttendanceEvent {}

class MarkAttendance extends AttendanceEvent {
  final String courseId;
  final AttendanceStatus status;
  final DateTime date;

  MarkAttendance({
    required this.courseId,
    required this.status,
    required this.date,
  });

  @override
  List<Object?> get props => [courseId, status, date];
}

class DeleteAttendance extends AttendanceEvent {
  final String courseId;
  final DateTime date;

  DeleteAttendance({required this.courseId, required this.date});

  @override
  List<Object?> get props => [courseId, date];
}

// State
class AttendanceState extends Equatable {
  final List<AttendanceRecord> records;

  const AttendanceState({this.records = const []});

  @override
  List<Object?> get props => [records];
}

// Bloc
class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepository repository;

  AttendanceBloc({required this.repository}) : super(const AttendanceState()) {
    on<LoadAttendance>((event, emit) async {
      final records = await repository.getAttendance();
      emit(AttendanceState(records: records));
    });

    on<MarkAttendance>((event, emit) async {
      await repository.markAttendance(
        AttendanceRecord(
          courseId: event.courseId,
          date: event.date,
          status: event.status,
          recordedAt: DateTime.now(),
        ),
      );
      add(LoadAttendance());
    });

    on<DeleteAttendance>((event, emit) async {
      await repository.deleteAttendance(event.courseId, event.date);
      add(LoadAttendance());
    });
  }
}
