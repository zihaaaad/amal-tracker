import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/database_service.dart';
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

  void _checkCelebration(double completion, int streak) {
    if (completion >= 1.0 && !_hasCelebratedToday) {
      _hasCelebratedToday = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        
        // ── Perfect Month Milestone (30 Days) ─────────────────────
        if (streak == 30) {
          HapticFeedback.heavyImpact();
          _showPerfectMonthDialog(context);
        } else {
          // Standard Daily Success Haptic Choreography
          HapticFeedback.heavyImpact();
          Future.delayed(const Duration(milliseconds: 300), () {
            HapticFeedback.mediumImpact();
          });
        }
        _confettiController.play();
      });
    } else if (completion < 1.0) {
      _hasCelebratedToday = false;
    }
  }

  void _showPerfectMonthDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.warmAmber.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stars_rounded, color: AppColors.warmAmber, size: 64),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              'Perfect Month!',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: context.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              'Ma sha Allah! You have completed 30 consecutive days of spiritual discipline.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sageGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Continue Journey', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
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
      final currentStreak = ref.read(streakProvider);
      _checkCelebration(next.calculateCompletion(tasks), currentStreak);
    });

    return Scaffold(
      backgroundColor: context.surface,
      body: SafeArea(
        child: Stack(
          children: [
            groupedTasksAsync.when(
              data: (groupedTasks) {
                return RefreshIndicator(
                  onRefresh: () async {
                    await HapticFeedback.mediumImpact();
                    await DatabaseService.instance.syncToCloud();
                    await ref.refresh(tasksProvider.future);
                  },
                  backgroundColor: context.surfaceCard,
                  color: context.timeTint,
                  child: SlidableAutoCloseBehavior(
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                                      : dailyLog.getCounter(t.id) >= (t.points > 1 ? t.points : 5))
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
                                          .fadeIn(delay: (300 + (index * 40)).ms, duration: 500.ms, curve: Curves.easeOutQuart)
                                          .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart);
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

    // Use title for relevance check since IDs are now UUIDs
    final titleSearch = task.title.toLowerCase();
    if (titleSearch.contains('fajr') && context.index > TimeContext.earlyMorning.index) return false;
    if (titleSearch.contains('morning') && context.index > TimeContext.morning.index) return false;
    if (titleSearch.contains('dhuhr') && context.index > TimeContext.afternoon.index) return false;
    if (titleSearch.contains('asr') && context.index > TimeContext.evening.index) return false;
    
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
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                    'AS-SUNNAH FOUNDATION',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: context.timeTint.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    greeting,
                    style: TextStyle(
                      fontSize: 16,
                      color: context.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (syncStatus != null) _SyncIndicator(status: syncStatus!),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dateStr,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderSubtle),
            ),
            child: Text(
              quote,
              style: TextStyle(
                fontSize: 13,
                color: context.textSecondary,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
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
