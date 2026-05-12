import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_extension.dart';

/// A premium frosted-glass card with subtle border and glow effect.
/// Optimized with RepaintBoundary and conditional blur for performance.
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
    final isDark = context.isDark;
    
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: isCompleted
                ? context.completedGradient
                : (backgroundColor != null 
                    ? LinearGradient(colors: [backgroundColor!, backgroundColor!]) 
                    : context.cardGradient),
            border: Border.all(
              color: isCompleted
                  ? AppColors.sageGreen.withValues(alpha: 0.3)
                  : (borderColor ?? context.glassBorder),
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
                color: isDark 
                    ? Colors.black.withValues(alpha: 0.3) 
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: BackdropFilter(
              // Disable blur on extremely low-end or in light mode if not needed for "freshness"
              // Here we keep it but reduce intensity for a cleaner look
              filter: ImageFilter.blur(
                sigmaX: isDark ? 10 : 5, 
                sigmaY: isDark ? 10 : 5,
              ),
              child: Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

