import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/salah_data.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';

/// A compact card for habits and misc items with tap-to-toggle.
class HabitCard extends StatelessWidget {
  final AmalItem item;
  final bool isCompleted;
  final VoidCallback onToggle;

  const HabitCard({
    super.key,
    required this.item,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      isCompleted: isCompleted,
      onTap: () {
        HapticFeedback.lightImpact();
        onToggle();
      },
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon + check
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (isCompleted
                          ? AppColors.sageGreen
                          : item.color)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.icon,
                  color: isCompleted
                      ? AppColors.sageGreenLight
                      : item.color,
                  size: 16,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: isCompleted
                    ? const Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey('done'),
                        color: AppColors.sageGreenLight,
                        size: 18,
                      )
                    : Icon(
                        Icons.radio_button_unchecked,
                        key: const ValueKey('pending'),
                        color: AppColors.textMuted,
                        size: 16,
                      ),
              ),
            ],
          ),

          const Spacer(),

          // Title
          Text(
            item.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isCompleted
                  ? AppColors.sageGreenLight
                  : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            item.subtitle,
            style: TextStyle(
              fontSize: 9,
              color: isCompleted
                  ? AppColors.sageGreen
                  : AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
