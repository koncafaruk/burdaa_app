import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:burdaa_vibe_v1/data/courses/models/course_model.dart';
import 'package:burdaa_vibe_v1/presentation/courses/bloc/courses_bloc.dart';
import 'package:burdaa_vibe_v1/presentation/today/bloc/attendance_bloc.dart';
import 'package:burdaa_vibe_v1/data/today/models/attendance_record.dart';

class _UnrecordedSessionData {
  final CourseModel course;
  final DateTime date;

  _UnrecordedSessionData(this.course, this.date);

  String get id => '${course.id}_${date.toIso8601String()}';
}

class UnrecordedSessionsPage extends StatefulWidget {
  const UnrecordedSessionsPage({super.key});

  @override
  State<UnrecordedSessionsPage> createState() => _UnrecordedSessionsPageState();
}

class _UnrecordedSessionsPageState extends State<UnrecordedSessionsPage> {
  final List<_UnrecordedSessionData> _recentlyRecorded = [];
  final Map<String, AttendanceStatus> _recordedStatuses = {};
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _checkTutorialStatus();
  }

  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_unrecorded_tutorial') ?? false;
    if (!hasSeen && mounted) {
      setState(() {
        _showTutorial = true;
      });
    }
  }

  void _dismissTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_unrecorded_tutorial', true);
    if (mounted) {
      setState(() {
        _showTutorial = false;
      });
    }
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return months[month];
  }

  String _getDayName(int day) {
    const days = [
      '',
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    return days[day];
  }

  List<_UnrecordedSessionData> _getUnrecordedSessions(
    List<CourseModel> courses,
    List<AttendanceRecord> records,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    List<_UnrecordedSessionData> unrecorded = [];

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
            final item = _UnrecordedSessionData(course, tempDate);
            // Sadece recently recorded listesinde OLMAYANLARI ekle
            if (!_recentlyRecorded.any((e) => e.id == item.id)) {
              unrecorded.add(item);
            }
          }
        }
        tempDate = tempDate.add(const Duration(days: 1));
      }
    }
    unrecorded.sort((a, b) => b.date.compareTo(a.date));
    return unrecorded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kaydedilmemiş Dersler',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<CoursesBloc, CoursesState>(
        builder: (context, coursesState) {
          return BlocBuilder<AttendanceBloc, AttendanceState>(
            builder: (context, attendanceState) {
              final rawUnrecorded = _getUnrecordedSessions(
                coursesState.courses,
                attendanceState.records,
              );

              final List<Widget> listItems = [];

              if (_showTutorial) {
                listItems.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildTutorialCard(),
                  ),
                );
              }

              if (rawUnrecorded.isNotEmpty) {
                Map<DateTime, List<_UnrecordedSessionData>> grouped = {};
                for (var item in rawUnrecorded) {
                  final d = DateTime(
                    item.date.year,
                    item.date.month,
                    item.date.day,
                  );
                  grouped.putIfAbsent(d, () => []).add(item);
                }

                final sortedDates = grouped.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                for (var date in sortedDates) {
                  listItems.add(
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 12),
                      child: Text(
                        '${date.day} ${_getMonthName(date.month)} ${date.year} ${_getDayName(date.weekday)}',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  );

                  final items = grouped[date]!;
                  items.sort(
                    (a, b) => a.course.startTime.compareTo(b.course.startTime),
                  );

                  for (var item in items) {
                    listItems.add(
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: Key(item.id),
                          confirmDismiss: (direction) async {
                            final status =
                                direction == DismissDirection.startToEnd
                                ? AttendanceStatus.attended
                                : AttendanceStatus.missed;

                            setState(() {
                              if (!_recentlyRecorded.any(
                                (e) => e.id == item.id,
                              )) {
                                _recentlyRecorded.add(item);
                              }
                              _recordedStatuses[item.id] = status;
                            });

                            context.read<AttendanceBloc>().add(
                              MarkAttendance(
                                courseId: item.course.id,
                                status: status,
                                date: item.date,
                              ),
                            );
                            return false;
                          },
                          background: _buildSwipeBackground(
                            Alignment.centerLeft,
                            Colors.green,
                            Icons.check_circle_rounded,
                            'Katıldım',
                          ),
                          secondaryBackground: _buildSwipeBackground(
                            Alignment.centerRight,
                            Colors.redAccent,
                            Icons.cancel_rounded,
                            'Katılmadım',
                          ),
                          child: _buildUnrecordedTile(context, item),
                        ),
                      ),
                    );
                  }
                }
              }

              if (_recentlyRecorded.isNotEmpty) {
                final sortedRecentlyRecorded =
                    List<_UnrecordedSessionData>.from(_recentlyRecorded)
                      ..sort((a, b) {
                        final dateCompare = b.date.compareTo(a.date);
                        if (dateCompare != 0) return dateCompare;
                        return b.course.startTime.compareTo(a.course.startTime);
                      });

                listItems.add(
                  Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 12),
                    child: Text(
                      'Kaydedilenler',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                );

                for (var item in sortedRecentlyRecorded) {
                  listItems.add(
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRecentlyRecordedTile(
                        context,
                        item,
                        _recordedStatuses[item.id]!,
                      ),
                    ),
                  );
                }
              }

              return ListView.builder(
                padding: const EdgeInsets.all(24.0),
                itemCount: listItems.length,
                itemBuilder: (context, index) {
                  return listItems[index];
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSwipeBackground(
    Alignment alignment,
    Color color,
    IconData icon,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerLeft) ...[
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if (alignment == Alignment.centerRight) ...[
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white),
          ],
        ],
      ),
    );
  }

  Widget _buildUnrecordedTile(
    BuildContext context,
    _UnrecordedSessionData item,
  ) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              color: Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.course.title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.course.startTime} - ${item.course.endTime}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'Girilmedi',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyRecordedTile(
    BuildContext context,
    _UnrecordedSessionData item,
    AttendanceStatus status,
  ) {
    final bool isAttended = status == AttendanceStatus.attended;
    final color = isAttended ? Colors.green : Colors.redAccent;
    final dateStr =
        "${item.date.day} ${_getMonthName(item.date.month)} ${item.date.year} ${_getDayName(item.date.weekday)}";

    return Opacity(
      opacity: 0.5,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAttended ? Icons.check_rounded : Icons.close_rounded,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.course.title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    dateStr,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              isAttended ? 'Katıldım' : 'Katılmadım',
              style: GoogleFonts.inter(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () {
                setState(() {
                  _recentlyRecorded.removeWhere((e) => e.id == item.id);
                  _recordedStatuses.remove(item.id);
                });
                context.read<AttendanceBloc>().add(
                  DeleteAttendance(courseId: item.course.id, date: item.date),
                );
              },
              icon: Icon(
                Icons.restart_alt_rounded,
                size: 24,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ),
              tooltip: 'Kaydı Sıfırla',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.swipe_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nasıl Kayıt Alınır?',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.close_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: _dismissTutorial,
                tooltip: 'Anladım',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Dersleri kaydetmek için kaydı:\n\n'
            '👉 Sağa kaydırarak: Katıldım\n'
            '👈 Sola kaydırarak: Katılmadım\n\n'
            'olarak işaretleyebilirsiniz.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _dismissTutorial,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Anladım',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
