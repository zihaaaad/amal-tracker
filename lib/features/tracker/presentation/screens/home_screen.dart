import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/salah_data.dart';
import '../../../tracker/providers/daily_log_provider.dart';
import '../widgets/salah_card.dart';
import '../widgets/zikr_counter_card.dart';
import '../widgets/habit_card.dart';
import '../widgets/progress_ring.dart';

/// The main home screen with a premium Bento grid layout.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyLog = ref.watch(dailyLogProvider);
    final streak = ref.watch(streakProvider);
    final timeContext = ref.watch(timeContextProvider);

    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final dateStr = DateFormat('EEEE, MMM d').format(now);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── Header ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        // Time context indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getTimeIcon(timeContext),
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getTimeName(timeContext),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ─── Progress Ring ─────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: ProgressRing(
                  percentage: dailyLog.completionPercentage,
                  completedCount: dailyLog.completedCount,
                  totalCount: dailyLog.totalItems,
                  streak: streak,
                ),
              ),
            ),

            // ─── Salah Section ─────────────────────────
            const SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Salah',
                icon: Icons.mosque_rounded,
                color: AppColors.categoryPrayer,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.9,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final items = SalahData.dailySalah
                        .where((i) =>
                            !i.isCounter &&
                            shouldShowItem(i.id, timeContext))
                        .toList();
                    if (index >= items.length) return null;
                    final item = items[index];
                    return SalahCard(
                      item: item,
                      isCompleted: dailyLog.getBool(item.id),
                      onToggle: () {
                        ref.read(dailyLogProvider.notifier).toggleItem(item.id);
                      },
                    );
                  },
                  childCount: SalahData.dailySalah
                      .where((i) =>
                          !i.isCounter &&
                          shouldShowItem(i.id, timeContext))
                      .length,
                ),
              ),
            ),

            // ─── Sunnah Counter ────────────────────────
            if (shouldShowItem('sunnahMuakkadah', timeContext))
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: ZikrCounterCard(
                    item: SalahData.dailySalah
                        .firstWhere((i) => i.id == 'sunnahMuakkadah'),
                    currentValue: dailyLog.sunnahMuakkadah,
                    onValueChanged: (val) {
                      ref
                          .read(dailyLogProvider.notifier)
                          .setCounter('sunnahMuakkadah', val);
                    },
                  ),
                ),
              ),

            // ─── Zikr Section ──────────────────────────
            const SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Zikr & Tilawat',
                icon: Icons.auto_awesome_rounded,
                color: AppColors.categoryZikr,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final items = SalahData.zikr
                        .where((i) => shouldShowItem(i.id, timeContext))
                        .toList();
                    if (index >= items.length) return null;
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ZikrCounterCard(
                        item: item,
                        currentValue: dailyLog.getCounter(item.id),
                        onValueChanged: (val) {
                          ref
                              .read(dailyLogProvider.notifier)
                              .setCounter(item.id, val);
                        },
                      ),
                    );
                  },
                  childCount: SalahData.zikr
                      .where((i) => shouldShowItem(i.id, timeContext))
                      .length,
                ),
              ),
            ),

            // ─── Habits Section ────────────────────────
            const SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Daily Habits',
                icon: Icons.task_alt_rounded,
                color: AppColors.categoryHabit,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.95,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final allHabitItems = [
                      ...SalahData.habits,
                      ...SalahData.donts,
                      ...SalahData.forgottenSunnah,
                    ].where((i) => shouldShowItem(i.id, timeContext)).toList();
                    if (index >= allHabitItems.length) return null;
                    final item = allHabitItems[index];
                    return HabitCard(
                      item: item,
                      isCompleted: dailyLog.getBool(item.id),
                      onToggle: () {
                        ref.read(dailyLogProvider.notifier).toggleItem(item.id);
                      },
                    );
                  },
                  childCount: [
                    ...SalahData.habits,
                    ...SalahData.donts,
                    ...SalahData.forgottenSunnah,
                  ].where((i) => shouldShowItem(i.id, timeContext)).length,
                ),
              ),
            ),

            // ─── Weekly Section ────────────────────────
            const SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Weekly',
                icon: Icons.calendar_today_rounded,
                color: AppColors.categoryWeekly,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.95,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final items = SalahData.weekly;
                    if (index >= items.length) return null;
                    final item = items[index];
                    return HabitCard(
                      item: item,
                      isCompleted: dailyLog.getBool(item.id),
                      onToggle: () {
                        ref.read(dailyLogProvider.notifier).toggleItem(item.id);
                      },
                    );
                  },
                  childCount: SalahData.weekly.length,
                ),
              ),
            ),

            // ─── Monthly Section ───────────────────────
            const SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Monthly / Dhul Hijjah',
                icon: Icons.calendar_month_rounded,
                color: AppColors.categoryMonthly,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.95,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final items = SalahData.monthly;
                    if (index >= items.length) return null;
                    final item = items[index];
                    return HabitCard(
                      item: item,
                      isCompleted: dailyLog.getBool(item.id),
                      onToggle: () {
                        ref.read(dailyLogProvider.notifier).toggleItem(item.id);
                      },
                    );
                  },
                  childCount: SalahData.monthly.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 5) return 'Assalamu Alaikum 🌙';
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    if (hour < 21) return 'Good Evening 🌅';
    return 'Good Night 🌙';
  }

  IconData _getTimeIcon(TimeContext ctx) {
    switch (ctx) {
      case TimeContext.earlyMorning: return Icons.wb_twilight_rounded;
      case TimeContext.morning: return Icons.wb_sunny_rounded;
      case TimeContext.afternoon: return Icons.wb_sunny_outlined;
      case TimeContext.evening: return Icons.nights_stay_rounded;
      case TimeContext.night: return Icons.dark_mode_rounded;
      case TimeContext.lateNight: return Icons.bedtime_rounded;
    }
  }

  String _getTimeName(TimeContext ctx) {
    switch (ctx) {
      case TimeContext.earlyMorning: return 'Fajr Time';
      case TimeContext.morning: return 'Morning';
      case TimeContext.afternoon: return 'Afternoon';
      case TimeContext.evening: return 'Evening';
      case TimeContext.night: return 'Night';
      case TimeContext.lateNight: return 'Late Night';
    }
  }
}

/// Section header widget for each Amal category.
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
