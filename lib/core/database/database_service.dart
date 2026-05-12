import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// Represents a single day's tracking data.
/// All fields map directly to the PDF Amal sheet.
class DailyLog {
  final String date; // yyyy-MM-dd format key

  // ─── Daily Salah ──────────────────────────────────
  bool fajr;
  bool dhuhr;
  bool asr;
  bool maghrib;
  bool isha;
  int sunnahMuakkadah; // 0-12
  bool ishraq;

  // ─── Zikr & Tilawat ──────────────────────────────
  int morningAzkar; // 0-5
  int eveningAzkar; // 0-5

  // ─── Habits (To-Do) ──────────────────────────────
  bool fiveMinDua;
  bool salahOnTime;
  bool removedObstacles;
  bool physicalHealth;
  bool socialMediaLimit;

  // ─── Don'ts ───────────────────────────────────────
  bool sleptBefore1030;

  // ─── Weekly ───────────────────────────────────────
  bool surahKahf;
  bool durood;
  bool fridayMaghribDua;
  bool mondayFasting;
  bool thursdayFasting;

  // ─── Monthly / Dhul Hijjah ────────────────────────
  bool publicTakbeer;
  bool ayyamAlBidh;
  bool dhulHijjahFasting;

  // ─── Forgotten Sunnah ─────────────────────────────
  bool miswakEnteringHome;
  bool twoRakatTravel;

  DailyLog({
    required this.date,
    this.fajr = false,
    this.dhuhr = false,
    this.asr = false,
    this.maghrib = false,
    this.isha = false,
    this.sunnahMuakkadah = 0,
    this.ishraq = false,
    this.morningAzkar = 0,
    this.eveningAzkar = 0,
    this.fiveMinDua = false,
    this.salahOnTime = false,
    this.removedObstacles = false,
    this.physicalHealth = false,
    this.socialMediaLimit = false,
    this.sleptBefore1030 = false,
    this.surahKahf = false,
    this.durood = false,
    this.fridayMaghribDua = false,
    this.mondayFasting = false,
    this.thursdayFasting = false,
    this.publicTakbeer = false,
    this.ayyamAlBidh = false,
    this.dhulHijjahFasting = false,
    this.miswakEnteringHome = false,
    this.twoRakatTravel = false,
  });

  /// Returns a value 0.0–1.0 representing daily completion.
  double get completionPercentage {
    int total = 0;
    int completed = 0;

    // Salah (7 items: 5 prayers + sunnah ratio + ishraq)
    final boolSalah = [fajr, dhuhr, asr, maghrib, isha, ishraq];
    total += boolSalah.length;
    completed += boolSalah.where((b) => b).length;

    // Sunnah as fraction
    total += 1;
    completed += (sunnahMuakkadah >= 12) ? 1 : 0;

    // Zikr (2 items, each maxed at 5)
    total += 2;
    completed += (morningAzkar >= 5) ? 1 : 0;
    completed += (eveningAzkar >= 5) ? 1 : 0;

    // Habits (5 items)
    final boolHabits = [
      fiveMinDua, salahOnTime, removedObstacles,
      physicalHealth, socialMediaLimit,
    ];
    total += boolHabits.length;
    completed += boolHabits.where((b) => b).length;

    // Don'ts (1 item)
    total += 1;
    completed += sleptBefore1030 ? 1 : 0;

    // Forgotten Sunnah (2 items)
    total += 2;
    completed += miswakEnteringHome ? 1 : 0;
    completed += twoRakatTravel ? 1 : 0;

    return total > 0 ? completed / total : 0.0;
  }

  /// Number of completed items (for display).
  int get completedCount {
    int count = 0;
    final bools = [
      fajr, dhuhr, asr, maghrib, isha, ishraq,
      fiveMinDua, salahOnTime, removedObstacles,
      physicalHealth, socialMediaLimit, sleptBefore1030,
      miswakEnteringHome, twoRakatTravel,
    ];
    count += bools.where((b) => b).length;
    if (sunnahMuakkadah >= 12) count++;
    if (morningAzkar >= 5) count++;
    if (eveningAzkar >= 5) count++;
    return count;
  }

  int get totalItems => 17; // Total trackable daily items

  /// Get or set a boolean field by its string ID.
  bool getBool(String id) {
    switch (id) {
      case 'fajr': return fajr;
      case 'dhuhr': return dhuhr;
      case 'asr': return asr;
      case 'maghrib': return maghrib;
      case 'isha': return isha;
      case 'ishraq': return ishraq;
      case 'fiveMinDua': return fiveMinDua;
      case 'salahOnTime': return salahOnTime;
      case 'removedObstacles': return removedObstacles;
      case 'physicalHealth': return physicalHealth;
      case 'socialMediaLimit': return socialMediaLimit;
      case 'sleptBefore1030': return sleptBefore1030;
      case 'surahKahf': return surahKahf;
      case 'durood': return durood;
      case 'fridayMaghribDua': return fridayMaghribDua;
      case 'mondayFasting': return mondayFasting;
      case 'thursdayFasting': return thursdayFasting;
      case 'publicTakbeer': return publicTakbeer;
      case 'ayyamAlBidh': return ayyamAlBidh;
      case 'dhulHijjahFasting': return dhulHijjahFasting;
      case 'miswakEnteringHome': return miswakEnteringHome;
      case 'twoRakatTravel': return twoRakatTravel;
      default: return false;
    }
  }

