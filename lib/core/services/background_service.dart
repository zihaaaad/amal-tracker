import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_constants.dart';
import '../database/database_service.dart';

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

      // ── Rule 1: Morning Motivation (5:30 AM) ──────
      if (now.hour == AppConstants.morningMotivationHour &&
          now.minute <= 30) {
        await _showNotification(
          notificationsPlugin,
          id: 1,
          title: 'Bismillah! 🌅',
          body: 'Start your day with Fajr. A new day of blessings awaits.',
        );
      }

      // ── Rule 2: Evening Incomplete Alert (8 PM) ───
      if (now.hour == AppConstants.eveningCheckHour) {
        final pct = todayLog.completionPercentage;
        if (pct < 0.5) {
          final streak = db.calculateStreak();
          final streakMsg = streak > 0
              ? 'You have a $streak-day streak! Don\'t break it.'
              : 'Start building your streak today.';
          await _showNotification(
            notificationsPlugin,
            id: 2,
            title: 'Amal Reminder 📋',
            body:
                'You\'ve completed ${(pct * 100).round()}% today. $streakMsg',
          );
        }
      }

      // ── Rule 3: Sleep Reminder (10:00 PM) ─────────
      if (now.hour == AppConstants.sleepReminderHour &&
          now.minute <= AppConstants.sleepReminderMinute + 15) {
        if (!todayLog.sleptBefore1030) {
          await _showNotification(
            notificationsPlugin,
            id: 3,
            title: 'Time to wind down 🌙',
            body:
                'Sleep before 10:30 PM for the Sunnah. Put your devices away.',
          );
        }
      }

      // ── Rule 4: Friday Reminder (12 PM Friday) ────
      if (now.weekday == DateTime.friday && now.hour == 12) {
        if (!todayLog.surahKahf) {
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
        final streak = db.calculateStreak();
        if (streak >= 3 && todayLog.completionPercentage >= 0.5) {
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
