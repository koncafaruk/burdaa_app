import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:burdaa_vibe_v1/presentation/courses/bloc/courses_bloc.dart';
import '../bloc/attendance_bloc.dart';
import 'package:burdaa_vibe_v1/data/courses/models/course_model.dart';
import 'package:burdaa_vibe_v1/data/today/models/attendance_record.dart';
import 'package:burdaa_vibe_v1/presentation/courses/pages/course_detail_page.dart';
import 'package:google_fonts/google_fonts.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayWeekday = now.weekday;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bugün',
                  style: GoogleFonts.outfit(
                    textStyle: Theme.of(context).textTheme.headlineLarge
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Harika bir gün seni bekliyor!',
                  style: GoogleFonts.inter(
                    textStyle: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: BlocBuilder<CoursesBloc, CoursesState>(
                    builder: (context, coursesState) {
                      final todayCourses = coursesState.courses
                          .where((c) => c.dayOfWeek == todayWeekday)
                          .toList();

                      if (todayCourses.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 100,
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.2),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Bugün için bir dersin yok',
                                style: GoogleFonts.inter(
                                  textStyle: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return BlocBuilder<AttendanceBloc, AttendanceState>(
                        builder: (context, attendanceState) {
                          return ListView.builder(
                            itemCount: todayCourses.length,
                            itemBuilder: (context, index) {
                              final course = todayCourses[index];
                              final record = attendanceState.records.firstWhere(
                                (r) =>
                                    r.courseId == course.id &&
                                    r.date.year == now.year &&
                                    r.date.month == now.month &&
                                    r.date.day == now.day,
                                orElse: () => AttendanceRecord(
                                  courseId: course.id,
                                  date: now,
                                  status: AttendanceStatus.none,
                                  recordedAt: now,
                                ),
                              );

                              return _TodayCourseCard(
                                course: course,
                                record: record,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayCourseCard extends StatelessWidget {
  final CourseModel course;
  final AttendanceRecord record;

  const _TodayCourseCard({required this.course, required this.record});

  @override
  Widget build(BuildContext context) {
    bool isAttended = record.status == AttendanceStatus.attended;
    bool isMissed = record.status == AttendanceStatus.missed;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseDetailPage(course: course),
                  ),
                );
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: GoogleFonts.outfit(
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        Text(
                          '${course.startTime} - ${course.endTime}',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _AttendanceButton(
                    label: 'Katıldım',
                    icon: Icons.check_circle_rounded,
                    color: Colors.green,
                    isSelected: isAttended,
                    onTap: () {
                      context.read<AttendanceBloc>().add(
                        MarkAttendance(
                          courseId: course.id,
                          status: AttendanceStatus.attended,
                          date: DateTime.now(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AttendanceButton(
                    label: 'Katılmadım',
                    icon: Icons.cancel_rounded,
                    color: Colors.redAccent,
                    isSelected: isMissed,
                    onTap: () {
                      context.read<AttendanceBloc>().add(
                        MarkAttendance(
                          courseId: course.id,
                          status: AttendanceStatus.missed,
                          date: DateTime.now(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _AttendanceButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isSelected ? Colors.white : color),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
