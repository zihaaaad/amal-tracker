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

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Parallel init: timezone + local DB
  await Future.wait([
    _initTimezone(),
    DatabaseService.initialize(),
  ]);

  // Supabase — handles session restoration, deep links, OAuth callbacks
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    // PKCE is the secure default for mobile OAuth — required for Google Sign-In
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Non-critical services — don't block startup
  NotificationService.initialize().catchError((_) {});
  BackgroundService.initialize().catchError((_) {});

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

// ─── Root App ──────────────────────────────────────────────────

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

// ─── Router ────────────────────────────────────────────────────
//
// Responsibilities:
//   1. Show splash for one frame while Supabase restores the cached session
//   2. After that, route to AuthScreen or MainNavigationScreen based on session
//   3. Re-route automatically when auth state changes (login / logout / OAuth return)

class _AppRouter extends ConsumerStatefulWidget {
  const _AppRouter();

  @override
  ConsumerState<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends ConsumerState<_AppRouter> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // One frame is enough for Supabase to restore a cached session synchronously
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the auth stream — causes rebuild on every auth state change:
    //   - Email/password login → session created
    //   - Google OAuth return → onAuthStateChange fires
    //   - Sign out → session destroyed
    final authAsync = ref.watch(authStateProvider);

    // Direct session read — always reflects ground-truth Supabase state
    final session = ref.watch(sessionProvider);

    // Show splash while:
    //   (a) waiting for first frame (Supabase session restore), OR
    //   (b) auth stream is still in initial loading state
    if (!_ready || authAsync.isLoading) {
      return const SplashScreen();
    }

    // Session present → go to app
    if (session != null) {
      return const MainNavigationScreen();
    }

    // No session → show login
    return const AuthScreen();
  }
}

// ─── Main Navigation ───────────────────────────────────────────

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
