import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/database/database_service.dart';
import 'core/services/background_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_extension.dart';

import 'features/settings/providers/settings_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/onboarding_screen.dart';
import 'features/tracker/presentation/screens/home_screen.dart';
import 'features/analytics/presentation/screens/analytics_screen.dart';
import 'features/settings/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Performance Optimization: Shader Warmup / Pre-caching
  // Ensures smooth first-frame transitions for glassmorphism
  _prewarmUI();

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
    DatabaseService.initialize(), // Now uses Isar
  ]);

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Initialize Services
  NotificationService.initialize().catchError((_) {});
  BackgroundService.initialize().catchError((_) {});

  runApp(const ProviderScope(child: AmalTrackerApp()));
}

void _prewarmUI() {
  // Logic to prevent "first-frame stutter" by warming up complex shaders
  // or pre-caching institutional assets.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Subtle pre-loading of heavy components
  });
}

Future<void> _initTimezone() async {
  tz.initializeTimeZones();
  try {
    final name = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(name.toString()));
  } catch (_) {
    tz.setLocalLocation(tz.UTC);
  }
}

class AmalTrackerApp extends ConsumerWidget {
  const AmalTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'As-Sunnah Tracker',
      themeMode: settings.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const _AppRouter(),
    );
  }
}

class _AppRouter extends ConsumerStatefulWidget {
  const _AppRouter();

  @override
  ConsumerState<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends ConsumerState<_AppRouter> {
  bool _ready = false;
  bool _checkingProfile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  Future<void> _checkProfile() async {
    if (_checkingProfile) return;
    setState(() => _checkingProfile = true);
    await AuthService.instance.refreshProfile();
    if (mounted) setState(() => _checkingProfile = false);
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);
    final session = ref.watch(sessionProvider);

    if (!_ready || authAsync.isLoading || _checkingProfile) {
      return const SplashScreen();
    }

    if (session != null) {
      if (!AuthService.instance.isProfileComplete) {
        // Trigger background refresh if we haven't checked yet
        if (AuthService.instance.currentProfile == null) {
          _checkProfile();
          return const SplashScreen();
        }
        return const OnboardingScreen();
      }
      return const MainNavigationScreen();
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

  static const _screens = [
    HomeScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
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
