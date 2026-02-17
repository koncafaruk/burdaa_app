import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:burdaa_vibe_v1/data/courses/models/course_model.dart';
import 'package:burdaa_vibe_v1/presentation/today/bloc/attendance_bloc.dart';
import 'package:burdaa_vibe_v1/data/today/models/attendance_record.dart';

enum AttendanceFilter { all, attended, missed, unrecorded }

class CourseDetailPage extends StatefulWidget {
  final CourseModel course;

  const CourseDetailPage({super.key, required this.course});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  AttendanceFilter _selectedFilter = AttendanceFilter.all;
  bool _isAscending = false;

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

  List<DateTime> _getUnrecordedDates(List<AttendanceRecord> records) {
    final startDate = widget.course.startDate;
    final endDate = widget.course.endDate;
    final now = DateTime.now();

    // We only care about unrecorded dates until today or endDate (whichever is earlier)
    final checkUntil = now.isBefore(endDate) ? now : endDate;

    List<DateTime> unrecorded = [];
    DateTime tempDate = startDate;

    while (!tempDate.isAfter(checkUntil)) {
      if (tempDate.weekday == widget.course.dayOfWeek) {
        // Check if any record exists for this date
        bool exists = records.any(
          (r) =>
              r.date.year == tempDate.year &&
              r.date.month == tempDate.month &&
              r.date.day == tempDate.day,
        );
        if (!exists) {
          unrecorded.add(tempDate);
        }
      }
      tempDate = tempDate.add(const Duration(days: 1));
    }
    return unrecorded;
  }

  int _getTotalLessons() {
    int count = 0;
    DateTime tempDate = widget.course.startDate;
    while (!tempDate.isAfter(widget.course.endDate)) {
      if (tempDate.weekday == widget.course.dayOfWeek) {
        count++;
      }
      tempDate = tempDate.add(const Duration(days: 1));
    }
    return count;
  }

