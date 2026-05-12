import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_extension.dart';

/// Hold-to-fill circular counter widget.
/// User taps and holds to increment the counter with haptic feedback.
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
    this.size = 64,
  });

  @override
  State<HoldToFill> createState() => _HoldToFillState();
}

class _HoldToFillState extends State<HoldToFill>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isHolding = false;
  int _displayValue = 0;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.currentValue;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void didUpdateWidget(HoldToFill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentValue != widget.currentValue) {
      _displayValue = widget.currentValue;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _startHold() {
    _isHolding = true;
    _tickCounter();
  }

  void _tickCounter() async {
    if (!_isHolding || !mounted) return;

    await Future.delayed(const Duration(milliseconds: 400));
    if (!_isHolding || !mounted) return;

    setState(() {
      if (_displayValue < widget.maxValue) {
        _displayValue++;
      } else {
        _displayValue = 0; // reset
      }
    });

    // Premium haptics: heavy impact on completion, selection click otherwise
    if (_displayValue == widget.maxValue) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    widget.onValueChanged(_displayValue);

    _animController.forward(from: 0);
    _tickCounter(); // recursive
  }

  void _stopHold() {
    _isHolding = false;
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.maxValue > 0
        ? _displayValue / widget.maxValue
        : 0.0;
    final isComplete = _displayValue >= widget.maxValue;

    return GestureDetector(
      onLongPressStart: (_) => _startHold(),
      onLongPressEnd: (_) => _stopHold(),
      onTap: () {
        // Single tap increments by 1
        setState(() {
          if (_displayValue < widget.maxValue) {
            _displayValue++;
          } else {
            _displayValue = 0;
          }
        });
        // Premium haptics
        if (_displayValue == widget.maxValue) {
          HapticFeedback.heavyImpact();
        } else {
          HapticFeedback.selectionClick();
        }
        widget.onValueChanged(_displayValue);
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 3,
                color: context.surfaceOverlay,
                strokeCap: StrokeCap.round,
              ),
            ),

            // Progress arc
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: widget.size,
              height: widget.size,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return CustomPaint(
                    painter: _ArcPainter(
                      progress: value,
                      color: isComplete
                          ? AppColors.sageGreen
                          : widget.color,
                      strokeWidth: 3,
                    ),
                  );
                },
              ),
            ),

            // Counter text
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: widget.size * 0.28,
                fontWeight: FontWeight.w700,
                color: isComplete
                    ? AppColors.sageGreenLight
                    : context.textPrimary,
              ),
              child: Text('$_displayValue'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the progress arc.
class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) / 2) - strokeWidth;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,          // start from top
      2 * pi * progress, // sweep angle
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
