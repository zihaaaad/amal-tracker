import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Simple branded splash screen — no unnecessary animations.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.sageGreen.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 40,
                color: AppColors.sageGreenLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Amal Tracker',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.sageGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
