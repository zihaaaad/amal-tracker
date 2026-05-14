import 'package:flutter/material.dart';

/// Ultra-Premium 'Big Tech' Color Palette for Amal Tracker.
/// Engineered for high contrast, OLED efficiency, and vibrant engagement.
class AppColors {
  AppColors._();

  // ─── Core Surfaces (OLED Optimized) ────────────────
  static const Color surface = Color(0xFF000000); // True OLED Black
  static const Color surfaceElevated = Color(0xFF0A0A0A);
  static const Color surfaceCard = Color(0xFF121212);
  static const Color surfaceOverlay = Color(0xFF1E1E1E);

  // ─── Primary: Electric Emerald (Completion) ────────
  static const Color sageGreen = Color(0xFF10B981); // Vibrant Emerald
  static const Color sageGreenLight = Color(0xFF34D399);
  static const Color sageGreenDark = Color(0xFF059669);
  static const Color sageGreenSubtle = Color(0x2610B981);

  // ─── Accent: Cyber Gold (Streaks/Achievements) ────
  static const Color warmAmber = Color(0xFFF59E0B);
  static const Color warmAmberLight = Color(0xFFFCD34D);
  static const Color warmAmberDark = Color(0xFFD97706);

  // ─── Alert: Neon Rose (Missed/Incomplete) ────────
  static const Color softCoral = Color(0xFFF43F5E);
  static const Color softCoralLight = Color(0xFFFB7185);
  static const Color softCoralDark = Color(0xFFE11D48);

  // ─── Text (High Readability) ─────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure White
  static const Color textSecondary = Color(0xFFA1A1AA); // Crisp Silver
  static const Color textMuted = Color(0xFF52525B); // Deep Zinc
  static const Color textOnAccent = Color(0xFF000000);

  // ─── Structural Elements ─────────────────────────
  static const Color glassBorder = Color(0x1AFFFFFF); // Subtle crisp border
  static const Color glassHighlight = Color(0x0CFFFFFF);
  static const Color glassShadow = Color(0x80000000);

  // ─── Salah-Specific Colors (Vibrant Palette) ─────
  static const Color fajrColor = Color(0xFF3B82F6);       // Electric Blue
  static const Color dhuhrColor = Color(0xFFF59E0B);      // Cyber Gold
  static const Color asrColor = Color(0xFFF97316);        // Sunset Orange
  static const Color maghribColor = Color(0xFFEC4899);    // Neon Pink
  static const Color ishaColor = Color(0xFF8B5CF6);       // Deep Purple

  // ─── Category Colors ──────────────────────────────
  static const Color categoryPrayer = Color(0xFF10B981);
  static const Color categoryZikr = Color(0xFF3B82F6);
  static const Color categoryHabit = Color(0xFFF59E0B);
  static const Color categoryDont = Color(0xFFF43F5E);
  static const Color categoryWeekly = Color(0xFF8B5CF6);
  static const Color categoryMonthly = Color(0xFF06B6D4); // Cyan

  // ─── Modern Gradients ─────────────────────────────
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF18181B), Color(0xFF09090B)], // Zinc 900 to 950
  );

  static const LinearGradient completedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF064E3B), Color(0xFF022C22)], // Emerald 900 to 950
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0A0A), Color(0xFF000000)],
  );

  static const LinearGradient progressGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sageGreen, sageGreenLight],
  );
}
