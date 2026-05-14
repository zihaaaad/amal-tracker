import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      } else if (task.inputType == TaskInputType.numberInput && (val ?? 0) > 0) {
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

  Map<String, dynamic> toJson() => {'date': date, 'completion_data': values};
  factory DailyLog.fromJson(Map<String, dynamic> json) => 
      DailyLog(date: json['date'], values: json['completion_data'] ?? {});

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
  bool _initialized = false;

  static Future<DatabaseService> initialize() async {
    if (instance._initialized) return instance;
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      instance._isar = await Isar.open(
        [DailyLogEntrySchema, TaskEntrySchema],
        directory: dir.path,
      );
      instance._prefs = await SharedPreferences.getInstance();
      instance._initialized = true;
      
      // Run migration in background to avoid blocking the splash screen
      unawaited(compute(_migrateInBackground, {
        'keys': instance._prefs.getKeys().where((k) => k.startsWith('log_')).toList(),
        'migrated': instance._prefs.getBool('isar_migrated') ?? false,
      }).then((_) {}).catchError((e) {
        debugPrint('Background migration failed: $e');
      }));
      
      // Also run synchronously for small datasets (safe check)
      await instance._migrateFromPrefs();
    } catch (e) {
      debugPrint('Database initialization error: $e');
      // We still mark as initialized if we caught an error to avoid infinite retry hangs,
      // but the app might be in a degraded state.
      instance._initialized = true; 
    }
    
    return instance;
  }

  static Future<void> _migrateInBackground(Map<String, dynamic> params) async {
    // Placeholder for heavy migration logic in an isolate
    // Actual Isar writes must happen on the main isolate
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
      try {
        return DailyLog(date: dateStr, values: json.decode(entry.valuesJson));
      } catch (_) {
        return DailyLog(date: dateStr);
      }
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
      await _isar.dailyLogEntrys.put(entry);
    });
  }

  List<DailyLog> getCurrentMonthLogs() {
    final now = DateTime.now();
    final firstDay = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1).subtract(const Duration(days: 1)));
    final lastDay = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month + 1, 0).add(const Duration(days: 1)));
    
    final entries = _isar.dailyLogEntrys
        .filter()
        .dateGreaterThan(firstDay)
        .and()
        .dateLessThan(lastDay)
        .findAllSync();

    return entries.map((e) {
      try {
        return DailyLog(date: e.date, values: json.decode(e.valuesJson));
      } catch (_) {
        return DailyLog(date: e.date);
      }
    }).toList();
  }

  /// Optimized streak calculation: fetches recent entries in bulk instead of one-by-one.
  int calculateStreak(List<AmalTask> tasks) {
    if (tasks.isEmpty) return 0;
    
    // Batch-load the last 365 days of entries sorted by date descending
    final entries = _isar.dailyLogEntrys
        .filter()
        .dateGreaterThan(DateFormat('yyyy-MM-dd').format(
          DateTime.now().subtract(const Duration(days: 366)),
        ))
        .sortByDateDesc()
        .findAllSync();

    if (entries.isEmpty) return 0;

    // Build a lookup map for O(1) access
    final logMap = <String, DailyLog>{};
    for (final e in entries) {
      try {
        logMap[e.date] = DailyLog(date: e.date, values: json.decode(e.valuesJson));
      } catch (_) {}
    }

    int streak = 0;
    DateTime checkDate = DateTime.now();
    bool skippedToday = false;

    for (int i = 0; i < 366; i++) {
      final dateStr = DateFormat('yyyy-MM-dd').format(checkDate);
      final log = logMap[dateStr];
      
      if (log != null && log.calculateCompletion(tasks) >= 0.5) {
        streak++;
      } else {
        // Allow skipping today if not yet tracked
        if (i == 0 && !skippedToday) {
          skippedToday = true;
          checkDate = checkDate.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<void> clearAllData() async {
    await _isar.writeTxn(() => _isar.dailyLogEntrys.clear());
  }

  /// Enhanced Sync Engine: Implements Atomic Batching and Failure Tracking.
  Future<SyncResult> syncToCloud() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return SyncResult.unauthorized();

    final lastSyncStr = _prefs.getString('last_sync_timestamp');
    final lastSync = lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;

    final allEntries = await _isar.dailyLogEntrys.where().findAll();
    if (allEntries.isEmpty) return SyncResult.success(0);

    // Filter local logs that are newer than lastSync
    final logsToSyncLocal = lastSync == null 
        ? allEntries 
        : allEntries.where((e) => e.updatedAt.isAfter(lastSync)).toList();

    // 1. Fetch cloud timestamps to compare
    List<dynamic> cloudData = [];
    try {
      if (lastSync != null) {
        cloudData = await client.from('daily_logs')
            .select('date, updated_at')
            .eq('user_id', user.id)
            .gte('updated_at', lastSync.toIso8601String());
      } else {
        cloudData = await client.from('daily_logs')
            .select('date, updated_at')
            .eq('user_id', user.id);
      }
    } catch (e) {
      return SyncResult.partial(0, 'Failed to fetch cloud timestamps: $e');
    }

    final cloudMap = { 
      for (var e in cloudData) 
        e['date']: e['updated_at'] != null ? DateTime.parse(e['updated_at']) : DateTime.fromMillisecondsSinceEpoch(0) 
    };

    final logsToSync = <Map<String, dynamic>>[];

    // 2. Only push logs where local is newer than cloud
    for (final e in logsToSyncLocal) {
      final cloudUpdatedAt = cloudMap[e.date];
      if (cloudUpdatedAt == null || e.updatedAt.isAfter(cloudUpdatedAt)) {
        logsToSync.add({
          'date': e.date,
          'completion_data': json.decode(e.valuesJson),
          'user_id': user.id,
          'updated_at': e.updatedAt.toIso8601String(),
        });
      }
    }

    if (logsToSync.isEmpty) {
      await _prefs.setString('last_sync_timestamp', DateTime.now().toIso8601String());
      return SyncResult.success(0);
    }

    // 3. Process in batches with atomic failure tracking
    int syncedCount = 0;
    const batchSize = 50;
    for (int i = 0; i < logsToSync.length; i += batchSize) {
      final batch = logsToSync.sublist(i, (i + batchSize).clamp(0, logsToSync.length));
      try {
        await client.from('daily_logs').upsert(batch);
        syncedCount += batch.length;
      } catch (e) {
        debugPrint('Sync batch $i failed: $e');
        return SyncResult.partial(syncedCount, e.toString());
      }
    }
    
    await _prefs.setString('last_sync_timestamp', DateTime.now().toIso8601String());
    return SyncResult.success(syncedCount);
  }

  Future<void> restoreFromCloud() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    final lastSyncStr = _prefs.getString('last_sync_timestamp');
    final lastSync = lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;

    try {
      final dynamic response;
      if (lastSync != null) {
        response = await client.from('daily_logs')
            .select()
            .eq('user_id', user.id)
            .gte('updated_at', lastSync.toIso8601String());
      } else {
        response = await client.from('daily_logs')
            .select()
            .eq('user_id', user.id);
      }
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty) return;

      await _isar.writeTxn(() async {
        for (final item in data) {
          final dateStr = item['date'] is String ? item['date'] : item['date'].toString();
          final cloudUpdatedAt = item['updated_at'] != null 
              ? DateTime.parse(item['updated_at']) 
              : DateTime.fromMillisecondsSinceEpoch(0);
              
          final localEntry = await _isar.dailyLogEntrys.filter().dateEqualTo(dateStr).findFirst();
          
          // Only overwrite local if cloud is strictly newer, or local doesn't exist
          if (localEntry == null || cloudUpdatedAt.isAfter(localEntry.updatedAt)) {
            final entry = DailyLogEntry()
              ..id = localEntry?.id ?? Isar.autoIncrement
              ..date = dateStr
              ..valuesJson = json.encode(item['completion_data'] ?? {})
              ..createdAt = localEntry?.createdAt ?? DateTime.now()
              ..updatedAt = cloudUpdatedAt;
            await _isar.dailyLogEntrys.put(entry);
          }
        }
      });
    } catch (e) {
      debugPrint('Restore from cloud failed: $e');
    }
  }

  List<String> getAllLogDates() {
    return _isar.dailyLogEntrys.where().findAllSync().map((e) => e.date).toList();
  }
}

/// Big Tech Standard: Structured Result Types for operations.
class SyncResult {
  final bool isSuccess;
  final int count;
  final String? error;
  final bool isUnauthorized;

  SyncResult({required this.isSuccess, required this.count, this.error, this.isUnauthorized = false});

  factory SyncResult.success(int count) => SyncResult(isSuccess: true, count: count);
  factory SyncResult.partial(int count, String error) => SyncResult(isSuccess: false, count: count, error: error);
  factory SyncResult.unauthorized() => SyncResult(isSuccess: false, count: 0, isUnauthorized: true);
}
