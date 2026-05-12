import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../tracker/providers/daily_log_provider.dart';
import '../widgets/progress_ring.dart';
import '../../providers/tasks_provider.dart';
import '../widgets/dynamic_task_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _checkCelebration(double completion) {
    if (completion >= 1.0 && _confettiController.state != ConfettiControllerState.playing) {
      _confettiController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyLog = ref.watch(dailyLogProvider);
    final streak = ref.watch(streakProvider);
    final timeContext = ref.watch(timeContextProvider);
    final groupedTasksAsync = ref.watch(groupedTasksProvider);
    final allTasksAsync = ref.watch(tasksProvider);

    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final dateStr = DateFormat('EEEE, MMM d').format(now);

    final allTasks = allTasksAsync.value ?? [];
    final completion = dailyLog.calculateCompletion(allTasks);
    
    // Trigger celebration if 100%
    _checkCelebration(completion);

    return Scaffold(
      backgroundColor: context.surface,
      body: SafeArea(
        child: Stack(
          children: [
            groupedTasksAsync.when(
              data: (groupedTasks) {
                return CustomScrollView(
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
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: context.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: context.textPrimary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                _buildTimeContextBadge(context, timeContext),
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
                          percentage: completion,
                          completedCount: dailyLog.getEarnedPoints(allTasks),
                          totalCount: dailyLog.getTotalPoints(allTasks),
                          streak: streak,
                        ),
                      ),
                    ),

                    // ─── Dynamic Categories ────────────────────
                    ...groupedTasks.entries.map((entry) {
                      final category = entry.key;
                      final tasks = entry.value;

                      return SliverMainAxisGroup(
                        slivers: [
                          SliverToBoxAdapter(
                            child: _SectionHeader(
                              title: _getCategoryTitle(category),
                              icon: _getCategoryIcon(category),
                              color: _getCategoryColor(category),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index >= tasks.length) return null;
                                  return DynamicTaskCard(task: tasks[index]);
                                },
                                childCount: tasks.length,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
            
            // Celebration Layer
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  AppColors.sageGreen,
                  AppColors.warmAmber,
                  Colors.blueAccent,
                  Colors.pinkAccent,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeContextBadge(BuildContext context, TimeContext timeContext) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getTimeIcon(timeContext), size: 14, color: context.textSecondary),
          const SizedBox(width: 4),
          Text(
            _getTimeName(timeContext),
            style: TextStyle(
              fontSize: 11,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryTitle(String category) {
    switch (category) {
      case 'salah': return 'Salah';
      case 'sunnah_salah': return 'Sunnah & Nafl';
      case 'zikr': return 'Zikr & Tilawat';
      case 'habits': return 'Daily Habits';
      case 'donts': return 'Things to Avoid';
      case 'weekly': return 'Weekly Amal';
      case 'dhul_hijjah': return 'Dhul Hijjah';
      case 'forgotten_sunnah': return 'Forgotten Sunnah';
      default: return category.toUpperCase();
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'salah': return Icons.mosque_rounded;
      case 'zikr': return Icons.waves_rounded;
      case 'habits': return Icons.task_alt_rounded;
      default: return Icons.auto_awesome_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'salah': return Colors.blueAccent;
      case 'zikr': return AppColors.sageGreen;
      case 'habits': return AppColors.warmAmber;
      case 'donts': return AppColors.softCoral;
      default: return AppColors.sageGreen;
    }
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
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
