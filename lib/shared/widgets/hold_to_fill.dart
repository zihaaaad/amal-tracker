import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_extension.dart';

/// Hold-to-fill circular counter widget with enhanced interactivity.
/// User taps to increment or holds to rapidly increment with haptic feedback.
class HoldToFill extends StatefulWidget {
  final int currentValue;
  final int maxValue;
  final Color color;
  final ValueChanged<int> onValueChanged;
  final double size;

  const HoldToFill({
    super.key,
    required this.currentValue,
    required this.maxValue,
    required this.color,
    required this.onValueChanged,
    this.size = 52,
  });

  @override
  State<HoldToFill> createState() => _HoldToFillState();
}

class _HoldToFillState extends State<HoldToFill>
    with SingleTickerProviderStateMixin {
  bool _isHolding = false;
  int _displayValue = 0;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.currentValue;
  }

  @override
  void didUpdateWidget(HoldToFill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentValue != widget.currentValue) {
      _displayValue = widget.currentValue;
    }
  }

  void _startHold() {
    _isHolding = true;
    _tickCounter();
  }

  void _tickCounter() async {
    if (!_isHolding || !mounted) return;

    await Future.delayed(const Duration(milliseconds: 220)); 
    if (!_isHolding || !mounted) return;

    _increment();
    _tickCounter();
  }

  void _increment() {
    setState(() {
      if (_displayValue < widget.maxValue) {
        _displayValue++;
      } else {
        _displayValue = 0; // reset
      }
    });

    if (_displayValue == widget.maxValue) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    widget.onValueChanged(_displayValue);
  }

  void _stopHold() {
    _isHolding = false;
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.maxValue > 0 ? _displayValue / widget.maxValue : 0.0;
    final isComplete = _displayValue >= widget.maxValue;
    final activeColor = isComplete ? AppColors.sageGreen : widget.color;

    return GestureDetector(
      onLongPressStart: (_) {
        HapticFeedback.selectionClick();
        _startHold();
      },
      onLongPressEnd: (_) => _stopHold(),
      onTap: _increment,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: activeColor.withValues(alpha: 0.05),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background & Progress Arc
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return CustomPaint(
                    painter: _CounterPainter(
                      progress: value,
                      bgColor: context.glassBorder.withValues(alpha: 0.1),
                      fgColor: activeColor,
                      strokeWidth: 3.5,
                    ),
                  );
                },
              ),
            ),

            // Number with AnimatedSwitcher for a "bounce" effect on change
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: animation.drive(Tween(begin: 0.8, end: 1.0)
                      .chain(CurveTween(curve: Curves.easeOutBack))),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Text(
                '$_displayValue',
                key: ValueKey(_displayValue),
                style: TextStyle(
                  fontSize: widget.size * 0.35,
                  fontWeight: FontWeight.w800,
                  color: isComplete ? AppColors.sageGreenLight : context.textPrimary,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ).animate(target: isComplete ? 1 : 0).scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1), curve: Curves.elasticOut),
    );
  }
}

class _CounterPainter extends CustomPainter {
  final double progress;
  final Color bgColor;
  final Color fgColor;
  final double strokeWidth;

  _CounterPainter({
    required this.progress,
    required this.bgColor,
    required this.fgColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..color = fgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CounterPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.fgColor != fgColor;
  }
}
