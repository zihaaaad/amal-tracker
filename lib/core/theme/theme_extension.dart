import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'package:amal_tracker/core/theme/theme_extension.dart';

extension ThemeContextExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  
  Color get surface => isDark ? context.surface : const Color(0xFFF5F5F5);
  Color get surfaceElevated => isDark ? context.surfaceElevated : const Color(0xFFFFFFFF);
  Color get surfaceCard => isDark ? context.surfaceCard : const Color(0xFFFFFFFF);
  Color get surfaceOverlay => isDark ? context.surfaceOverlay : const Color(0xFFE0E0E0);
  
  Color get textPrimary => isDark ? context.textPrimary : const Color(0xFF1A1A1A);
  Color get textSecondary => isDark ? context.textSecondary : const Color(0xFF5A5A50);
  Color get textMuted => isDark ? context.textMuted : const Color(0xFF8A8A7C);
  Color get textOnAccent => isDark ? context.textOnAccent : const Color(0xFFFFFFFF);
  
  Color get glassBorder => isDark ? context.glassBorder : const Color(0x1A000000);
  
  LinearGradient get cardGradient => isDark 
      ? context.cardGradient 
      : const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFFFFF), Color(0xFFF8F8F8)]);
      
  LinearGradient get completedGradient => isDark 
      ? context.completedGradient 
      : const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE8F2E9), Color(0xFFD0E5D2)]);
      
  LinearGradient get headerGradient => isDark 
      ? context.headerGradient 
      : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF5F5F5), Color(0xFFEAEAEA)]);
}
