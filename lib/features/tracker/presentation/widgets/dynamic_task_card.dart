import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/swipe_action.dart';
import '../../../../shared/widgets/hold_to_fill.dart';
import '../../data/models/amal_task.dart';
import '../../providers/daily_log_provider.dart';

class DynamicTaskCard extends ConsumerWidget {
  final AmalTask task;

  const DynamicTaskCard({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyLog = ref.watch(dailyLogProvider);

    if (task.inputType == TaskInputType.checkbox) {
      final isCompleted = dailyLog.getBool(task.id);
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SwipeAction(
          isCompleted: isCompleted,
          onComplete: () => ref.read(dailyLogProvider.notifier).toggleTask(task.id),
          child: GlassmorphicCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildCategoryIcon(task.category, context, isCompleted),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isCompleted ? context.textMuted : context.textPrimary,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      Text(
                        _getCategoryLabel(task.category),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  const Icon(Icons.check_circle_rounded, color: AppColors.sageGreen),
              ],
            ),
          ),
        ),
      );
    }

    if (task.inputType == TaskInputType.counter) {
      final count = dailyLog.getCounter(task.id);
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassmorphicCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildCategoryIcon(task.category, context, count >= 5),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ),
              HoldToFill(
                currentValue: count,
                maxValue: 5,
                color: _getCategoryColor(task.category),
                onValueChanged: (val) => 
                    ref.read(dailyLogProvider.notifier).updateCounter(task.id, val),
              ),
            ],
          ),
        ),
      );
    }

    // Default for numberInput or others
    return const SizedBox.shrink();
  }

  Widget _buildCategoryIcon(String category, BuildContext context, bool isActive) {
    IconData icon;
    Color color = _getCategoryColor(category);

    switch (category) {
      case 'salah': icon = Icons.mosque_rounded; break;
      case 'sunnah_salah': icon = Icons.auto_awesome_rounded; break;
      case 'zikr': icon = Icons.waves_rounded; break;
      case 'habits': icon = Icons.task_alt_rounded; break;
      case 'donts': icon = Icons.block_rounded; color = AppColors.softCoral; break;
      case 'weekly': icon = Icons.calendar_today_rounded; break;
      default: icon = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isActive ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: isActive ? color : context.textMuted, size: 20),
    );
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

  String _getCategoryLabel(String category) {
    return category.replaceAll('_', ' ').toUpperCase();
  }
}
