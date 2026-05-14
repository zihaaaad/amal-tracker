import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/quotes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../tracker/providers/daily_log_provider.dart';
import '../../data/models/amal_task.dart';
import '../../providers/tasks_provider.dart';
import '../widgets/dynamic_task_card.dart';
import '../widgets/progress_ring.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late ConfettiController _confettiController;
  bool _hasCelebratedToday = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _checkCelebration(double completion) {
    if (completion >= 1.0 && !_hasCelebratedToday) {
      _hasCelebratedToday = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Success Haptic Choreography: Heavy followed by Medium
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 300), () {
          HapticFeedback.mediumImpact();
        });
        _confettiController.play();
      });
    } else if (completion < 1.0) {
      _hasCelebratedToday = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyLog = ref.watch(dailyLogProvider);
    final streak = ref.watch(streakProvider);
    final groupedTasksAsync = ref.watch(groupedTasksProvider);
    final allTasksAsync = ref.watch(tasksProvider);
    final user = ref.watch(userProvider);
    final timeContext = ref.watch(timeContextProvider);

    final now = DateTime.now();
    final userName = user?.userMetadata?['full_name']?.split(' ').first ?? '';
    final greeting = _getGreeting(now.hour, userName);
    final dateStr = DateFormat('EEEE, d MMMM').format(now);
    final quote = AppQuotes.getQuoteOfTheDay();

    final allTasks = allTasksAsync.value ?? [];
    final completion = dailyLog.calculateCompletion(allTasks);

    // Dynamic Sync Status (Big Tech UX Standard)
    final syncStatus = ref.watch(syncStatusProvider);

    ref.listen(dailyLogProvider, (_, next) {
      final tasks = ref.read(tasksProvider).value ?? [];
      _checkCelebration(next.calculateCompletion(tasks));
    });

    return Scaffold(
      backgroundColor: context.surface,
      body: SafeArea(
        child: Stack(
          children: [
            groupedTasksAsync.when(
              data: (groupedTasks) {
                return SlidableAutoCloseBehavior(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // ── Header with Quote ──────────────────────────
                      SliverToBoxAdapter(
                        child: _HomeHeader(
                          greeting: greeting,
                          dateStr: dateStr,
                          quote: quote,
                          hour: now.hour,
                          syncStatus: syncStatus,
                        ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0, curve: Curves.easeOutCubic),
                      ),

                      // ── Progress Ring ────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: ProgressRing(
                            percentage: completion,
                            completedCount: dailyLog.getEarnedPoints(allTasks),
                            totalCount: dailyLog.getTotalPoints(allTasks),
                            streak: streak,
                          ),
                        ).animate().fadeIn(delay: 200.ms, duration: 600.ms).scale(begin: const Offset(0.95, 0.95)),
                      ),

                      // ── Task Categories ──────────────────────────
                      ...groupedTasks.entries.map((entry) {
                        final category = entry.key;
                        final tasks = entry.value;
                        final doneCount = tasks
                            .where((t) =>
                                t.inputType == TaskInputType.checkbox
                                    ? dailyLog.getBool(t.id)
                                    : dailyLog.getCounter(t.id) >= 5)
                            .length;

                        return SliverMainAxisGroup(
                          slivers: [
                            SliverToBoxAdapter(
                              child: _SectionHeader(
                                title: _getCategoryTitle(category),
                                icon: _getCategoryIcon(category),
                                color: _getCategoryColor(category),
                                doneCount: doneCount,
                                totalCount: tasks.length,
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    if (index >= tasks.length) return null;
                                    final task = tasks[index];
                                    
                                    // Contextual Dimming: Dim tasks not relevant to current time
                                    final isRelevant = _isTaskRelevant(task, timeContext);
                                    
                                    return Opacity(
                                      opacity: isRelevant ? 1.0 : 0.4,
                                      child: DynamicTaskCard(task: task),
                                    )
                                        .animate()
                                        .fadeIn(delay: (400 + (index * 50)).ms, duration: 400.ms)
                                        .slideX(begin: 0.05, end: 0);
                                  },
                                  childCount: tasks.length,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),

                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),

            // ── Confetti ─────────────────────────────────────────
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 40,
                gravity: 0.25,
                shouldLoop: false,
                colors: const [
                  AppColors.sageGreen,
                  AppColors.sageGreenLight,
                  AppColors.warmAmber,
                  AppColors.warmAmberLight,
                  Color(0xFF6B9BD2),
                  Colors.white,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isTaskRelevant(AmalTask task, TimeContext context) {
    // Big Tech Excellence: Data-Driven Relevance
    // If it's a specific frequency task, it's always relevant on its due day
    if (task.frequency != TaskFrequency.daily) return true;

    // Hardcoded logic for legacy IDs, but prepared for metadata expansion
    final id = task.id.toLowerCase();
    if (id.contains('fajr') && context.index > TimeContext.earlyMorning.index) return false;
    if (id.contains('morning') && context.index > TimeContext.morning.index) return false;
    if (id.contains('dhuhr') && context.index > TimeContext.afternoon.index) return false;
    if (id.contains('asr') && context.index > TimeContext.evening.index) return false;
    
    return true;
  }

  String _getCategoryTitle(String category) {
    switch (category) {
      case 'salah': return 'Prayer';
      case 'sunnah_salah': return 'Sunnah & Nafl';
      case 'zikr': return 'Remembrance';
      case 'habits': return 'Productivity';
      case 'donts': return 'Self Discipline';
      case 'weekly': return 'Weekly Goals';
      default: return category;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'salah': return Icons.mosque_rounded;
      case 'sunnah_salah': return Icons.auto_awesome_rounded;
      case 'zikr': return Icons.waves_rounded;
      case 'habits': return Icons.flash_on_rounded;
      case 'donts': return Icons.shield_outlined;
      case 'weekly': return Icons.event_note_rounded;
      default: return Icons.bookmark_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'salah': return const Color(0xFF6B9BD2);
      case 'sunnah_salah': return const Color(0xFF9B8FD0);
      case 'zikr': return AppColors.sageGreen;
      case 'habits': return AppColors.warmAmber;
      case 'donts': return AppColors.softCoral;
      case 'weekly': return const Color(0xFF8A7FA3);
      default: return AppColors.sageGreen;
    }
  }

  String _getGreeting(int hour, String name) {
    final suffix = name.isNotEmpty ? ', $name' : '';
    if (hour < 5) return 'Assalamu Alaikum$suffix 🌙';
    if (hour < 12) return 'Salam, Good Morning$suffix ☀️';
    if (hour < 17) return 'Salam, Good Afternoon$suffix 🌤️';
    if (hour < 21) return 'Salam, Good Evening$suffix 🌅';
    return 'Salam, Good Night$suffix 🌙';
  }
}

// ─── Home Header ─────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final String greeting;
  final String dateStr;
  final String quote;
  final int hour;
  final SyncStatus? syncStatus;

  const _HomeHeader({
    required this.greeting,
    required this.dateStr,
    required this.quote,
    required this.hour,
    this.syncStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: context.headerGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: context.timeTint.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'AS-SUNNAH FOUNDATION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: context.timeTint.withValues(alpha: 0.5),
                          ),
                        ),
                        if (syncStatus != null) ...[
                          const SizedBox(width: 8),
                          _SyncIndicator(status: syncStatus!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      greeting,
                      style: TextStyle(
                        fontSize: 16,
                        color: context.timeTint,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: context.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.timeTint.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTimeIcon(hour),
                  color: context.timeTint,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceCard.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: context.glassBorder.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  color: context.timeTint.withValues(alpha: 0.3),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    quote,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondary.withValues(alpha: 0.7), // Lower opacity for hierarchy
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTimeIcon(int hour) {
    if (hour < 6) return Icons.nights_stay_rounded;
    if (hour < 12) return Icons.wb_sunny_rounded;
    if (hour < 17) return Icons.wb_sunny_outlined;
    if (hour < 21) return Icons.wb_twilight_rounded;
    return Icons.bedtime_rounded;
  }
}

// ─── Sync Indicator (Big Tech UX Pattern) ────────────────────────────────────

class _SyncIndicator extends StatelessWidget {
  final SyncStatus status;
  const _SyncIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == SyncStatus.idle) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getStatusColor().withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == SyncStatus.syncing)
            const SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.blue),
            )
          else
            Icon(_getStatusIcon(), size: 10, color: _getStatusColor()),
          const SizedBox(width: 4),
          Text(
            _getStatusText(),
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: _getStatusColor()),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Color _getStatusColor() {
    switch (status) {
      case SyncStatus.syncing: return Colors.blue;
      case SyncStatus.success: return AppColors.sageGreen;
      case SyncStatus.error: return Colors.red;
      case SyncStatus.offline: return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case SyncStatus.success: return Icons.check_circle_rounded;
      case SyncStatus.error: return Icons.error_rounded;
      case SyncStatus.offline: return Icons.cloud_off_rounded;
      default: return Icons.sync;
    }
  }

  String _getStatusText() {
    switch (status) {
      case SyncStatus.syncing: return 'SYNCING';
      case SyncStatus.success: return 'SAVED';
      case SyncStatus.error: return 'RETRYING';
      case SyncStatus.offline: return 'OFFLINE';
      default: return '';
    }
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int doneCount;
  final int totalCount;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
    required this.doneCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final allDone = doneCount == totalCount && totalCount > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: allDone
                  ? AppColors.sageGreen.withValues(alpha: 0.2)
                  : context.surfaceOverlay,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: allDone
                    ? AppColors.sageGreen.withValues(alpha: 0.4)
                    : context.glassBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (allDone) ...[
                  const Icon(Icons.check_rounded, size: 12, color: AppColors.sageGreenLight),
                  const SizedBox(width: 4),
                ],
                Text(
                  '$doneCount/$totalCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: allDone ? AppColors.sageGreenLight : context.textMuted,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
