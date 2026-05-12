import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Premium dark theme for Amal Tracker.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.surface,
        textTheme: AppTypography.textTheme,

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
