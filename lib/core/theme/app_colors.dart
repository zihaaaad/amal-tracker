import 'package:flutter/material.dart';

/// Premium Zen color palette for Amal Tracker.
/// Inspired by Japanese minimalism and Islamic geometric art.
class AppColors {
  AppColors._();

  // ─── Core Surfaces ─────────────────────────────────
  static const Color surface = Color(0xFF0F0F0F);
  static const Color surfaceElevated = Color(0xFF1A1A1A);
  static const Color surfaceCard = Color(0xFF1E1E1E);
  static const Color surfaceOverlay = Color(0xFF242424);

  // ─── Primary: Sage Green (Completion) ──────────────
  static const Color sageGreen = Color(0xFF7A907C);
  static const Color sageGreenLight = Color(0xFFA8C4AA);
  static const Color sageGreenDark = Color(0xFF5A6E5C);
  static const Color sageGreenSubtle = Color(0x337A907C);

  // ─── Accent: Warm Amber (Streaks/Achievements) ────
  static const Color warmAmber = Color(0xFFD4A574);
  static const Color warmAmberLight = Color(0xFFE8C49A);
  static const Color warmAmberDark = Color(0xFFB88A5C);

  // ─── Alert: Soft Coral (Missed/Incomplete) ────────
  static const Color softCoral = Color(0xFFC17C74);
  static const Color softCoralLight = Color(0xFFD4A09A);
  static const Color softCoralDark = Color(0xFF9E5E56);

  // ─── Text ──────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF5F5F0);
  static const Color textSecondary = Color(0xFF8A8A7C);
  static const Color textMuted = Color(0xFF5A5A50);
  static const Color textOnAccent = Color(0xFF0F0F0F);

  // ─── Glassmorphism ────────────────────────────────
  static const Color glassBorder = Color(0x14FFFFFF);
  static const Color glassHighlight = Color(0x0AFFFFFF);
  static const Color glassShadow = Color(0x40000000);

  // ─── Salah-Specific Colors ────────────────────────
  static const Color fajrColor = Color(0xFF6B7FA3);       // Steel blue dawn
  static const Color dhuhrColor = Color(0xFFD4A574);       // Warm amber noon
  static const Color asrColor = Color(0xFFC4A066);         // Golden afternoon
  static const Color maghribColor = Color(0xFFC17C74);     // Coral sunset
  static const Color ishaColor = Color(0xFF6B6B8A);        // Twilight indigo

  // ─── Category Colors ──────────────────────────────
  static const Color categoryPrayer = Color(0xFF7A907C);
  static const Color categoryZikr = Color(0xFF6B7FA3);
  static const Color categoryHabit = Color(0xFFD4A574);
  static const Color categoryDont = Color(0xFFC17C74);
  static const Color categoryWeekly = Color(0xFF8A7FA3);
  static const Color categoryMonthly = Color(0xFF7A9A8A);

  // ─── Gradients ────────────────────────────────────
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1E1E), Color(0xFF161616)],
  );

  static const LinearGradient completedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A3F2C), Color(0xFF1E2E1F)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
  );

  static const LinearGradient progressGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sageGreen, sageGreenLight],
  );
}
