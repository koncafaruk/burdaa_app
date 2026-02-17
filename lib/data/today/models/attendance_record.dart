import 'package:equatable/equatable.dart';

enum AttendanceStatus { attended, missed, none }

class AttendanceRecord extends Equatable {
  final int? id;
  final String courseId;
  final DateTime date;
  final AttendanceStatus status;
  final DateTime recordedAt;
  final String? notes;

  const AttendanceRecord({
    this.id,
    required this.courseId,
    required this.date,
    this.status = AttendanceStatus.none,
    required this.recordedAt,
    this.notes,
  });

  @override
  List<Object?> get props => [id, courseId, date, status, recordedAt, notes];

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'date':
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}", // YYYY-MM-DD
      'status': status.index,
      'recordedAt': recordedAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'],
      courseId: map['courseId'].toString(),
      date: DateTime.parse(map['date']),
      status: AttendanceStatus.values[map['status'] ?? 0],
      recordedAt: DateTime.parse(map['recordedAt']),
      notes: map['notes'],
    );
  }

  AttendanceRecord copyWith({
    int? id,
    String? courseId,
    DateTime? date,
    AttendanceStatus? status,
    DateTime? recordedAt,
    String? notes,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      date: date ?? this.date,
      status: status ?? this.status,
      recordedAt: recordedAt ?? this.recordedAt,
      notes: notes ?? this.notes,
    );
  }
}
