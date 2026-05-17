import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../shared/widgets/hold_to_fill.dart';
import '../../data/models/amal_task.dart';
import '../../providers/daily_log_provider.dart';

class DynamicTaskCard extends ConsumerWidget {
  final AmalTask task;

  const DynamicTaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyLog = ref.watch(dailyLogProvider);

    if (task.inputType == TaskInputType.checkbox) {
      final isCompleted = dailyLog.getBool(task.id);
      return _CheckboxTaskCard(task: task, isCompleted: isCompleted);
    }

    if (task.inputType == TaskInputType.counter) {
      final count = dailyLog.getCounter(task.id);
      return _CounterTaskCard(task: task, count: count);
    }

    return const SizedBox.shrink();
  }
}

// ─── Checkbox Task Card ──────────────────────────────────────────────────────

class _CheckboxTaskCard extends ConsumerStatefulWidget {
  final AmalTask task;
  final bool isCompleted;

  const _CheckboxTaskCard({required this.task, required this.isCompleted});

  @override
  ConsumerState<_CheckboxTaskCard> createState() => _CheckboxTaskCardState();
}

class _CheckboxTaskCardState extends ConsumerState<_CheckboxTaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final isGoingToComplete = !widget.isCompleted;
    if (isGoingToComplete) {
      await HapticFeedback.mediumImpact();
    } else {
      await HapticFeedback.lightImpact();
    }
    unawaited(_controller.forward().then((_) => _controller.reverse()));
    await ref.read(dailyLogProvider.notifier).toggleTask(widget.task.id);
  }

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(widget.task.category);
    final isCompleted = widget.isCompleted;

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Slidable(
          key: ValueKey(widget.task.id),
          endActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: 0.22,
            children: [
              SlidableAction(
                onPressed: (_) async {
                  await HapticFeedback.selectionClick();
                  await ref.read(dailyLogProvider.notifier).toggleTask(widget.task.id);
                },


                backgroundColor: Colors.transparent,
                foregroundColor: isCompleted ? AppColors.softCoral : AppColors.sageGreen,
                icon: isCompleted ? Icons.close_rounded : Icons.check_rounded,
                label: isCompleted ? 'Undo' : 'Done',
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
              ),
            ],
          ),
          child: ScaleTransition(
            scale: _scaleAnim,
            child: GestureDetector(
              onTapDown: (_) {
                 HapticFeedback.selectionClick();
              },
              onTapUp: (_) async {
                await _toggle();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutQuart,
                decoration: BoxDecoration(
                  color: isCompleted ? context.surfaceSecondary : context.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCompleted ? context.timeTint.withValues(alpha: 0.1) : context.borderSubtle,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? context.timeTint.withValues(alpha: 0.1)
                              : color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _categoryIcon(widget.task.category),
                          size: 18,
                          color: isCompleted ? context.timeTint : color,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isCompleted ? context.textMuted : context.textPrimary,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                decorationColor: context.textMuted,
                                letterSpacing: -0.2,
                              ),
                              child: Text(widget.task.title),
                            ),
                            if (widget.task.category.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                _categoryLabel(widget.task.category).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: context.textMuted,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) => ScaleTransition(
                          scale: animation,
                          child: FadeTransition(opacity: animation, child: child),
                        ),
                        child: isCompleted
                            ? Container(
                                key: const ValueKey('checked'),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: context.timeTint,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              )
                            : Container(
                                key: const ValueKey('unchecked'),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: context.borderSubtle,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate(target: isCompleted ? 1 : 0).shimmer(duration: 1200.ms, color: AppColors.sageGreen.withValues(alpha: 0.1)),
          ),
        ),
      ),
    );
  }
}

// ─── Counter Task Card ───────────────────────────────────────────────────────

class _CounterTaskCard extends ConsumerWidget {
  final AmalTask task;
  final int count;

  const _CounterTaskCard({required this.task, required this.count});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _categoryColor(task.category);
    // Derive max from task points — tasks with higher points (e.g. Sunnah 12) use their own threshold
    final maxVal = task.points > 1 ? task.points : 5;
    final isDone = count >= maxVal;

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isDone
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.sageGreen.withValues(alpha: 0.18),
                      AppColors.sageGreenDark.withValues(alpha: 0.08),
                    ],
                  )
                : LinearGradient(
                    colors: [context.surfaceCard, context.surfaceCard],
                  ),
            border: Border(
              left: BorderSide(
                color: isDone ? AppColors.sageGreen : color,
                width: 3,
              ),
            top: BorderSide(color: context.dynamicGlassBorder),
            right: BorderSide(color: context.dynamicGlassBorder),
            bottom: BorderSide(color: context.dynamicGlassBorder),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.sageGreen.withValues(alpha: 0.2)
                        : color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _categoryIcon(task.category),
                    size: 18,
                    color: isDone ? AppColors.sageGreenLight : color,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDone ? context.textMuted : context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: count / maxVal),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return LinearProgressIndicator(
                              value: value,
                              minHeight: 4,
                              backgroundColor: context.surfaceOverlay,
                              color: isDone ? AppColors.sageGreenLight : color,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$count / $maxVal',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                HoldToFill(
                  currentValue: count,
                  maxValue: maxVal,
                  color: isDone ? AppColors.sageGreen : color,
                  onValueChanged: (val) async =>
                      await ref.read(dailyLogProvider.notifier).updateCounter(task.id, val),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared Helpers ──────────────────────────────────────────────────────────

Color _categoryColor(String category) {
  switch (category) {
    case 'salah': return const Color(0xFF6B9BD2);
    case 'sunnah_salah': return const Color(0xFF9B8FD0);
    case 'zikr': return AppColors.sageGreen;
    case 'habits': return AppColors.warmAmber;
    case 'donts': return AppColors.softCoral;
    case 'weekly': return const Color(0xFF8A7FA3);
    case 'monthly': return AppColors.sageGreenDark;
    default: return AppColors.sageGreen;
  }
}

IconData _categoryIcon(String category) {
  switch (category) {
    case 'salah': return Icons.mosque_rounded;
    case 'sunnah_salah': return Icons.auto_awesome_rounded;
    case 'zikr': return Icons.waves_rounded;
    case 'habits': return Icons.task_alt_rounded;
    case 'donts': return Icons.shield_outlined;
    case 'weekly': return Icons.calendar_today_rounded;
    case 'monthly': return Icons.calendar_month_rounded;
    default: return Icons.check_circle_outline_rounded;
  }
}

String _categoryLabel(String category) {
  switch (category) {
    case 'salah': return 'Prayer';
    case 'sunnah_salah': return 'Sunnah';
    case 'zikr': return 'Zikr';
    case 'habits': return 'Habit';
    case 'donts': return 'Avoid';
    case 'weekly': return 'Weekly';
    case 'monthly': return 'Monthly';
    default: return category;
  }
}
