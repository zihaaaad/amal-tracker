import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

/// Data-focused analytics aggregation for the UI.
class AnalyticsData {
  final int streak;
  final int daysTracked;
  final double avgCompletion;
  final double weeklyTrend;
  final List<DailyLog> pastLogs;

  AnalyticsData({
    required this.streak,
    required this.daysTracked,
    required this.avgCompletion,
    required this.weeklyTrend,
    required this.pastLogs,
  });
}

/// Reactive provider for aggregated analytics data.
/// Performs all heavy calculations in a single place.
final analyticsDataProvider = Provider<AnalyticsData>((ref) {
  final monthLogs = ref.watch(monthLogsProvider);
  final streak = ref.watch(streakProvider);
  final tasks = ref.watch(tasksProvider).value ?? [];
  final now = DateTime.now();

  // 1. Filter past logs for today and before
  final pastLogs = monthLogs.where((l) {
    try {
      final day = DateTime.parse(l.date).day;
      return day <= now.day;
    } catch (_) {
      return false;
    }
  }).toList();

  // 2. Average Completion
  final avgCompletion = pastLogs.isEmpty
      ? 0.0
      : pastLogs.fold(0.0, (s, l) => s + l.calculateCompletion(tasks)) /
          pastLogs.length;

  // 3. Days Tracked
  final daysTracked = pastLogs.where((l) => l.calculateCompletion(tasks) > 0).length;

  // 4. Weekly Trend Calculation
  final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
  double thisWeekTotal = 0;
  int thisWeekDays = 0;
  for (int i = 0; i <= now.weekday - 1; i++) {
    final dateStr = DateFormat('yyyy-MM-dd').format(thisWeekStart.add(Duration(days: i)));
    final log = monthLogs.firstWhere((l) => l.date == dateStr, orElse: () => DailyLog(date: dateStr));
    final comp = log.calculateCompletion(tasks);
    if (comp > 0) { thisWeekTotal += comp; thisWeekDays++; }
  }
  final thisWeekAvg = thisWeekDays > 0 ? thisWeekTotal / thisWeekDays : 0.0;

  final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
  double lastWeekTotal = 0;
  int lastWeekDays = 0;
  for (int i = 0; i < 7; i++) {
    // Note: DatabaseService.getLog is Sync and cached in Isar, but for consistency we use monthLogs if available
    final log = DatabaseService.instance.getLog(lastWeekStart.add(Duration(days: i)));
    final comp = log.calculateCompletion(tasks);
    if (comp > 0) { lastWeekTotal += comp; lastWeekDays++; }
  }
  final lastWeekAvg = lastWeekDays > 0 ? lastWeekTotal / lastWeekDays : 0.0;
  final trend = thisWeekAvg - lastWeekAvg;

  return AnalyticsData(
    streak: streak,
    daysTracked: daysTracked,
    avgCompletion: avgCompletion,
    weeklyTrend: trend,
    pastLogs: pastLogs,
  );
});

enum SyncStatus { idle, syncing, success, error, offline }

final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.idle);

/// Notifier for the daily log state with Auto-Sync capability.
class DailyLogNotifier extends StateNotifier<DailyLog> {
  final DatabaseService _db;
  final Ref _ref;
  Timer? _debounceTimer;

  DailyLogNotifier(this._db, this._ref) : super(_db.getTodayLog());

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

  /// Debounced sync to Supabase with status tracking.
  void _triggerAutoSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () async {
      _ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;
      try {
        final result = await _db.syncToCloud();
        if (result.isSuccess) {
          _ref.read(syncStatusProvider.notifier).state = SyncStatus.success;
          Future.delayed(const Duration(seconds: 2), () {
            if (_ref.read(syncStatusProvider.notifier).state == SyncStatus.success) {
              _ref.read(syncStatusProvider.notifier).state = SyncStatus.idle;
            }
          });
        } else {
          _ref.read(syncStatusProvider.notifier).state = 
              result.isUnauthorized ? SyncStatus.offline : SyncStatus.error;
        }
      } catch (e) {
        _ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
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
