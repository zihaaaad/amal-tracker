import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_service.dart';

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
  // Re-read when dailyLog changes
  ref.watch(dailyLogProvider);
  return DatabaseService.instance.calculateStreak();
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

  /// Toggle a boolean field.
  Future<void> toggleItem(String id) async {
    state.toggle(id);
    state = state.copyWith();
    await _db.saveLog(state);
  }

  /// Increment a counter field.
  Future<int> incrementCounter(String id, int max) async {
    final newVal = state.increment(id, max);
    state = state.copyWith();
    await _db.saveLog(state);
    return newVal;
  }

  /// Set a counter to a specific value.
  Future<void> setCounter(String id, int value) async {
    state.setCounter(id, value);
    state = state.copyWith();
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
