import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/tracker/data/models/amal_task.dart';

/// Represents a single day's tracking data.
/// All fields map directly to the PDF Amal sheet.
class DailyLog {
  final String date; // yyyy-MM-dd format key
  final Map<String, dynamic> values;

  DailyLog({
    required this.date,
    Map<String, dynamic>? values,
  }) : values = values ?? {};

  /// Returns a value 0.0–1.0 representing daily completion based on weighted points.
  double calculateCompletion(List<AmalTask> tasks) {
    if (tasks.isEmpty) return 0.0;
    int earnedPoints = 0;
    int totalPossiblePoints = 0;
    for (final task in tasks) {
      totalPossiblePoints += task.points;
      final val = values[task.id];
      if (task.inputType == TaskInputType.checkbox && val == true) {
        earnedPoints += task.points;
      } else if (task.inputType == TaskInputType.counter && (val ?? 0) >= 5) {
        earnedPoints += task.points;
      } else if (task.inputType == TaskInputType.numberInput && (val ?? 0) > 0) {
        earnedPoints += task.points;
      }
    }
    // Guard against division by zero
    if (totalPossiblePoints == 0) return 0.0;
    return earnedPoints / totalPossiblePoints;
  }

  /// Total points earned today.
  int getEarnedPoints(List<AmalTask> tasks) {
    int earnedPoints = 0;
    for (final task in tasks) {
      final val = values[task.id];
      if (task.inputType == TaskInputType.checkbox && val == true) {
        earnedPoints += task.points;
      } else if (task.inputType == TaskInputType.counter && (val ?? 0) >= 5) {
        earnedPoints += task.points;
      } else if (task.inputType == TaskInputType.numberInput && (val ?? 0) > 0) {
        earnedPoints += task.points;
      }
    }
    return earnedPoints;
  }

  /// Total possible points for the given tasks.
  int getTotalPoints(List<AmalTask> tasks) {
    return tasks.fold(0, (sum, task) => sum + task.points);
  }


  /// Get or set a boolean field by its string ID.
  bool getBool(String id) => values[id] == true;

  void setBool(String id, bool value) {
    values[id] = value;
  }

  /// Get or set a counter field by its string ID.
  int getCounter(String id) => values[id] is int ? values[id] : 0;

  void setCounter(String id, int value) {
    values[id] = value;
  }

  /// Toggle a boolean field and return the new value.
  bool toggle(String id) {
    final newVal = !getBool(id);
    setBool(id, newVal);
    return newVal;
  }

  /// Increment a counter field. Returns the new value.
  int increment(String id, int max) {
    final current = getCounter(id);
    final newVal = (current < max) ? current + 1 : 0; 
    setCounter(id, newVal);
    return newVal;
  }

  // ─── Serialization ────────────────────────────────
  Map<String, dynamic> toJson() => {
        'date': date,
        'values': values,
      };

  factory DailyLog.fromJson(Map<String, dynamic> json) {
    // Migration logic: if 'values' doesn't exist, it might be old format
    if (json.containsKey('values')) {
      return DailyLog(
        date: json['date'] as String,
        values: Map<String, dynamic>.from(json['values'] as Map),
      );
    } else {
      // Basic migration for common fields
      final values = <String, dynamic>{};
      json.forEach((key, value) {
        if (key != 'date') values[key] = value;
      });
      return DailyLog(date: json['date'] as String, values: values);
    }
  }

  DailyLog copyWith({Map<String, dynamic>? values}) => DailyLog(
        date: date,
        values: values ?? Map<String, dynamic>.from(this.values),
      );
}

/// Simple local database service using SharedPreferences.
/// Each day's data is stored as a JSON string keyed by date.
class DatabaseService {
  static DatabaseService? _instance;
  late SharedPreferences _prefs;

  DatabaseService._();

  static Future<DatabaseService> initialize() async {
    if (_instance != null) return _instance!;
    _instance = DatabaseService._();
    _instance!._prefs = await SharedPreferences.getInstance();
    return _instance!;
  }

