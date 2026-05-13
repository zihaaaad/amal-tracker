import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_extension.dart';

/// Simple themed card widget — no expensive BackdropFilter blur.
/// Uses gradient background with subtle border for visual depth.
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: isCompleted
              ? context.completedGradient
              : (backgroundColor != null
                  ? null
                  : context.cardGradient),
          color: backgroundColor,
          border: Border.all(
            color: isCompleted
                ? AppColors.sageGreen.withValues(alpha: 0.3)
                : (borderColor ?? context.glassBorder),
          ),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
