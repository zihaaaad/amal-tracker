import 'package:flutter/material.dart';
import 'app_colors.dart';

extension ThemeContextExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  
  Color get surface => isDark ? AppColors.surface : const Color(0xFFFBFBFA);
  Color get surfaceElevated => isDark ? AppColors.surfaceElevated : const Color(0xFFFFFFFF);
  Color get surfaceCard => isDark ? AppColors.surfaceCard : const Color(0xFFFFFFFF);
  Color get surfaceOverlay => isDark ? AppColors.surfaceOverlay : const Color(0xFFF2F2EF);
  
  Color get textPrimary => isDark ? AppColors.textPrimary : const Color(0xFF0F0F0F);
  Color get textSecondary => isDark ? AppColors.textSecondary : const Color(0xFF4A4A40);
  Color get textMuted => isDark ? AppColors.textMuted : const Color(0xFF8A8A7C);
  Color get textOnAccent => isDark ? AppColors.textOnAccent : const Color(0xFFFFFFFF);
  
  Color get glassBorder => isDark ? AppColors.glassBorder : const Color(0x0F000000);

  Color get dynamicGlassBorder {
    final tint = timeTint;
    return isDark 
      ? tint.withValues(alpha: 0.12)
      : tint.withValues(alpha: 0.08);
  }
  
  /// Dynamic "Zen" tint based on time of day.
  /// Fajr/Sunrise (4-8 AM): Amber
  /// Day (8 AM - 6 PM): Sage (Standard)
  /// Evening/Night (6 PM - 4 AM): Indigo/Violet
  Color get timeTint {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 8) {
      return isDark ? const Color(0xFFD4AF37) : const Color(0xFFB8860B); // Amber/Gold
    } else if (hour >= 18 || hour < 4) {
      return isDark ? const Color(0xFF9B8FD0) : const Color(0xFF6A5ACD); // Indigo/Slate
    }
    return AppColors.sageGreen; // Standard Sage
  }

  LinearGradient get cardGradient => isDark 
      ? AppColors.cardGradient 
      : const LinearGradient(
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight, 
          colors: [Color(0xFFFFFFFF), Color(0xFFF9F9F7)],
        );
      
  LinearGradient get completedGradient => isDark 
      ? AppColors.completedGradient 
      : const LinearGradient(
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight, 
          colors: [Color(0xFFF0F7F1), Color(0xFFE2EEE3)],
        );
      
  LinearGradient get headerGradient {
    final tint = timeTint;
    return isDark 
      ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint.withValues(alpha: 0.15),
            const Color(0xFF161C17),
          ],
        )
      : LinearGradient(
          begin: Alignment.topCenter, 
          end: Alignment.bottomCenter, 
          colors: [
            tint.withValues(alpha: 0.05),
            const Color(0xFFF2F2EF),
          ],
        );
  }
}