  String _formatSmallDate(DateTime date) {
    return "${date.day} ${_getMonthName(date.month)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.course.title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          final courseRecords =
              state.records
                  .where((r) => r.courseId == widget.course.id)
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));

          final attendedCount = courseRecords
              .where((r) => r.status == AttendanceStatus.attended)
              .length;
          final missedCount = courseRecords
              .where((r) => r.status == AttendanceStatus.missed)
              .length;

          final unrecordedDates = _getUnrecordedDates(courseRecords);
          final unrecordedCount = unrecordedDates.length;

          // Filtreleme mantığı
          List<dynamic> displayedItems = [];
          if (_selectedFilter == AttendanceFilter.all) {
            displayedItems = [...courseRecords, ...unrecordedDates];
          } else if (_selectedFilter == AttendanceFilter.attended) {
            displayedItems = courseRecords
                .where((r) => r.status == AttendanceStatus.attended)
                .toList();
          } else if (_selectedFilter == AttendanceFilter.missed) {
            displayedItems = courseRecords
                .where((r) => r.status == AttendanceStatus.missed)
                .toList();
          } else if (_selectedFilter == AttendanceFilter.unrecorded) {
            displayedItems = unrecordedDates;
          }

          // Sıralama mantığı
          displayedItems.sort((a, b) {
            final dateA = (a is AttendanceRecord) ? a.date : a as DateTime;
            final dateB = (b is AttendanceRecord) ? b.date : b as DateTime;
            return _isAscending
                ? dateA.compareTo(dateB)
                : dateB.compareTo(dateA);
          });

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(context),
                  const SizedBox(height: 32),
                  _buildSummarySection(
                    context,
                    attendedCount,
                    missedCount,
                    unrecordedCount,
                    _getTotalLessons(),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Text(
                        'Devamsızlık Geçmişi',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () =>
                            setState(() => _isAscending = !_isAscending),
                        icon: Icon(
                          _isAscending
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 20,
                        ),
                        tooltip: _isAscending
                            ? 'Eskiden Yeniye'
                            : 'Yeniden Eskiye',
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.05),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (displayedItems.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'Görüntülenecek kayıt bulunmuyor.',
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayedItems.length,
                      itemBuilder: (context, index) {
                        final item = displayedItems[index];
                        // ignore: unused_local_variable
                        final DateTime itemDate = (item is AttendanceRecord)
                            ? item.date
                            : item as DateTime;

                        // We use a simplified key for uniqueness in this list
                        // Using ISO string helps uniqueness
                        final String dateKey = itemDate.toIso8601String();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: Key(dateKey),
                            confirmDismiss: (direction) async {
                              final status =
                                  direction == DismissDirection.startToEnd
                                  ? AttendanceStatus.attended
                                  : AttendanceStatus.missed;

                              // Find date
                              final date = (item is AttendanceRecord)
                                  ? item.date
                                  : item as DateTime;

                              context.read<AttendanceBloc>().add(
                                MarkAttendance(
                                  courseId: widget.course.id,
                                  status: status,
                                  date: date,
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
                            child: item is AttendanceRecord
                                ? _buildRecordTile(context, item)
                                : _buildUnrecordedTile(
                                    context,
                                    item as DateTime,
                                  ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
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

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.school_rounded, color: Colors.white, size: 32),
          const SizedBox(height: 16),
          Text(
            widget.course.title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _getDayName(widget.course.dayOfWeek),
                style: GoogleFonts.inter(color: Colors.white70),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.access_time_rounded,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.course.startTime} - ${widget.course.endTime}',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.date_range_rounded,
                color: Colors.white54,
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                '${_formatSmallDate(widget.course.startDate)} - ${_formatSmallDate(widget.course.endDate)}',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(
    BuildContext context,
    int attended,
    int missed,
    int unrecorded,
    int total,
  ) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Toplam Ders Sayısı',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                total.toString(),
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                'Katılmadım',
                missed.toString(),
                Colors.redAccent,
                Icons.cancel_rounded,
                isSelected: _selectedFilter == AttendanceFilter.missed,
                onTap: () => setState(
                  () => _selectedFilter =
                      _selectedFilter == AttendanceFilter.missed
                      ? AttendanceFilter.all
                      : AttendanceFilter.missed,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                context,
                'Girilmeyen',
                unrecorded.toString(),
                Colors.orange,
                Icons.help_outline_rounded,
                isSelected: _selectedFilter == AttendanceFilter.unrecorded,
                onTap: () => setState(
                  () => _selectedFilter =
                      _selectedFilter == AttendanceFilter.unrecorded
                      ? AttendanceFilter.all
                      : AttendanceFilter.unrecorded,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                context,
                'Katıldım',
                attended.toString(),
                Colors.green,
                Icons.check_circle_rounded,
                isSelected: _selectedFilter == AttendanceFilter.attended,
                onTap: () => setState(
                  () => _selectedFilter =
                      _selectedFilter == AttendanceFilter.attended
                      ? AttendanceFilter.all
                      : AttendanceFilter.attended,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : color),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white.withOpacity(0.9)
                    : color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordTile(BuildContext context, AttendanceRecord record) {
    final bool isAttended = record.status == AttendanceStatus.attended;
    final color = isAttended ? Colors.green : Colors.redAccent;
    final dateStr =
        "${record.date.day} ${_getMonthName(record.date.month)} ${record.date.year}";

    return Container(
      height: 72, // Fixed height for consistency
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
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
            child: Text(
              dateStr,
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
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
              context.read<AttendanceBloc>().add(
                DeleteAttendance(courseId: record.courseId, date: record.date),
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
    );
  }

  Widget _buildUnrecordedTile(BuildContext context, DateTime date) {
    final dateStr = "${date.day} ${_getMonthName(date.month)} ${date.year}";

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.help_outline_rounded,
              color: Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              dateStr,
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            'Girilmedi',
            style: GoogleFonts.inter(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
        ],
      ),
    );
  }
}
