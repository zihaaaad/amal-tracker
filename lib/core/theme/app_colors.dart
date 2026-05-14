import 'package:flutter/material.dart';

/// Professional 'Modern-Classic' Color Palette for As-Sunnah Foundation.
/// Stripping away 'AI-generated' vibrancy for a more grounded, institutional feel.
class AppColors {
  AppColors._();

  // ─── Core Surfaces (Layered Depth) ────────────────
  static const Color surface = Color(0xFFFAFAFA); // Paper White
  static const Color surfaceSecondary = Color(0xFFF1F5F9); // Slate 100
  static const Color surfaceCard = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceElevated = Color(0xFFF8FAFC); // Slate 50
  
  // Dark Mode Core
  static const Color darkSurface = Color(0xFF0F172A); // Slate 900
  static const Color darkSurfaceSecondary = Color(0xFF1E293B); // Slate 800
  static const Color darkSurfaceCard = Color(0xFF1E293B);
  static const Color darkSurfaceElevated = Color(0xFF334155);

  // ─── Primary: Institutional Green (The Foundation's Identity) ──
  static const Color sageGreen = Color(0xFF2D5A27); // Deep Forest Green
  static const Color sageGreenLight = Color(0xFF4C7C45);
  static const Color sageGreenDark = Color(0xFF1B3B18);
  static const Color sageGreenSubtle = Color(0x1A2D5A27);

  // ─── Accents: Grounded Tones ──────────────────────
  static const Color warmAmber = Color(0xFFB45309); // Burnt Orange
  static const Color softCoral = Color(0xFF9F1239); // Deep Rose
  static const Color slateBlue = Color(0xFF334155); // Professional Slate

  // ─── Text (Type-First Hierarchy) ──────────────────
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  
  // Dark Mode Text
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF64748B);

  // ─── Borders & Dividers ──────────────────────────
  static const Color borderSubtle = Color(0xFFE2E8F0); // Slate 200
  static const Color darkBorderSubtle = Color(0xFF334155); // Slate 700

  // ─── Salah Colors (Sophisticated Palette) ─────────
  static const Color fajrColor = Color(0xFF1E40AF); // Deep Indigo
  static const Color dhuhrColor = Color(0xFFB45309); // Burnt Orange
  static const Color asrColor = Color(0xFF92400E); // Brown Orange
  static const Color maghribColor = Color(0xFF7C3AED); // Soft Purple
  static const Color ishaColor = Color(0xFF1E293B); // Deep Navy

  // ─── Modern Glassmorphic Shaders ──────────────────
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassHighlight = Color(0x1AFFFFFF);
}
