import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Enum representing all trackable items from the PDF.
enum AmalCategory {
  salah,
  zikr,
  habit,
  dont,
  weekly,
  monthly,
  sunnah,
}

/// A single trackable Amal item definition.
class AmalItem {
  final String id;
  final String title;
  final String subtitle;
  final AmalCategory category;
  final IconData icon;
  final Color color;
  final bool isCounter;
  final int maxCount;
  final bool isWeekly;
  final bool isMonthly;
  final List<int>? activeDays; // 1=Mon, 7=Sun

  const AmalItem({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.category,
    required this.icon,
    required this.color,
    this.isCounter = false,
    this.maxCount = 1,
    this.isWeekly = false,
    this.isMonthly = false,
    this.activeDays,
  });
}

/// Static definitions of all Amal items from the PDF.
class SalahData {
  SalahData._();

  // ─── Daily Salah ──────────────────────────────────
  static const List<AmalItem> dailySalah = [
    AmalItem(
      id: 'fajr',
      title: 'Fajr',
      subtitle: 'Dawn Prayer',
      category: AmalCategory.salah,
      icon: Icons.wb_twilight_rounded,
      color: AppColors.fajrColor,
    ),
    AmalItem(
      id: 'dhuhr',
      title: 'Dhuhr',
      subtitle: 'Noon Prayer',
      category: AmalCategory.salah,
      icon: Icons.wb_sunny_rounded,
      color: AppColors.dhuhrColor,
    ),
    AmalItem(
      id: 'asr',
      title: 'Asr',
      subtitle: 'Afternoon Prayer',
      category: AmalCategory.salah,
      icon: Icons.wb_sunny_outlined,
      color: AppColors.asrColor,
    ),
    AmalItem(
      id: 'maghrib',
      title: 'Maghrib',
      subtitle: 'Sunset Prayer',
      category: AmalCategory.salah,
      icon: Icons.nights_stay_rounded,
      color: AppColors.maghribColor,
    ),
    AmalItem(
      id: 'isha',
      title: 'Isha',
      subtitle: 'Night Prayer',
      category: AmalCategory.salah,
      icon: Icons.dark_mode_rounded,
      color: AppColors.ishaColor,
    ),
    AmalItem(
      id: 'sunnahMuakkadah',
      title: 'Sunnah',
      subtitle: '12 Rakat Muakkadah',
      category: AmalCategory.salah,
      icon: Icons.auto_awesome_rounded,
      color: AppColors.categoryPrayer,
      isCounter: true,
      maxCount: 12,
    ),
    AmalItem(
      id: 'ishraq',
      title: 'Ishraq',
      subtitle: 'Post-sunrise Prayer',
      category: AmalCategory.salah,
      icon: Icons.light_mode_rounded,
      color: AppColors.warmAmber,
    ),
  ];

  // ─── Zikr & Tilawat ──────────────────────────────
  static const List<AmalItem> zikr = [
    AmalItem(
      id: 'morningAzkar',
      title: 'Morning Azkar',
      subtitle: 'Masnoon Azkar',
      category: AmalCategory.zikr,
      icon: Icons.wb_twilight_outlined,
      color: AppColors.categoryZikr,
      isCounter: true,
      maxCount: 5,
    ),
    AmalItem(
      id: 'eveningAzkar',
      title: 'Evening Azkar',
      subtitle: 'Masnoon Azkar',
      category: AmalCategory.zikr,
      icon: Icons.nights_stay_outlined,
      color: AppColors.categoryZikr,
      isCounter: true,
      maxCount: 5,
    ),
  ];

  // ─── Habits (To-Do) ──────────────────────────────
  static const List<AmalItem> habits = [
    AmalItem(
      id: 'fiveMinDua',
      title: '5 Min Dua',
      subtitle: 'Daily supplication',
      category: AmalCategory.habit,
      icon: Icons.front_hand_rounded,
      color: AppColors.categoryHabit,
    ),
    AmalItem(
      id: 'salahOnTime',
      title: 'Salah on Time',
      subtitle: '2 Rakat/5min, 4 Rakat/10min',
      category: AmalCategory.habit,
      icon: Icons.timer_rounded,
      color: AppColors.categoryHabit,
    ),
    AmalItem(
      id: 'removedObstacles',
      title: 'Clear Path',
      subtitle: 'Remove obstacles from path',
      category: AmalCategory.habit,
      icon: Icons.cleaning_services_rounded,
      color: AppColors.categoryHabit,
    ),
    AmalItem(
      id: 'physicalHealth',
      title: 'Exercise',
      subtitle: '2 Pushups, 4 Up-Downs',
      category: AmalCategory.habit,
      icon: Icons.fitness_center_rounded,
      color: AppColors.categoryHabit,
    ),
    AmalItem(
      id: 'socialMediaLimit',
      title: 'Screen Limit',
      subtitle: 'Under 1 hour social media',
      category: AmalCategory.habit,
      icon: Icons.phone_android_rounded,
      color: AppColors.categoryHabit,
    ),
  ];

