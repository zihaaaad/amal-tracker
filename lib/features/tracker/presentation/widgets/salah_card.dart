import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/salah_data.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/swipe_action.dart';

/// A premium Bento-style card for Salah tracking with swipe-to-complete.
class SalahCard extends StatelessWidget {
  final AmalItem item;
  final bool isCompleted;
  final VoidCallback onToggle;

  const SalahCard({
    super.key,
    required this.item,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SwipeAction(
      isCompleted: isCompleted,
      onComplete: onToggle,
      child: GlassmorphicCard(
        isCompleted: isCompleted,
        onTap: () {
          HapticFeedback.lightImpact();
          onToggle();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top row: icon + status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isCompleted
                            ? AppColors.sageGreen
                            : item.color)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    color: isCompleted ? AppColors.sageGreenLight : item.color,
                    size: 20,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isCompleted
                      ? const Icon(
                          Icons.check_circle_rounded,
                          key: ValueKey('check'),
                          color: AppColors.sageGreenLight,
                          size: 22,
                        )
                      : Icon(
                          Icons.circle_outlined,
                          key: const ValueKey('empty'),
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                ),
              ],
            ),

            const Spacer(),

            // Bottom: title + subtitle
            Text(
              item.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isCompleted
                    ? AppColors.sageGreenLight
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isCompleted
                    ? AppColors.sageGreen
                    : AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
