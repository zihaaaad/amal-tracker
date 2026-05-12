import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

/// Swipe-to-complete action wrapper.
/// Swipe right to mark as complete, with spring-back animation.
class SwipeAction extends StatefulWidget {
  final Widget child;
  final bool isCompleted;
  final VoidCallback onComplete;
  final double threshold;

  const SwipeAction({
    super.key,
    required this.child,
    required this.isCompleted,
    required this.onComplete,
    this.threshold = 0.4,
  });

  @override
  State<SwipeAction> createState() => _SwipeActionState();
}

class _SwipeActionState extends State<SwipeAction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    _isDragging = true;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || widget.isCompleted) return;
    setState(() {
      _dragExtent = max(0, _dragExtent + details.delta.dx);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging || widget.isCompleted) return;
    _isDragging = false;

    final width = context.size?.width ?? 300;
    final ratio = _dragExtent / width;

    if (ratio >= widget.threshold) {
      // Complete!
      HapticFeedback.mediumImpact();
      widget.onComplete();
    }

    // Spring back
    _controller.forward(from: 0).then((_) {
      if (mounted) setState(() => _dragExtent = 0);
      _controller.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final ratio = width > 0 ? _dragExtent / width : 0.0;
    final clampedRatio = ratio.clamp(0.0, 1.0);

    return Stack(
      children: [
        // Background reveal layer
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.sageGreen.withValues(alpha: clampedRatio * 0.6),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: clampedRatio > 0.2 ? 1.0 : 0.0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.textPrimary.withValues(alpha: clampedRatio),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Complete',
                    style: TextStyle(
                      color: AppColors.textPrimary.withValues(alpha: clampedRatio),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Main content
        GestureDetector(
          onHorizontalDragStart: widget.isCompleted ? null : _handleDragStart,
          onHorizontalDragUpdate: widget.isCompleted ? null : _handleDragUpdate,
          onHorizontalDragEnd: widget.isCompleted ? null : _handleDragEnd,
          child: AnimatedContainer(
            duration: _isDragging
                ? Duration.zero
                : const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            transform: Matrix4.translationValues(
              widget.isCompleted ? 0 : _dragExtent,
              0,
              0,
            ),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
