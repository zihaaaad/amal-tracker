import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primaryColor = AppColors.sageGreen;
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      
      // ─── Typography (Type-First Hierarchy) ──────────
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        displayColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),

      // ─── Color Scheme ──────────────────────────────
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        primary: primaryColor,
        surface: isDark ? AppColors.darkSurface : AppColors.surface,
        onSurface: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),

      // ─── AppBar ────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
      ),

      // ─── Cards (Bespoke Professional Layering) ──────
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkSurfaceCard : AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
            width: 1,
          ),
        ),
      ),

      // ─── Buttons ───────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),

      // ─── Inputs ────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(18),
        hintStyle: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
      ),
    );
  }
}
