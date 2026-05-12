import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/salah_data.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/hold_to_fill.dart';

/// A Bento card for Zikr counters with hold-to-fill interaction.
class ZikrCounterCard extends StatelessWidget {
  final AmalItem item;
  final int currentValue;
  final ValueChanged<int> onValueChanged;

  const ZikrCounterCard({
    super.key,
    required this.item,
    required this.currentValue,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = currentValue >= item.maxCount;

    return GlassmorphicCard(
      isCompleted: isComplete,
      child: Row(
        children: [
          // Left side: info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (isComplete
                            ? AppColors.sageGreen
                            : item.color)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    color: isComplete
                        ? AppColors.sageGreenLight
                        : item.color,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isComplete
                        ? AppColors.sageGreenLight
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isComplete
                      ? 'Completed!'
                      : '${item.maxCount - currentValue} remaining',
                  style: TextStyle(
                    fontSize: 11,
                    color: isComplete
                        ? AppColors.sageGreen
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Right side: circular counter
          HoldToFill(
            currentValue: currentValue,
            maxValue: item.maxCount,
            color: item.color,
            onValueChanged: onValueChanged,
            size: 56,
          ),
        ],
      ),
    );
  }
}
