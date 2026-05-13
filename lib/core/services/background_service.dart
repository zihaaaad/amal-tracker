import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_constants.dart';
import '../database/database_service.dart';
import '../../features/tracker/data/services/task_service.dart';

/// Background service for smart notifications using WorkManager.
/// Runs completely offline — no API calls needed.

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      // Initialize notification plugin in background isolate
      final notificationsPlugin = FlutterLocalNotificationsPlugin();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await notificationsPlugin.initialize(initSettings);

      // Initialize database
      final db = await DatabaseService.initialize();
      final now = DateTime.now();
      final todayLog = db.getTodayLog();

      final tasks = await TaskService.instance.getCachedTasks();

      // ── Rule 4: Friday Reminder (12 PM Friday) ────
      if (now.weekday == DateTime.friday && now.hour == 12) {
        if (!todayLog.getBool('surahKahf')) {
          await _showNotification(
            notificationsPlugin,
            id: 4,
            title: 'Jumu\'ah Mubarak! 🕌',
            body: 'Don\'t forget to recite Surah Al-Kahf today.',
          );
        }
      }

      // ── Rule 5: Streak Alert (9 PM) ───────────────
      if (now.hour == 21) {
        final streak = db.calculateStreak(tasks);
        if (streak >= 3 && todayLog.calculateCompletion(tasks) >= 0.5) {
          await _showNotification(
            notificationsPlugin,
            id: 5,
            title: 'Masha\'Allah! 🔥',
            body:
                'You\'re on a $streak-day streak! Keep up the amazing work.',
          );
        }
      }
    } catch (e) {
      // Silently fail in background — don't crash the app
    }
    return Future.value(true);
  });
}

Future<void> _showNotification(
  FlutterLocalNotificationsPlugin plugin, {
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
    ),
  );
  await plugin.show(id, title, body, details);
}

/// Initialize and register background tasks.
class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);

    // Register periodic task (runs approximately every 1 hour)
    await Workmanager().registerPeriodicTask(
      AppConstants.periodicTaskName,
      AppConstants.backgroundTaskName,
      frequency: const Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }
}
