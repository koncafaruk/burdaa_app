import 'package:equatable/equatable.dart';

class CourseModel extends Equatable {
  final String id;
  final String title;
  final String? location;
  final int dayOfWeek; // 1-7
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final DateTime startDate;
  final DateTime endDate;
  final int frequency; // 31 for weekly
  final int interval;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CourseModel({
    required this.id,
    required this.title,
    this.location,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.startDate,
    required this.endDate,
    this.frequency = 31,
    this.interval = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    location,
    dayOfWeek,
    startTime,
    endTime,
    startDate,
    endDate,
    frequency,
    interval,
    createdAt,
    updatedAt,
  ];

  Map<String, dynamic> toCourseTable() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'frequency': frequency,
      'interval': interval,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      id: map['id'].toString(),
      title: map['title'],
      location: map['location'],
      dayOfWeek: map['dayOfWeek'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      frequency: map['frequency'] ?? 31,
      interval: map['interval'] ?? 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  CourseModel copyWith({
    String? id,
    String? title,
    String? location,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    DateTime? startDate,
    DateTime? endDate,
    int? frequency,
    int? interval,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
