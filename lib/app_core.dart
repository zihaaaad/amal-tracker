import 'dart:async';
import 'dart:ui' as ui;

import 'package:app_links/app_links.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'core/constants/app_constants.dart';
import 'core/database/database_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/background_service.dart';
import 'core/services/logger_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_extension.dart';
import 'features/admin/presentation/screens/admin_task_screen.dart';
import 'features/analytics/presentation/screens/analytics_screen.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/auth/presentation/screens/onboarding_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/tracker/presentation/screens/home_screen.dart';

enum AppMode { client, admin }

/// Big Tech Architecture: Centralized Application Core.
class AppCore {
  static AppMode _currentMode = AppMode.client;
  static AppMode get mode => _currentMode;

  static Future<void> init(AppMode mode) async {
    _currentMode = mode;
    
    LoggerService.init();
    LoggerService.info('App Kernel: Booting in ${mode.name} mode...');

    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // 1. Backend Connectivity (CRITICAL - Prioritize Deep Link Capture)
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
        debug: true, // Enable verbose logging for auth troubleshooting
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      ).timeout(const Duration(seconds: 15));

      // Debug: Aggressive Auth State Monitoring
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        LoggerService.info('Core Auth State Change: ${data.event} (Session: ${data.session != null})');
      });

      // 2. Multi-Target Localization
      await EasyLocalization.ensureInitialized();

      // 3. System Components
      await Future.wait([
        _initTimezone(),
        DatabaseService.initialize(),
        _initFirebase(),
        _prewarmAssets(),
      ]).catchError((e) {
        LoggerService.warning('Non-critical initialization warning: $e');
        return [];
      });

      await NotificationService.initialize().catchError((_) {});
      await BackgroundService.initialize().catchError((_) {});

      // 4. Deep Link Handler — Critical for OAuth PKCE flow completion
      _initDeepLinkHandler();

    } catch (e) {
      LoggerService.error('Global init error', e);
    }
  }

  static StreamSubscription? _deepLinkSub;

  /// Listens for incoming deep links (OAuth callbacks) and exchanges the
  /// PKCE authorization code for a session. Without this, Google sign-in
  /// opens the browser but the app never receives the session back.
  static void _initDeepLinkHandler() {
    final appLinks = AppLinks();

    // Handle link that launched the app (cold start)
    appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    }).catchError((e) {
      LoggerService.warning('Initial deep link error: $e');
    });

    // Handle links while the app is running (warm resume from browser)
    _deepLinkSub?.cancel();
    _deepLinkSub = appLinks.uriLinkStream.listen(
      (uri) => _handleDeepLink(uri),
      onError: (e) => LoggerService.warning('Deep link stream error: $e'),
    );
  }

  static Future<void> _handleDeepLink(Uri uri) async {
    LoggerService.info('Deep Link Received: $uri');

    // Only process our auth callback URLs
    final uriStr = uri.toString();
    if (!uriStr.startsWith('com.amaltracker.auth://callback') &&
        !uriStr.startsWith('com.amaltracker.admin.auth://callback')) {
      return;
    }

    try {
      // Exchange the PKCE authorization code for a session
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
      LoggerService.info('OAuth session established successfully!');
    } catch (e) {
      LoggerService.error('Failed to exchange OAuth code for session', e);
    }
  }

  static Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp();
      await PushNotificationService.initialize();
      await PushNotificationService.subscribeToTopic('global_announcements');
    } catch (e) {
      LoggerService.warning('Firebase skipped: $e');
    }
  }

  static Future<void> _prewarmAssets() async {
    TextPainter(textDirection: ui.TextDirection.ltr).layout();
    try {
      await GoogleFonts.pendingFonts([GoogleFonts.outfit()]);
    } catch (_) {}
  }

  static Future<void> _initTimezone() async {
    tz.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name.toString()));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }
}

class AmalTrackerApp extends ConsumerWidget {
  final AppMode mode;
  const AmalTrackerApp({super.key, required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: mode == AppMode.admin ? 'Foundation Admin' : 'app_title'.tr(),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      themeMode: settings.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: _AppRouter(mode: mode),
    );
  }
}

class _AppRouter extends ConsumerWidget {
  final AppMode mode;
  const _AppRouter({required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final authAsync = ref.watch(authStateProvider);
    final profileAsync = ref.watch(profileProvider);

    // Initial Loading State
    if (authAsync.isLoading || (session != null && profileAsync.isLoading && !profileAsync.hasValue)) {
      return const SplashScreen();
    }

    // ── Routing Decision Tree ─────────────────────────────────────
    if (session != null) {
      final profile = profileAsync.value;
      
      // If profile is still null after loading, it means it doesn't exist yet -> Onboarding
      if (profile == null || profile['is_profile_complete'] != true) {
        return const OnboardingScreen();
      }

      if (mode == AppMode.admin) {
        final role = profile['role'];
        final isAdmin = role == 'admin' || role == 'manager';
        if (!isAdmin) {
          return const _UnauthorizedScreen();
        }
        return const AdminDashboardScreen();
      }

      return const MainNavigationScreen();
    }

    return const AuthScreen();
  }
}

class _UnauthorizedScreen extends StatelessWidget {
  const _UnauthorizedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.gpp_bad_rounded, size: 64, color: context.softCoral),
              const SizedBox(height: 24),
              Text('Unauthorized Access', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('This target requires Admin privileges.', textAlign: TextAlign.center),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => AuthService.instance.signOut(),
                  child: const Text('Sign Out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    AuthService.instance.refreshProfile().then((_) {
      if (mounted) setState(() {});
    });
  }

  static const _screens = [
    HomeScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOutQuart,
        switchOutCurve: Curves.easeInQuart,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation.drive(Tween(begin: 0.98, end: 1.0).chain(CurveTween(curve: Curves.easeOutQuart))),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activeColor = context.timeTint;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: context.surfaceCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: context.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavBarItem(icon: Icons.home_rounded, label: 'Today', isActive: currentIndex == 0, activeColor: activeColor, onTap: () => onTap(0)),
          _NavBarItem(icon: Icons.bar_chart_rounded, label: 'Stats', isActive: currentIndex == 1, activeColor: activeColor, onTap: () => onTap(1)),
          _NavBarItem(icon: Icons.settings_rounded, label: 'Menu', isActive: currentIndex == 2, activeColor: activeColor, onTap: () => onTap(2)),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? activeColor : context.textMuted, size: 24),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: activeColor, fontWeight: FontWeight.w800, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
