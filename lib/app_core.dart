import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'core/constants/app_constants.dart';
import 'core/database/database_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/background_service.dart';
import 'core/services/notification_service.dart';
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
/// Handles shared initialization, routing, and state management.
class AppCore {
  static AppMode _currentMode = AppMode.client;
  static AppMode get mode => _currentMode;

  static Future<void> init(AppMode mode) async {
    _currentMode = mode;
    WidgetsFlutterBinding.ensureInitialized();

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    await Future.wait([
      _initTimezone(),
      DatabaseService.initialize(),
      _prewarmAssets(),
    ]);

    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    await NotificationService.initialize().catchError((_) {});
    await BackgroundService.initialize().catchError((_) {});
  }

  static Future<void> _prewarmAssets() async {
    TextPainter(textDirection: TextDirection.ltr).layout();
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
      title: mode == AppMode.admin ? 'Foundation Admin' : 'As-Sunnah Tracker',
      themeMode: settings.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: _AppRouter(mode: mode),
    );
  }
}

class _AppRouter extends ConsumerStatefulWidget {
  final AppMode mode;
  const _AppRouter({required this.mode});

  @override
  ConsumerState<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends ConsumerState<_AppRouter> {
  bool _ready = false;
  bool _checkingProfile = false;
  bool _profileChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  Future<void> _checkProfile() async {
    if (_checkingProfile || _profileChecked) return;
    _checkingProfile = true;
    if (mounted) setState(() {});
    
    await AuthService.instance.refreshProfile();
    _checkingProfile = false;
    _profileChecked = true;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);
    final session = ref.watch(sessionProvider);

    if (!_ready || authAsync.isLoading) {
      return const SplashScreen();
    }

    if (session != null) {
      if (!_profileChecked && !_checkingProfile) {
        _checkProfile();
        return const SplashScreen();
      }
      
      if (_checkingProfile) {
        return const SplashScreen();
      }

      if (!AuthService.instance.isProfileComplete) {
        return const OnboardingScreen();
      }

      // ── Hard Boundary Logic ────────────────────────────────────────
      if (widget.mode == AppMode.admin) {
        if (!AuthService.instance.isAdmin) {
          return const Scaffold(body: Center(child: Text('Unauthorized Access')));
        }
        return const AdminDashboardScreen();
      }

      return const MainNavigationScreen();
    }

    if (_profileChecked) {
      _profileChecked = false;
    }

    return const AuthScreen();
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
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavBarItem(
              icon: Icons.home_rounded,
              label: 'Today',
              isActive: currentIndex == 0,
              activeColor: activeColor,
              onTap: () => onTap(0),
            ),
            _NavBarItem(
              icon: Icons.bar_chart_rounded,
              label: 'Stats',
              isActive: currentIndex == 1,
              activeColor: activeColor,
              onTap: () => onTap(1),
            ),
            _NavBarItem(
              icon: Icons.settings_rounded,
              label: 'Menu',
              isActive: currentIndex == 2,
              activeColor: activeColor,
              onTap: () => onTap(2),
            ),
          ],
        ),
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
            Icon(
              icon,
              color: isActive ? activeColor : context.textMuted,
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
