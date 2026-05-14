import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_service.dart';
import 'tasks_provider.dart';

/// Time-of-day context for showing/hiding relevant items.
enum TimeContext {
  earlyMorning, // Before 7 AM  — Fajr, Ishraq, Morning Azkar
  morning,      // 7-12         — Morning items + habits
  afternoon,    // 12-3 PM      — + Dhuhr, Asr
  evening,      // 3-6 PM       — + Asr, Maghrib prep
  night,        // 6-9 PM       — Full view, Maghrib, Isha, Evening Azkar
  lateNight,    // 9 PM+        — Full view + sleep reminder
}

/// Provider for the database service singleton.
final databaseProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

/// Provider for today's daily log with reactive state and auto-sync.
final dailyLogProvider =
    StateNotifierProvider<DailyLogNotifier, DailyLog>((ref) {
  final db = ref.watch(databaseProvider);
  return DailyLogNotifier(db, ref);
});

/// Provider for the current streak count.
final streakProvider = Provider<int>((ref) {
  ref.watch(dailyLogProvider);
  final tasks = ref.watch(tasksProvider).value ?? [];
  return DatabaseService.instance.calculateStreak(tasks);
});

/// Provider for time-based context filtering.
/// Uses a regular Provider so it always reads the current time.
final timeContextProvider = Provider<TimeContext>((ref) {
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
  ref.watch(dailyLogProvider);
  return DatabaseService.instance.getCurrentMonthLogs();
});

/// Notifier for the daily log state with Auto-Sync capability.
class DailyLogNotifier extends StateNotifier<DailyLog> {
  final DatabaseService _db;
  Timer? _debounceTimer;

  DailyLogNotifier(this._db) : super(_db.getTodayLog());

  /// Toggle a boolean task with auto-sync.
  Future<void> toggleTask(String taskId) async {
    final currentValues = Map<String, dynamic>.from(state.values);
    currentValues[taskId] = !(currentValues[taskId] == true);
    state = state.copyWith(values: currentValues);
    await _db.saveLog(state);
    _triggerAutoSync();
  }

  /// Update a counter with auto-sync.
  Future<void> updateCounter(String taskId, int value) async {
    final currentValues = Map<String, dynamic>.from(state.values);
    currentValues[taskId] = value;
    state = state.copyWith(values: currentValues);
    await _db.saveLog(state);
    _triggerAutoSync();
  }

  /// Debounced sync to Supabase to prevent spamming the network.
  void _triggerAutoSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () async {
      try {
        await _db.syncToCloud();
      } catch (e) {
        // Silently handle sync errors (e.g., offline)
      }
    });
  }

  /// Restore history from cloud (called after login).
  Future<void> restoreFromCloud() async {
    try {
      await _db.restoreFromCloud();
      refreshToday();
    } catch (_) {}
  }

  /// Load a specific date's log.
  void loadDate(DateTime date) {
    state = _db.getLog(date);
  }

  /// Reload today's data.
  void refreshToday() {
    state = _db.getTodayLog();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
