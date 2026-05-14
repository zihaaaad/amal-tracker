import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

extension ThemeContextExtension on BuildContext {
  // ─── Semantic Theme Properties ───────────────────
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get surface => isDark ? AppColors.darkSurface : AppColors.surface;
  Color get surfaceSecondary => isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary;
  Color get surfaceCard => isDark ? AppColors.darkSurfaceCard : AppColors.surfaceCard;
  Color get surfaceElevated => isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceElevated;
  
  Color get textPrimary => isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get textSecondary => isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get textMuted => isDark ? AppColors.darkTextMuted : AppColors.textMuted;
  
  Color get borderSubtle => isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle;

  // ─── Dynamic Interaction Colors ──────────────────
  Color get timeTint => AppColors.sageGreen;
  Color get softCoral => AppColors.softCoral;
  Color get warmAmber => AppColors.warmAmber;
  
  Color get dynamicGlassBorder => isDark 
      ? Colors.white.withValues(alpha: 0.08) 
      : Colors.black.withValues(alpha: 0.05);

  Color get glassBorder => isDark 
      ? Colors.white.withValues(alpha: 0.12) 
      : Colors.black.withValues(alpha: 0.08);

  Color get surfaceOverlay => isDark 
      ? Colors.white.withValues(alpha: 0.05) 
      : Colors.black.withValues(alpha: 0.02);

  // ─── Institutional Shaders (Compatibility) ───────
  LinearGradient get headerGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: isDark 
        ? [AppColors.darkSurface, AppColors.darkSurfaceSecondary]
        : [Colors.white, AppColors.surfaceSecondary],
  );

  LinearGradient get cardGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: isDark 
        ? [AppColors.darkSurfaceCard, AppColors.darkSurfaceSecondary]
        : [AppColors.surfaceCard, AppColors.surfaceSecondary],
  );

  LinearGradient get completedGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: isDark 
        ? [AppColors.sageGreenDark.withValues(alpha: 0.2), AppColors.sageGreen.withValues(alpha: 0.1)]
        : [AppColors.sageGreenSubtle, Colors.white],
  );
}
