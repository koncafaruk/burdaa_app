import 'package:burdaa_vibe_v1/core/util/notification_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:burdaa_vibe_v1/data/courses/models/course_model.dart';
import 'package:burdaa_vibe_v1/data/courses/repositories/course_repository_impl.dart';

// Events
abstract class CoursesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadCourses extends CoursesEvent {}

class AddCourse extends CoursesEvent {
  final CourseModel course;
  AddCourse(this.course);
  @override
  List<Object?> get props => [course];
}

class DeleteCourse extends CoursesEvent {
  final String courseId;
  DeleteCourse(this.courseId);
  @override
  List<Object?> get props => [courseId];
}

// State
class CoursesState extends Equatable {
  final List<CourseModel> courses;

  const CoursesState({this.courses = const []});

  @override
  List<Object?> get props => [courses];
}

// Bloc
class CoursesBloc extends Bloc<CoursesEvent, CoursesState> {
  final CourseRepository repository;
  final NotificationService notificationService;

  CoursesBloc({required this.repository, required this.notificationService})
    : super(const CoursesState()) {
    on<LoadCourses>((event, emit) async {
      final courses = await repository.getCourses();
      emit(CoursesState(courses: courses));
    });

    on<AddCourse>((event, emit) async {
      await repository.addCourse(event.course);
      await notificationService.scheduleCourseNotification(event.course);
      add(LoadCourses());
    });

    on<DeleteCourse>((event, emit) async {
      await repository.deleteCourse(event.courseId);
      await notificationService.cancelCourseNotification(event.courseId);
      add(LoadCourses());
    });
  }
}
