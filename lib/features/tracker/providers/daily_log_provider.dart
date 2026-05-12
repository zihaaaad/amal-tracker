import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_service.dart';
import 'tasks_provider.dart';

/// Provider for the database service singleton.
final databaseProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

/// Provider for today's daily log with reactive state.
final dailyLogProvider =
    StateNotifierProvider<DailyLogNotifier, DailyLog>((ref) {
  final db = ref.watch(databaseProvider);
  return DailyLogNotifier(db);
});

/// Provider for the current streak count.
final streakProvider = Provider<int>((ref) {
  // Re-read when dailyLog or tasks change
  ref.watch(dailyLogProvider);
  final tasks = ref.watch(tasksProvider).value ?? [];
  return DatabaseService.instance.calculateStreak(tasks);
});

/// Provider for time-based context filtering.
final timeContextProvider = StateProvider<TimeContext>((ref) {
  final hour = DateTime.now().hour;
  if (hour < 7) return TimeContext.earlyMorning;
  if (hour < 12) return TimeContext.morning;
  if (hour < 15) return TimeContext.afternoon;
  if (hour < 18) return TimeContext.evening;
  if (hour < 21) return TimeContext.night;
  return TimeContext.lateNight;
});

/// Provider for selected date (for viewing past days).
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Provider for month logs (analytics).
final monthLogsProvider = Provider<List<DailyLog>>((ref) {
  ref.watch(dailyLogProvider); // refresh when today changes
  return DatabaseService.instance.getCurrentMonthLogs();
});

/// Time-of-day context for showing/hiding relevant items.
enum TimeContext {
  earlyMorning, // Before 7 AM  — Fajr, Ishraq, Morning Azkar
  morning,      // 7-12         — Morning items + habits
  afternoon,    // 12-3 PM      — + Dhuhr, Asr
  evening,      // 3-6 PM       — + Asr, Maghrib prep
  night,        // 6-9 PM       — Full view, Maghrib, Isha, Evening Azkar
  lateNight,    // 9 PM+        — Full view + sleep reminder
}

/// Determines if an Amal item should be visible based on time context.
bool shouldShowItem(String itemId, TimeContext context) {
  // Always show these items regardless of time
  const alwaysShow = {
    'fiveMinDua', 'removedObstacles', 'physicalHealth',
    'socialMediaLimit', 'miswakEnteringHome', 'twoRakatTravel',
    'durood', 'salahOnTime',
  };
  if (alwaysShow.contains(itemId)) return true;

  switch (context) {
    case TimeContext.earlyMorning:
      return {'fajr', 'ishraq', 'morningAzkar', 'sunnahMuakkadah'}
          .contains(itemId);
    case TimeContext.morning:
      return {'fajr', 'ishraq', 'morningAzkar', 'sunnahMuakkadah', 'dhuhr'}
          .contains(itemId);
    case TimeContext.afternoon:
      return !{'sleptBefore1030', 'eveningAzkar', 'isha'}.contains(itemId);
    case TimeContext.evening:
    case TimeContext.night:
    case TimeContext.lateNight:
      return true; // Show everything in the evening/night
  }
}

/// Notifier for the daily log state.
class DailyLogNotifier extends StateNotifier<DailyLog> {
  final DatabaseService _db;

  DailyLogNotifier(this._db) : super(_db.getTodayLog());

  /// Toggle a boolean task.
  Future<void> toggleTask(String taskId) async {
    final currentValues = Map<String, dynamic>.from(state.values);
    currentValues[taskId] = !(currentValues[taskId] == true);
    state = state.copyWith(values: currentValues);
    await _db.saveLog(state);
  }

  /// Update a counter or number input.
  Future<void> updateCounter(String taskId, int value) async {
    final currentValues = Map<String, dynamic>.from(state.values);
    currentValues[taskId] = value;
    state = state.copyWith(values: currentValues);
    await _db.saveLog(state);
  }

  /// Load a specific date's log.
  void loadDate(DateTime date) {
    state = _db.getLog(date);
  }

  /// Reload today's data.
  void refreshToday() {
    state = _db.getTodayLog();
  }
}
