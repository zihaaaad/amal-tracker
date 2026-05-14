import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/tracker/data/models/amal_task.dart';
import '../../features/tracker/data/services/task_service.dart';
import '../constants/app_constants.dart';
import '../database/database_service.dart';

/// Big-Tech Architecture: Task-Driven Background Notifications.
/// Notifications are now derived from data rather than hardcoded logic.

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      final notificationsPlugin = FlutterLocalNotificationsPlugin();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await notificationsPlugin.initialize(initSettings);

      final db = await DatabaseService.initialize();
      final now = DateTime.now();
      final todayLog = db.getTodayLog();
      final tasks = await TaskService.instance.getCachedTasks();

      // ── Strategic Shift: Metadata-Driven Notifications ────────────────
      for (final task in tasks) {
        // If it's a scheduled task (Weekly/Monthly) and active today
        if (task.frequency != TaskFrequency.daily && _isTaskDueToday(task, now)) {
          final isDone = task.inputType == TaskInputType.checkbox 
              ? todayLog.getBool(task.id) 
              : todayLog.getCounter(task.id) >= 5;

          if (!isDone) {
            await _showNotification(
              notificationsPlugin,
              id: task.id.hashCode,
              title: 'Don\'t miss: ${task.title}',
              body: task.subtitle ?? 'Keep up your ${task.category} goals!',
            );
          }
        }
      }

      // ── Intelligent Streak Guard (Only 9 PM) ────────────────────────
      if (now.hour == 21) {
        final streak = db.calculateStreak(tasks);
        if (streak >= 3 && todayLog.calculateCompletion(tasks) < 0.5) {
          await _showNotification(
            notificationsPlugin,
            id: 999,
            title: 'Keep the fire burning! 🔥',
            body: 'You are on a $streak-day streak. Complete your tasks to keep it alive!',
          );
        }
      }
    } catch (e) {
      // Background fails should never crash the host process
    }
    return Future.value(true);
  });
}

bool _isTaskDueToday(AmalTask task, DateTime now) {
  if (task.activeDays != null && !task.activeDays!.contains(now.weekday)) return false;
  if (task.frequency == TaskFrequency.monthly && now.day != 1) return false;
  return true;
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
      importance: Importance.high,
      priority: Priority.high,
    ),
  );
  await plugin.show(id, title, body, details);
}

class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      AppConstants.periodicTaskName,
      AppConstants.backgroundTaskName,
      frequency: const Duration(hours: 1),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }
}
