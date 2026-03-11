import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:burdaa_vibe_v1/presentation/courses/bloc/courses_bloc.dart';
import '../bloc/attendance_bloc.dart';
import 'package:burdaa_vibe_v1/data/courses/models/course_model.dart';
import 'package:burdaa_vibe_v1/data/today/models/attendance_record.dart';
import 'package:burdaa_vibe_v1/presentation/courses/pages/course_detail_page.dart';
import 'package:burdaa_vibe_v1/presentation/today/pages/unrecorded_sessions_page.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:burdaa_vibe_v1/core/util/notification_service.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> with WidgetsBindingObserver {
  bool _permissionsGranted = true;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
    _subscription = NotificationService().responseStream.listen((event) {
      if (event == 'attendance_update' && mounted) {
        context.read<AttendanceBloc>().add(LoadAttendance());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
      // Reload attendance when app comes to foreground to reflect any changes from notifications
      context.read<AttendanceBloc>().add(LoadAttendance());
    }
  }

  Future<void> _checkPermissions() async {
    final granted = await NotificationService().arePermissionsGranted();
    if (mounted && granted != _permissionsGranted) {
      setState(() {
        _permissionsGranted = granted;
      });
    }
  }

  int _calculateUnrecordedSessionsCount(
    List<CourseModel> courses,
    List<AttendanceRecord> records,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int count = 0;

    for (var course in courses) {
      final startDate = DateTime(
        course.startDate.year,
        course.startDate.month,
        course.startDate.day,
      );
      final endDate = DateTime(
        course.endDate.year,
        course.endDate.month,
        course.endDate.day,
      );

      final checkUntil = today.subtract(const Duration(days: 1));
      final actualCheckUntil = checkUntil.isBefore(endDate)
          ? checkUntil
          : endDate;

      DateTime tempDate = startDate;
      while (!tempDate.isAfter(actualCheckUntil)) {
        if (tempDate.weekday == course.dayOfWeek) {
          bool exists = records.any(
            (r) =>
                r.courseId == course.id &&
                r.date.year == tempDate.year &&
                r.date.month == tempDate.month &&
                r.date.day == tempDate.day,
          );
          if (!exists) {
            count++;
          }
        }
        tempDate = tempDate.add(const Duration(days: 1));
      }
    }
    return count;
  }

  CourseStats _calculateCourseStats(
    CourseModel course,
    List<AttendanceRecord> records,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int attended = 0;
    int missed = 0;
    int notEntered = 0;

    final startDate = DateTime(
      course.startDate.year,
      course.startDate.month,
      course.startDate.day,
    );
    final endDate = DateTime(
      course.endDate.year,
      course.endDate.month,
      course.endDate.day,
    );

    final checkUntil = today;
    final actualCheckUntil = checkUntil.isBefore(endDate)
        ? checkUntil
        : endDate;

    DateTime tempDate = startDate;
    while (!tempDate.isAfter(actualCheckUntil)) {
      if (tempDate.weekday == course.dayOfWeek) {
        final recordIndex = records.indexWhere(
          (r) =>
              r.courseId == course.id &&
              r.date.year == tempDate.year &&
              r.date.month == tempDate.month &&
              r.date.day == tempDate.day,
        );

        if (recordIndex != -1) {
          final record = records[recordIndex];
          if (record.status == AttendanceStatus.attended) {
            attended++;
          } else if (record.status == AttendanceStatus.missed) {
            missed++;
          }
        } else {
          notEntered++;
        }
      }
      tempDate = tempDate.add(const Duration(days: 1));
    }
    return CourseStats(
      attended: attended,
      missed: missed,
      notEntered: notEntered,
    );
  }

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
                if (!_permissionsGranted) ...[
                  const SizedBox(height: 24),
                  _PermissionAlert(onTap: _checkPermissions),
                ],
                const SizedBox(height: 32),
                Expanded(
                  child: BlocBuilder<CoursesBloc, CoursesState>(
                    builder: (context, coursesState) {
                      return BlocBuilder<AttendanceBloc, AttendanceState>(
                        builder: (context, attendanceState) {
                          final int unrecordedCount =
                              _calculateUnrecordedSessionsCount(
                                coursesState.courses,
                                attendanceState.records,
                              );

                          final todayCourses =
                              coursesState.courses
                                  .where((c) => c.dayOfWeek == todayWeekday)
                                  .toList()
                                ..sort(
                                  (a, b) => a.startTime.compareTo(b.startTime),
                                );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (unrecordedCount > 0) ...[
                                _UnrecordedSessionsAlert(
                                  count: unrecordedCount,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const UnrecordedSessionsPage(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                              ],
                              Expanded(
                                child: todayCourses.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.calendar_today_rounded,
                                              size: 100,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.2),
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
                                      )
                                    : ListView.builder(
                                        itemCount: todayCourses.length,
                                        itemBuilder: (context, index) {
                                          final course = todayCourses[index];
                                          final record = attendanceState.records
                                              .firstWhere(
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
                                            stats: _calculateCourseStats(
                                              course,
                                              attendanceState.records,
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
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

class CourseStats {
  final int attended;
  final int missed;
  final int notEntered;

  const CourseStats({
    required this.attended,
    required this.missed,
    required this.notEntered,
  });
}

class _TodayCourseCard extends StatelessWidget {
  final CourseModel course;
  final AttendanceRecord record;
  final CourseStats stats;

  const _TodayCourseCard({
    required this.course,
    required this.record,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    bool isAttended = record.status == AttendanceStatus.attended;
    bool isMissed = record.status == AttendanceStatus.missed;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailPage(course: course),
          ),
        );
      },
      child: Container(
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
              Row(
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${course.startTime} - ${course.endTime}',
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: stats.missed == 0
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.redAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    stats.missed == 0
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    size: 10,
                                    color: stats.missed == 0
                                        ? Colors.green
                                        : Colors.redAccent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${stats.missed} Devamsızlık',
                                    style: GoogleFonts.inter(
                                      textStyle: TextStyle(
                                        color: stats.missed == 0
                                            ? Colors.green
                                            : Colors.redAccent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _AttendanceButton(
                      label: 'Katıldım',
                      icon: Icons.check_circle_rounded,
                      color: Colors.green,
                      isSelected: isAttended,
                      onTap: () {
                        if (isAttended) {
                          context.read<AttendanceBloc>().add(
                            DeleteAttendance(
                              courseId: course.id,
                              date: record.date,
                            ),
                          );
                        } else {
                          context.read<AttendanceBloc>().add(
                            MarkAttendance(
                              courseId: course.id,
                              status: AttendanceStatus.attended,
                              date: DateTime.now(),
                            ),
                          );
                        }
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
                        if (isMissed) {
                          context.read<AttendanceBloc>().add(
                            DeleteAttendance(
                              courseId: course.id,
                              date: record.date,
                            ),
                          );
                        } else {
                          context.read<AttendanceBloc>().add(
                            MarkAttendance(
                              courseId: course.id,
                              status: AttendanceStatus.missed,
                              date: DateTime.now(),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionAlert extends StatelessWidget {
  final VoidCallback onTap;

  const _PermissionAlert({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.errorContainer.withOpacity(0.9),
            Theme.of(context).colorScheme.errorContainer.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.error.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_off_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bildirim İzinleri Eksik',
                  style: GoogleFonts.outfit(
                    textStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Derslerini zamanında hatırlatabilmemiz için bildirim ve tam doğrulukta alarm izinlerini vermeniz gerekiyor.',
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onErrorContainer.withOpacity(0.8),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await NotificationService().requestPermissions();
              // Give the system a moment to update status
              await Future.delayed(const Duration(milliseconds: 500));
              onTap();

              if (context.mounted) {
                final stillMissing = !await NotificationService()
                    .arePermissionsGranted();
                if (stillMissing) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'İzinler henüz tam olarak verilmedi. Eğer uyarı çıkmıyorsa ayarlardan manuel açabilirsiniz.',
                      ),
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              elevation: 0,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'İzin Ver',
              style: GoogleFonts.inter(
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
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

class _UnrecordedSessionsAlert extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _UnrecordedSessionsAlert({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$count ders henüz kaydedilmedi',
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.orange[800]),
          ],
        ),
      ),
    );
  }
}