  // ─── Don'ts ───────────────────────────────────────
  static const List<AmalItem> donts = [
    AmalItem(
      id: 'sleptBefore1030',
      title: 'Sleep by 10:30',
      subtitle: 'Early sleep Sunnah',
      category: AmalCategory.dont,
      icon: Icons.bedtime_rounded,
      color: AppColors.categoryDont,
    ),
  ];

  // ─── Weekly ───────────────────────────────────────
  static const List<AmalItem> weekly = [
    AmalItem(
      id: 'surahKahf',
      title: 'Surah Kahf',
      subtitle: 'Friday recitation',
      category: AmalCategory.weekly,
      icon: Icons.menu_book_rounded,
      color: AppColors.categoryWeekly,
      isWeekly: true,
      activeDays: [5], // Friday
    ),
    AmalItem(
      id: 'durood',
      title: 'Durood',
      subtitle: 'Send salutations',
      category: AmalCategory.weekly,
      icon: Icons.favorite_rounded,
      color: AppColors.categoryWeekly,
      isWeekly: true,
    ),
    AmalItem(
      id: 'fridayMaghribDua',
      title: 'Friday Dua',
      subtitle: 'Friday Maghrib Dua',
      category: AmalCategory.weekly,
      icon: Icons.mosque_rounded,
      color: AppColors.categoryWeekly,
      isWeekly: true,
      activeDays: [5],
    ),
    AmalItem(
      id: 'mondayFasting',
      title: 'Monday Fast',
      subtitle: 'Sunnah fasting',
      category: AmalCategory.weekly,
      icon: Icons.no_food_rounded,
      color: AppColors.categoryWeekly,
      isWeekly: true,
      activeDays: [1],
    ),
    AmalItem(
      id: 'thursdayFasting',
      title: 'Thursday Fast',
      subtitle: 'Sunnah fasting',
      category: AmalCategory.weekly,
      icon: Icons.no_food_rounded,
      color: AppColors.categoryWeekly,
      isWeekly: true,
      activeDays: [4],
    ),
  ];

  // ─── Monthly / Dhul Hijjah ────────────────────────
  static const List<AmalItem> monthly = [
    AmalItem(
      id: 'publicTakbeer',
      title: 'Public Takbeer',
      subtitle: 'Dhul Hijjah',
      category: AmalCategory.monthly,
      icon: Icons.campaign_rounded,
      color: AppColors.categoryMonthly,
      isMonthly: true,
    ),
    AmalItem(
      id: 'ayyamAlBidh',
      title: 'Ayyam al-Bidh',
      subtitle: 'White days fasting',
      category: AmalCategory.monthly,
      icon: Icons.brightness_3_rounded,
      color: AppColors.categoryMonthly,
      isMonthly: true,
    ),
    AmalItem(
      id: 'dhulHijjahFasting',
      title: 'Dhul Hijjah Fast',
      subtitle: '1st 9 Days',
      category: AmalCategory.monthly,
      icon: Icons.calendar_month_rounded,
      color: AppColors.categoryMonthly,
      isMonthly: true,
    ),
  ];

  // ─── Forgotten Sunnah ─────────────────────────────
  static const List<AmalItem> forgottenSunnah = [
    AmalItem(
      id: 'miswakEnteringHome',
      title: 'Miswak',
      subtitle: 'When entering home',
      category: AmalCategory.sunnah,
      icon: Icons.home_rounded,
      color: AppColors.sageGreen,
    ),
    AmalItem(
      id: 'twoRakatTravel',
      title: '2 Rakat Travel',
      subtitle: 'Before/after travel',
      category: AmalCategory.sunnah,
      icon: Icons.flight_rounded,
      color: AppColors.sageGreen,
    ),
  ];

  /// All items flattened into a single list.
  static List<AmalItem> get allItems => [
        ...dailySalah,
        ...zikr,
        ...habits,
        ...donts,
        ...weekly,
        ...monthly,
        ...forgottenSunnah,
      ];
}
