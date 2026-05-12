 import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../constants/app_constants.dart';

/// Service for managing local notifications.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    // Create notification channel
    const channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDesc,
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Initial schedule of daily reminders
    await scheduleDailyReminders();
  }

  /// Schedule fixed daily reminders (Fajr, Sleep, etc.) for the next 7 days.
  /// Uses Exact Alarms to bypass Doze Mode.
  static Future<void> scheduleDailyReminders() async {
    // 1. Morning Motivation (Fajr)
    await _scheduleDaily(
      id: 101,
      title: 'Bismillah! 🌅',
      body: 'Start your day with Fajr. A new day of blessings awaits.',
      hour: AppConstants.morningMotivationHour,
      minute: 30,
    );

    // 2. Evening Check
    await _scheduleDaily(
      id: 102,
      title: 'Amal Tracker 📋',
      body: 'Don\'t forget to check your progress before the day ends.',
      hour: AppConstants.eveningCheckHour,
      minute: 0,
    );

    // 3. Sleep Reminder
    await _scheduleDaily(
      id: 103,
      title: 'Time to wind down 🌙',
      body: 'Prepare for early sleep to catch Fajr. Sunnah sleep time.',
      hour: AppConstants.sleepReminderHour,
      minute: AppConstants.sleepReminderMinute,
    );
  }

  static Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
      ),
    );
    await _plugin.show(id, title, body, details);
  }

  /// Get the plugin instance for background isolate usage.
  static FlutterLocalNotificationsPlugin get plugin => _plugin;
}
