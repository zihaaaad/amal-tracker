/// App-wide constants for Amal Tracker.
class AppConstants {
  AppConstants._();

  // ─── Supabase ─────────────────────────────────────
  static const String supabaseUrl = 'https://aqnsombaguxiamxtyudl.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFxbnNvbWJhZ3V4aWFteHR5dWRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1MDE2ODQsImV4cCI6MjA5NDA3NzY4NH0.vzmZDsarwBmrvFlVmyM5ycD46AahegV7UAesuieKkME';

  // ─── Counter Limits ───────────────────────────────
  static const int morningAzkarMax = 5;
  static const int eveningAzkarMax = 5;
  static const int sunnahMuakkadahMax = 12;

  // ─── Notification Channels ────────────────────────
  static const String notificationChannelId = 'amal_tracker_notifications';
  static const String notificationChannelName = 'Amal Tracker';
  static const String notificationChannelDesc =
      'Smart reminders for your daily Amal';

  // ─── WorkManager Task Names ───────────────────────
  static const String backgroundTaskName = 'amalTrackerBackgroundCheck';
  static const String periodicTaskName = 'amalTrackerPeriodicCheck';

  // ─── Timing Thresholds ────────────────────────────
  static const int sleepReminderHour = 22;
  static const int sleepReminderMinute = 0;
  static const int eveningCheckHour = 20;
  static const int morningMotivationHour = 5;
  static const int morningMotivationMinute = 30;

  // ─── Database ─────────────────────────────────────
  static const String dbName = 'amal_tracker_db';
  static const String dailyLogsTable = 'daily_logs';

  // ─── UI ───────────────────────────────────────────
  static const double cardBorderRadius = 16.0;
  static const double swipeThreshold = 0.4; // 40% of card width
  static const int holdToFillDurationMs = 2000;
}
