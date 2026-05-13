import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';

/// Animated progress ring with motivational message, streak badge, and "cool" pulsing completion effect.
class ProgressRing extends StatefulWidget {
  final double percentage;
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
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = widget.percentage >= 1.0;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulseValue = isComplete ? _pulseController.value : 0.0;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: context.cardGradient,
              border: Border.all(
                color: isComplete
                    ? AppColors.sageGreen.withValues(alpha: 0.5 + (pulseValue * 0.3))
                    : context.glassBorder,
                width: isComplete ? 1.5 : 1,
              ),
              boxShadow: [
                if (widget.percentage > 0.1)
                  BoxShadow(
                    color: _progressColor(widget.percentage).withValues(
                      alpha: isComplete 
                        ? (0.15 + (pulseValue * 0.1)) 
                        : (widget.percentage * 0.1),
                    ),
                    blurRadius: isComplete ? 30 + (pulseValue * 15) : 24,
                    spreadRadius: isComplete ? -2 + (pulseValue * 4) : -6,
                  ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: child,
          );
        },
        child: Row(
          children: [
            // ── Animated Ring ──────────────────────────────────
            SizedBox(
              width: 110,
              height: 110,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: widget.percentage),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutBack,
                builder: (context, value, _) {
                  final ringColor = _progressColor(value);
                  return CustomPaint(
                    painter: _RingPainter(
                      progress: value,
                      bgColor: context.surfaceOverlay,
                      fgColor: ringColor,
                      strokeWidth: 9,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(value * 100).round()}%',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: value >= 1.0
                                  ? AppColors.sageGreenLight
                                  : context.textPrimary,
                              height: 1,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'done',
                            style: TextStyle(
                              fontSize: 10,
                              color: context.textMuted,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 24),

            // ── Stats & Motivation ─────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: anim.drive(Tween(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeOutCubic))),
                        child: child,
                      ),
                    ),
                    child: Text(
                      _motivationalMessage(widget.percentage),
                      key: ValueKey(_motivationalMessage(widget.percentage)),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    '${widget.completedCount} of ${widget.totalCount} completed',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Streak badge
                  _StreakBadge(streak: widget.streak),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _progressColor(double value) {
    if (value >= 1.0) return AppColors.sageGreenLight;
    if (value >= 0.7) return AppColors.sageGreen;
    if (value >= 0.4) return AppColors.warmAmber;
    return AppColors.softCoral;
  }

  String _motivationalMessage(double p) {
    if (p >= 1.0) return 'MashaAllah!\nPure excellence ✨';
    if (p >= 0.8) return 'So close!\nFinish strong 💪';
    if (p >= 0.5) return 'Over halfway!\nKeep going 🚀';
    if (p >= 0.2) return "Great start!\nOne step at a time";
    return "Ready to track?\nBismillah! 🌙";
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;

  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    final active = streak > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? AppColors.warmAmber.withValues(alpha: 0.12)
            : context.surfaceOverlay.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active
              ? AppColors.warmAmber.withValues(alpha: 0.3)
              : context.glassBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.local_fire_department_rounded : Icons.auto_awesome_outlined,
            color: active ? AppColors.warmAmber : context.textMuted,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            active ? '$streak Day Streak' : 'Fresh Start',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: active ? AppColors.warmAmberLight : context.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color bgColor;
  final Color fgColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.bgColor,
    required this.fgColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;

    // BG Circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      // Progress Arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = fgColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      
      // Glow dots on ends for "cool" factor
      if (progress < 0.99) {
        final endAngle = -pi / 2 + (2 * pi * progress);
        final dotX = center.dx + radius * cos(endAngle);
        final dotY = center.dy + radius * sin(endAngle);
        
        canvas.drawCircle(
          Offset(dotX, dotY),
          strokeWidth * 0.5,
          Paint()..color = fgColor.withValues(alpha: 0.8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.fgColor != fgColor;
  }
}
