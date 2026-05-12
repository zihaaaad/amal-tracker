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
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';

import 'features/settings/providers/settings_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/tracker/presentation/screens/home_screen.dart';
import 'features/analytics/presentation/screens/analytics_screen.dart';
import 'features/settings/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait lock
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Prevent white flash before Flutter draws
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Parallel init: timezone + local DB (no network needed)
  await Future.wait([
    _initTimezone(),
    DatabaseService.initialize(),
  ]);

  // Supabase init (network optional — gracefully handles offline)
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Non-critical services in parallel
  unawaited(Future.wait([
    NotificationService.initialize(),
    BackgroundService.initialize(),
  ]));

  runApp(const ProviderScope(child: AmalTrackerApp()));
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

/// Fire-and-forget helper — runs future without awaiting.
void unawaited(Future<void> future) {
  future.catchError((_) {}); // Silently ignore errors
}

// ─── Root App ──────────────────────────────────────────────────────────────

class AmalTrackerApp extends ConsumerWidget {
  const AmalTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Amal Tracker',
      themeMode: settings.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const _AppRouter(),
    );
  }
}

// ─── Smart Router ─────────────────────────────────────────────────────────

/// Handles the splash → auth/home routing correctly.
/// Uses a brief minimum splash duration to prevent visual flicker.
class _AppRouter extends ConsumerStatefulWidget {
  const _AppRouter();

  @override
  ConsumerState<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends ConsumerState<_AppRouter> {
  bool _minimumSplashDone = false;

  @override
  void initState() {
    super.initState();
    // Minimum 1.5s splash for branding — prevents jarring instant transition
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _minimumSplashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Read auth state — this tells us if stream has emitted
    final authAsync = ref.watch(authStateProvider);
    // Direct session check — always immediately available from Supabase
    final session = ref.watch(sessionProvider);

    // Show splash if minimum time not done OR auth stream still loading
    final isLoading = !_minimumSplashDone || authAsync.isLoading;

    if (isLoading) {
      return const SplashScreen();
    }

    // Auth is determined — route correctly
    if (session != null) {
      return const MainNavigationScreen();
    }

    return const AuthScreen();
  }
}

// ─── Main Navigation ──────────────────────────────────────────────────────

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
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
