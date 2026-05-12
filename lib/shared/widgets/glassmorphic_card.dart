import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A premium frosted-glass card with subtle border and glow effect.
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool isCompleted;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: isCompleted
              ? AppColors.completedGradient
              : AppColors.cardGradient,
          border: Border.all(
            color: isCompleted
                ? AppColors.sageGreen.withValues(alpha: 0.3)
                : (borderColor ?? AppColors.glassBorder),
            width: 1,
          ),
          boxShadow: [
            if (isCompleted)
              BoxShadow(
                color: AppColors.sageGreen.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
