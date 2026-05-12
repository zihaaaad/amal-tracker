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
      
  LinearGradient get headerGradient => isDark 
      ? AppColors.headerGradient 
      : const LinearGradient(
          begin: Alignment.topCenter, 
          end: Alignment.bottomCenter, 
          colors: [Color(0xFFFBFBFA), Color(0xFFF2F2EF)],
        );
}

