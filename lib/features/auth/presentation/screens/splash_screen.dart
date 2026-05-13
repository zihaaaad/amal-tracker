import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_extension.dart';

/// Elite branded splash screen with time-aware tinting.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Branded Icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: context.timeTint.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.timeTint.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 44,
                    color: context.timeTint,
                  ),
                ),
                const SizedBox(height: 32),
                // App Name
                Text(
                  'Amal Tracker',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: context.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Spiritual Excellence',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.textMuted,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Subtle loading at the bottom
          Positioned(
            bottom: 60,
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.timeTint.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