  static DatabaseService get instance {
    if (_instance == null) {
      throw StateError('DatabaseService not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  String _dateKey(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  /// Get today's log.
  DailyLog getTodayLog() => getLog(DateTime.now());

  /// Get a specific day's log. Creates a new one if it doesn't exist.
  DailyLog getLog(DateTime date) {
    final key = _dateKey(date);
    final jsonStr = _prefs.getString('log_$key');
    if (jsonStr != null) {
      try {
        return DailyLog.fromJson(json.decode(jsonStr));
      } catch (e) {
        debugPrint('Error parsing log for $key: $e');
      }
    }
    return DailyLog(date: key);
  }

  /// Save a day's log.
  Future<void> saveLog(DailyLog log) async {
    await _prefs.setString('log_${log.date}', json.encode(log.toJson()));
    // Invalidate streak cache on save
    await _prefs.remove('cached_streak');
  }

  /// Get logs for a date range (inclusive).
  List<DailyLog> getLogsInRange(DateTime start, DateTime end) {
    final logs = <DailyLog>[];
    var current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    while (!current.isAfter(endDate)) {
      logs.add(getLog(current));
      current = current.add(const Duration(days: 1));
    }
    return logs;
  }

  /// Get logs for the current month.
  List<DailyLog> getCurrentMonthLogs() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0); // last day of month
    return getLogsInRange(start, end);
  }

  /// Calculate current streak (consecutive days with >50% completion).
  /// Optimized with caching to prevent 365 JSON decodes on every UI refresh.
  int calculateStreak(List<AmalTask> tasks) {
    if (tasks.isEmpty) return 0;

    // 1. Check Cache
    final cached = _prefs.getInt('cached_streak');
    final lastUpdate = _prefs.getString('last_streak_update');
    final today = _dateKey(DateTime.now());

    if (cached != null && lastUpdate == today) {
      return cached;
    }

    // 2. Heavy Calculation
    int streak = 0;
    var date = DateTime.now();
    
    // Start from yesterday if today is not complete yet
    final todayLog = getLog(date);
    if (todayLog.calculateCompletion(tasks) < 0.5) {
      date = date.subtract(const Duration(days: 1));
    }

    for (int i = 0; i < 365; i++) {
      final key = _dateKey(date);
      final jsonStr = _prefs.getString('log_$key');
      
      if (jsonStr == null) break;

      try {
        final log = DailyLog.fromJson(json.decode(jsonStr));
        if (log.calculateCompletion(tasks) >= 0.5) {
          streak++;
          date = date.subtract(const Duration(days: 1));
        } else {
          break;
        }
      } catch (_) {
        break;
      }
    }

    // 3. Update Cache
    _prefs.setInt('cached_streak', streak);
    _prefs.setString('last_streak_update', today);

    return streak;
  }

  /// Get all keys (dates) that have stored logs.
  List<String> getAllLogDates() {
    return _prefs
        .getKeys()
        .where((k) => k.startsWith('log_'))
        .map((k) => k.substring(4))
        .toList()
      ..sort();
  }

  /// Clear all stored log data.
  Future<void> clearAllData() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith('log_')).toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  /// Sync all local logs to Supabase cloud.
  Future<void> syncToCloud() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final dates = getAllLogDates();
    if (dates.isEmpty) return;

    final logsJson = dates.map((d) {
      final log = getLog(DateTime.parse(d));
      final json = log.toJson();
      json['user_id'] = user.id;
      return json;
    }).toList();

    // Batch upsert for efficiency
    await client.from('daily_logs').upsert(logsJson);
  }

  /// Download history from Supabase and save locally.
  Future<void> restoreFromCloud() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    final response = await client
        .from('daily_logs')
        .select()
        .eq('user_id', user.id);

    final List<dynamic> data = response as List<dynamic>;

    for (final item in data) {
      final log = DailyLog.fromJson(item as Map<String, dynamic>);
      await saveLog(log);
    }
  }
}

