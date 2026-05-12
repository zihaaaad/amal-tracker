import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';

/// Premium branded splash screen shown during app initialization.
/// Covers the async startup gap (timezone + DB + Supabase init).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.headerGradient,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing icon
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceCard,
                      border: Border.all(
                        color: AppColors.sageGreen.withValues(
                          alpha: 0.3 + (_pulseController.value * 0.4),
                        ),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sageGreen.withValues(
                            alpha: 0.1 + (_pulseController.value * 0.2),
                          ),
                          blurRadius: 40 + (_pulseController.value * 20),
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 48,
                  color: AppColors.sageGreenLight,
                ),
              )
                  .animate()
                  .scale(duration: 700.ms, curve: Curves.easeOutBack)
                  .fadeIn(duration: 500.ms),

              const SizedBox(height: 32),

              // App name
              const Text(
                'Amal Tracker',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -1.0,
                ),
              ).animate().fadeIn(delay: 300.ms).moveY(begin: 16, end: 0, duration: 500.ms),

              const SizedBox(height: 8),

              // Tagline
              const Text(
                'Your Daily Amal Companion',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 64),

              // Loading indicator
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.sageGreen.withValues(alpha: 0.6),
                ),
              ).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }
}
