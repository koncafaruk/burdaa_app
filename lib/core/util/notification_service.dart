import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:isolate';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/widgets.dart'; // For WidgetsFlutterBinding

import 'package:permission_handler/permission_handler.dart';
import '../../data/courses/models/course_model.dart';
import '../database/database_helper.dart';

@pragma('vm:entry-point')
void notificationTapBackground(
  NotificationResponse notificationResponse,
) async {
  await handleNotificationAction(notificationResponse);
}

Future<void> handleNotificationAction(
  NotificationResponse notificationResponse,
) async {
  // Ensure binding is initialized for platform channels (database, path_provider)
  WidgetsFlutterBinding.ensureInitialized();

  // ignore: avoid_print
  print(
    'notification(${notificationResponse.id}) action tapped: '
    '${notificationResponse.actionId} with'
    ' payload: ${notificationResponse.payload}',
  );

  if (notificationResponse.actionId == NotificationService.actionIdYes ||
      notificationResponse.actionId == NotificationService.actionIdNo) {
    final payload = notificationResponse.payload;
    if (payload != null) {
      try {
        final status =
            notificationResponse.actionId == NotificationService.actionIdYes
            ? 0 // AttendanceStatus.attended
            : 1; // AttendanceStatus.missed

        await DatabaseHelper.markAttendance(payload, status);
        print('Attendance marked: $status for course $payload');

        // Try sending an event to the main isolate using IsolateNameServer
        final SendPort? sendPort = IsolateNameServer.lookupPortByName(
          'notification_updates_port',
        );
        if (sendPort != null) {
          sendPort.send('attendance_update');
        } else {
          // Fallback if we are already in the main isolate
          NotificationService().notifyAttendanceUpdate();
        }
      } catch (e) {
        print('Error marking attendance: $e');
      }
    }
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final _responseController = StreamController<String>.broadcast();
  Stream<String> get responseStream => _responseController.stream;
  String lastResponse = 'Henüz bir tuşa basılmadı';

  static const String actionIdYes = 'action_yes';
  static const String actionIdNo = 'action_no';

  ReceivePort? _receivePort;

  Future<void> init() async {
    // Register port for background isolate communication
    _receivePort = ReceivePort();
    IsolateNameServer.removePortNameMapping('notification_updates_port');
    IsolateNameServer.registerPortWithName(
      _receivePort!.sendPort,
      'notification_updates_port',
    );

    _receivePort!.listen((message) {
      if (message == 'attendance_update') {
        notifyAttendanceUpdate();
      }
    });
    // Initialize timezone
    tz.initializeTimeZones();
    final String timeZoneName =
        (await FlutterTimezone.getLocalTimezone()).identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Initialize Android settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize iOS settings (optional but good to have)
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(
              'actionable_notification',
              actions: [
                DarwinNotificationAction.plain(
                  actionIdYes,
                  'Evet',
                  options: {DarwinNotificationActionOption.foreground},
                ),
                DarwinNotificationAction.plain(
                  actionIdNo,
                  'Hayır',
                  options: {DarwinNotificationActionOption.foreground},
                ),
              ],
            ),
          ],
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle foreground/interactive response using the same logic
        handleNotificationAction(response);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Check if the app was launched by a notification
    final NotificationAppLaunchDetails? launchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      if (launchDetails.notificationResponse != null) {
        handleNotificationAction(launchDetails.notificationResponse!);
      }
    }
  }

  void notifyAttendanceUpdate() {
    _responseController.add('attendance_update');
  }

  Future<void> scheduleCourseNotification(CourseModel course) async {
    // ID needs to be unique. We can hash the course ID or use int.tryParse if ID is numeric.
    // Since course.id is String (UUID likely), we need a way to generate a stable int ID.
    // Using hashCode is a simple way, though collisions are theoretically possible but rare enough for this.
    final notificationId = course.id.hashCode;

    // Calculate the next occurrence
    // frequency 31 is weekly.
    // dayOfWeek: 1 = Monday, 7 = Sunday (iso8601)

    // Parse time
    final parts = course.startTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    // Construct the DateTime components for the weekly schedule
    // LocalNotification's Day object is different from DateTime's weekday
    // DateTime: 1=Mon, 7=Sun
    // LocalNotification Day: 1=Mon, 7=Sun (matches ISO)

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'Ders Vakti: ${course.title}',
      ' derse katıldın mı?',
      _nextInstanceOfDayAndTime(course.dayOfWeek, hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel_id',
          'Daily Notifications',
          channelDescription: 'Daily scheduled notifications',
          importance: Importance.max,
          priority: Priority.high,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              actionIdYes,
              'Evet',
              showsUserInterface:
                  false, // Don't open app if possible, but for actions we might need to?
              // Actually for 'showsUserInterface: false' it works in background if we handle it in onDidReceiveBackgroundNotificationResponse
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              actionIdNo,
              'Hayır',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'actionable_notification',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: course.id,
    );

    print(
      'Scheduled notification for ${course.title} (ID: $notificationId) at Day ${course.dayOfWeek} $hour:$minute',
    );
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Ensure we are scheduling for the correct day of week
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // If the scheduled date is in the past, move it to next week
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  Future<void> cancelCourseNotification(String courseId) async {
    await flutterLocalNotificationsPlugin.cancel(courseId.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // Kept for reference but not used for courses directly
  Future<void> showScheduledNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel_id',
          'Daily Notifications',
          channelDescription: 'Daily scheduled notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> requestPermissions() async {
    try {
      // Notification permission is basic
      final notificationStatus = await Permission.notification.request();

      // Exact alarm is Android 12+ specific
      if (Platform.isAndroid) {
        final alarmStatus = await Permission.scheduleExactAlarm.request();

        // If either is permanently denied, open settings
        if (notificationStatus.isPermanentlyDenied ||
            alarmStatus.isPermanentlyDenied) {
          await openAppSettings();
        }
      } else {
        if (notificationStatus.isPermanentlyDenied) {
          await openAppSettings();
        }
      }
    } catch (e) {
      print('Permission request error: $e');
    }
  }

  Future<bool> hasNotificationPermission() async {
    return await Permission.notification.isGranted;
  }

  Future<bool> hasExactAlarmPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }
    return await Permission.scheduleExactAlarm.isGranted;
  }

  Future<bool> arePermissionsGranted() async {
    final hasNotification = await hasNotificationPermission();
    final hasExactAlarm = await hasExactAlarmPermission();
    return hasNotification && hasExactAlarm;
  }
}