  void setBool(String id, bool value) {
    switch (id) {
      case 'fajr': fajr = value;
      case 'dhuhr': dhuhr = value;
      case 'asr': asr = value;
      case 'maghrib': maghrib = value;
      case 'isha': isha = value;
      case 'ishraq': ishraq = value;
      case 'fiveMinDua': fiveMinDua = value;
      case 'salahOnTime': salahOnTime = value;
      case 'removedObstacles': removedObstacles = value;
      case 'physicalHealth': physicalHealth = value;
      case 'socialMediaLimit': socialMediaLimit = value;
      case 'sleptBefore1030': sleptBefore1030 = value;
      case 'surahKahf': surahKahf = value;
      case 'durood': durood = value;
      case 'fridayMaghribDua': fridayMaghribDua = value;
      case 'mondayFasting': mondayFasting = value;
      case 'thursdayFasting': thursdayFasting = value;
      case 'publicTakbeer': publicTakbeer = value;
      case 'ayyamAlBidh': ayyamAlBidh = value;
      case 'dhulHijjahFasting': dhulHijjahFasting = value;
      case 'miswakEnteringHome': miswakEnteringHome = value;
      case 'twoRakatTravel': twoRakatTravel = value;
    }
  }

  /// Get or set a counter field by its string ID.
  int getCounter(String id) {
    switch (id) {
      case 'sunnahMuakkadah': return sunnahMuakkadah;
      case 'morningAzkar': return morningAzkar;
      case 'eveningAzkar': return eveningAzkar;
      default: return 0;
    }
  }

  void setCounter(String id, int value) {
    switch (id) {
      case 'sunnahMuakkadah': sunnahMuakkadah = value;
      case 'morningAzkar': morningAzkar = value;
      case 'eveningAzkar': eveningAzkar = value;
    }
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
    final newVal = (current < max) ? current + 1 : 0; // reset after max
    setCounter(id, newVal);
    return newVal;
  }

  // ─── Serialization ────────────────────────────────
  Map<String, dynamic> toJson() => {
        'date': date,
        'fajr': fajr,
        'dhuhr': dhuhr,
        'asr': asr,
        'maghrib': maghrib,
        'isha': isha,
        'sunnahMuakkadah': sunnahMuakkadah,
        'ishraq': ishraq,
        'morningAzkar': morningAzkar,
        'eveningAzkar': eveningAzkar,
        'fiveMinDua': fiveMinDua,
        'salahOnTime': salahOnTime,
        'removedObstacles': removedObstacles,
        'physicalHealth': physicalHealth,
        'socialMediaLimit': socialMediaLimit,
        'sleptBefore1030': sleptBefore1030,
        'surahKahf': surahKahf,
        'durood': durood,
        'fridayMaghribDua': fridayMaghribDua,
        'mondayFasting': mondayFasting,
        'thursdayFasting': thursdayFasting,
        'publicTakbeer': publicTakbeer,
        'ayyamAlBidh': ayyamAlBidh,
        'dhulHijjahFasting': dhulHijjahFasting,
        'miswakEnteringHome': miswakEnteringHome,
        'twoRakatTravel': twoRakatTravel,
      };

  factory DailyLog.fromJson(Map<String, dynamic> json) => DailyLog(
        date: json['date'] as String,
        fajr: json['fajr'] as bool? ?? false,
        dhuhr: json['dhuhr'] as bool? ?? false,
        asr: json['asr'] as bool? ?? false,
        maghrib: json['maghrib'] as bool? ?? false,
        isha: json['isha'] as bool? ?? false,
        sunnahMuakkadah: json['sunnahMuakkadah'] as int? ?? 0,
        ishraq: json['ishraq'] as bool? ?? false,
        morningAzkar: json['morningAzkar'] as int? ?? 0,
        eveningAzkar: json['eveningAzkar'] as int? ?? 0,
        fiveMinDua: json['fiveMinDua'] as bool? ?? false,
        salahOnTime: json['salahOnTime'] as bool? ?? false,
        removedObstacles: json['removedObstacles'] as bool? ?? false,
        physicalHealth: json['physicalHealth'] as bool? ?? false,
        socialMediaLimit: json['socialMediaLimit'] as bool? ?? false,
        sleptBefore1030: json['sleptBefore1030'] as bool? ?? false,
        surahKahf: json['surahKahf'] as bool? ?? false,
        durood: json['durood'] as bool? ?? false,
        fridayMaghribDua: json['fridayMaghribDua'] as bool? ?? false,
        mondayFasting: json['mondayFasting'] as bool? ?? false,
        thursdayFasting: json['thursdayFasting'] as bool? ?? false,
        publicTakbeer: json['publicTakbeer'] as bool? ?? false,
        ayyamAlBidh: json['ayyamAlBidh'] as bool? ?? false,
        dhulHijjahFasting: json['dhulHijjahFasting'] as bool? ?? false,
        miswakEnteringHome: json['miswakEnteringHome'] as bool? ?? false,
        twoRakatTravel: json['twoRakatTravel'] as bool? ?? false,
      );

  DailyLog copyWith() => DailyLog.fromJson(toJson());
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
  int calculateStreak() {
    int streak = 0;
    var date = DateTime.now();
    // Start from yesterday if today is not complete yet
    final todayLog = getLog(date);
    if (todayLog.completionPercentage < 0.5) {
      date = date.subtract(const Duration(days: 1));
    }

    for (int i = 0; i < 365; i++) {
      final log = getLog(date);
      if (log.completionPercentage >= 0.5) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
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
}
