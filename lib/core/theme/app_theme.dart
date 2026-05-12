import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Premium dark theme for Amal Tracker.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        textTheme: AppTypography.textTheme.apply(
          bodyColor: const Color(0xFF1A1A1A),
          displayColor: const Color(0xFF0F0F0F),
        ),
        colorScheme: const ColorScheme.light(
          surface: Color(0xFFF5F5F5),
          primary: AppColors.sageGreen,
          secondary: AppColors.warmAmber,
          tertiary: AppColors.fajrColor,
          error: AppColors.softCoral,
          onPrimary: Colors.white,
          onSurface: Color(0xFF1A1A1A),
          onSecondary: Colors.white,
          outline: Color(0x1A000000),
          surfaceContainerHighest: Color(0xFFFFFFFF),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Color(0xFFF5F5F5),
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          titleTextStyle: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
          iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFFFFFFFF),
          indicatorColor: AppColors.sageGreenSubtle,
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return const IconThemeData(color: AppColors.sageGreenDark, size: 24);
            return const IconThemeData(color: Color(0xFF8A8A7C), size: 22);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sageGreenDark);
            return const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xFF8A8A7C));
          }),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFFFF),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0x1A000000)),
          ),
          margin: EdgeInsets.zero,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1A1A1A),
          contentTextStyle: const TextStyle(color: Color(0xFFF5F5F0), fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        ),
        dividerTheme: const DividerThemeData(color: Color(0x1A000000), thickness: 1),
      );

  static ThemeData get darkTheme => ThemeData(

        // Color scheme
        colorScheme: const ColorScheme.dark(
          surface: AppColors.surface,
          primary: AppColors.sageGreen,
          secondary: AppColors.warmAmber,
          tertiary: AppColors.fajrColor,
          error: AppColors.softCoral,
          onPrimary: AppColors.textOnAccent,
          onSurface: AppColors.textPrimary,
          onSecondary: AppColors.textOnAccent,
          outline: AppColors.glassBorder,
          surfaceContainerHighest: AppColors.surfaceCard,
        ),

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: AppColors.surface,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          titleTextStyle: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),

        // Navigation bar
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surfaceElevated,
          indicatorColor: AppColors.sageGreenSubtle,
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                color: AppColors.sageGreenLight,
                size: 24,
              );
            }
            return const IconThemeData(
              color: AppColors.textMuted,
              size: 22,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.sageGreenLight,
              );
            }
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted,
            );
          }),
        ),

        // Cards
        cardTheme: CardThemeData(
          color: AppColors.surfaceCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.glassBorder),
          ),
          margin: EdgeInsets.zero,
        ),

        // Dialogs
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        // Snackbar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.surfaceOverlay,
          contentTextStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),

        // Bottom sheet
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),

        // Dividers
        dividerTheme: const DividerThemeData(
          color: AppColors.glassBorder,
          thickness: 1,
        ),
      );
}
