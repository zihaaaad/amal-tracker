import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/tracker/data/models/amal_task.dart';
import 'isar_schemas.dart';

/// Represents a single day's tracking data (UI/Logic Model).
class DailyLog {
  final String date; // yyyy-MM-dd format key
  final Map<String, dynamic> values;

  DailyLog({
    required this.date,
    Map<String, dynamic>? values,
  }) : values = values ?? {};

  double calculateCompletion(List<AmalTask> tasks) {
    if (tasks.isEmpty) return 0.0;
    int earned = getEarnedPoints(tasks);
    int total = getTotalPoints(tasks);
    return total == 0 ? 0.0 : earned / total;
  }

  int getEarnedPoints(List<AmalTask> tasks) {
    int earnedPoints = 0;
    for (final task in tasks) {
      final val = values[task.id];
      if (task.inputType == TaskInputType.checkbox && val == true) {
        earnedPoints += task.points;
      } else if (task.inputType == TaskInputType.counter && (val ?? 0) >= 5) {
        earnedPoints += task.points;
      }
    }
    return earnedPoints;
  }

  int getTotalPoints(List<AmalTask> tasks) {
    int total = 0;
    for (final task in tasks) {
      total += task.points;
    }
    return total;
  }

  Map<String, dynamic> toJson() => {'date': date, 'values': values};
  factory DailyLog.fromJson(Map<String, dynamic> json) => 
      DailyLog(date: json['date'], values: json['values']);

  bool getBool(String key) => values[key] == true;
  int getCounter(String key) => values[key] is int ? values[key] : 0;
  
  DailyLog copyWith({Map<String, dynamic>? values}) => 
      DailyLog(date: date, values: values ?? this.values);
}

/// High-Performance Database Service using Isar.
class DatabaseService {
  DatabaseService._();
  static final instance = DatabaseService._();

  late Isar _isar;
  late SharedPreferences _prefs;

  static Future<DatabaseService> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    instance._isar = await Isar.open(
      [DailyLogEntrySchema, TaskEntrySchema],
      directory: dir.path,
    );
    instance._prefs = await SharedPreferences.getInstance();
    await instance._migrateFromPrefs();
    return instance;
  }

  Future<void> _migrateFromPrefs() async {
    final migrated = _prefs.getBool('isar_migrated') ?? false;
    if (migrated) return;

    final keys = _prefs.getKeys().where((k) => k.startsWith('log_')).toList();
    if (keys.isEmpty) {
      await _prefs.setBool('isar_migrated', true);
      return;
    }

    await _isar.writeTxn(() async {
      for (final key in keys) {
        final date = key.replaceFirst('log_', '');
        final jsonStr = _prefs.getString(key);
        if (jsonStr != null) {
          final entry = DailyLogEntry()
            ..date = date
            ..valuesJson = jsonStr
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await _isar.dailyLogEntrys.put(entry);
        }
      }
    });

    await _prefs.setBool('isar_migrated', true);
  }

  DailyLog getLog(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final entry = _isar.dailyLogEntrys.filter().dateEqualTo(dateStr).findFirstSync();
    
    if (entry != null) {
      return DailyLog(date: dateStr, values: json.decode(entry.valuesJson));
    }
    return DailyLog(date: dateStr);
  }

  DailyLog getTodayLog() => getLog(DateTime.now());

  Future<void> saveLog(DailyLog log) async {
    final entry = DailyLogEntry()
      ..date = log.date
      ..valuesJson = json.encode(log.values)
      ..updatedAt = DateTime.now()
      ..createdAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.dailyLogEntrys.put(entry); // put uses the unique index 'date' to replace
    });
  }

  List<DailyLog> getCurrentMonthLogs() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    
    final entries = _isar.dailyLogEntrys
        .filter()
        .dateGreaterThan(DateFormat('yyyy-MM-dd').format(firstDay.subtract(const Duration(days: 1))))
        .and()
        .dateLessThan(DateFormat('yyyy-MM-dd').format(lastDay.add(const Duration(days: 1))))
        .findAllSync();

    return entries.map((e) => DailyLog(date: e.date, values: json.decode(e.valuesJson))).toList();
  }

  int calculateStreak(List<AmalTask> tasks) {
    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    while (true) {
      final log = getLog(checkDate);
      if (log.calculateCompletion(tasks) >= 0.5) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        if (streak == 0 && checkDate.day == DateTime.now().day) {
          checkDate = checkDate.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
    }
    return streak;
  }

  Future<void> clearAllData() async {
    await _isar.writeTxn(() => _isar.dailyLogEntrys.clear());
  }

  Future<void> syncToCloud() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    final entries = await _isar.dailyLogEntrys.where().findAll();
    if (entries.isEmpty) return;

    final logsJson = entries.map((e) {
      final values = json.decode(e.valuesJson);
      return {
        'date': e.date,
        'values': values,
        'user_id': user.id,
      };
    }).toList();

    await client.from('daily_logs').upsert(logsJson);
  }

  Future<void> restoreFromCloud() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    final response = await client.from('daily_logs').select().eq('user_id', user.id);
    final List<dynamic> data = response as List<dynamic>;

    await _isar.writeTxn(() async {
      for (final item in data) {
        final entry = DailyLogEntry()
          ..date = item['date']
          ..valuesJson = json.encode(item['values'])
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await _isar.dailyLogEntrys.put(entry);
      }
    });
  }

  List<String> getAllLogDates() {
    return _isar.dailyLogEntrys.where().findAllSync().map((e) => e.date).toList();
  }
}
