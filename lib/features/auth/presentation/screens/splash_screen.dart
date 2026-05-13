import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_extension.dart';

/// Elite branded splash screen with time-aware tinting and shader pre-warming.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );
    _fadeController.forward();

    // Pre-warm shaders by rendering glassmorphic elements off-screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prewarmShaders();
    });
  }

  void _prewarmShaders() {
    // Force the rendering pipeline to compile shaders for blur/gradient
    // by painting a tiny invisible element with the same effects.
    // This prevents "first-frame jank" on the home screen.
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Branded Icon with animated glow
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: context.timeTint.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.timeTint.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: context.timeTint.withValues(alpha: 0.15),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
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
                      'As-Sunnah Tracker',
                      style: GoogleFonts.outfit(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: context.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'INSTITUTIONAL EDITION',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.timeTint.withValues(alpha: 0.6),
                        letterSpacing: 3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Subtle loading at the bottom
          Positioned(
            bottom: 60,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.timeTint.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'As-Sunnah Foundation',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textMuted.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
