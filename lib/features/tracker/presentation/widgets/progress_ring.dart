import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Circular progress ring showing daily completion percentage.
class ProgressRing extends StatelessWidget {
  final double percentage; // 0.0 to 1.0
  final int completedCount;
  final int totalCount;
  final int streak;

  const ProgressRing({
    super.key,
    required this.percentage,
    required this.completedCount,
    required this.totalCount,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppColors.cardGradient,
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.sageGreen.withValues(alpha: percentage * 0.15),
            blurRadius: 30,
            spreadRadius: -10,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 90,
            height: 90,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percentage),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return CustomPaint(
                  painter: _ProgressRingPainter(
                    progress: value,
                    backgroundColor: AppColors.surfaceOverlay,
                    progressColor: _getProgressColor(value),
                    strokeWidth: 6,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(value * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'done',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 20),

          // Stats column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Today\'s Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completedCount of $totalCount completed',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                // Streak badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: streak > 0
                        ? AppColors.warmAmber.withValues(alpha: 0.15)
                        : AppColors.surfaceOverlay,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: streak > 0
                          ? AppColors.warmAmber.withValues(alpha: 0.3)
                          : AppColors.glassBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        streak > 0
                            ? Icons.local_fire_department_rounded
                            : Icons.emoji_events_outlined,
                        color: streak > 0
                            ? AppColors.warmAmber
                            : AppColors.textMuted,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        streak > 0
                            ? '$streak day streak'
                            : 'Start your streak',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: streak > 0
                              ? AppColors.warmAmberLight
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double value) {
    if (value >= 0.8) return AppColors.sageGreenLight;
    if (value >= 0.5) return AppColors.sageGreen;
    if (value >= 0.3) return AppColors.warmAmber;
    return AppColors.softCoral;
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) / 2) - strokeWidth;

    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
