 import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'features/settings/providers/settings_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/database/database_service.dart';
import 'core/services/background_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'features/tracker/presentation/screens/home_screen.dart';
import 'features/analytics/presentation/screens/analytics_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for consistent layout
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style immediately to prevent white flash
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Run all async inits in parallel where possible
  await Future.wait([
    _initTimezone(),
    DatabaseService.initialize(),
  ]);

  // Supabase must come after DB init
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // These can run in parallel after Supabase
  await Future.wait([
    NotificationService.initialize(),
    BackgroundService.initialize(),
  ]);

  runApp(
    const ProviderScope(
      child: AmalTrackerApp(),
    ),
  );
}

Future<void> _initTimezone() async {
  tz.initializeTimeZones();
  try {
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName.toString()));
  } catch (_) {
    // Fallback to UTC if timezone detection fails
    tz.setLocalLocation(tz.UTC);
  }
}

class AmalTrackerApp extends ConsumerWidget {
  const AmalTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    // Watch the full auth stream — handles loading/error/data states
    final authAsync = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Amal Tracker',
      themeMode: settings.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: authAsync.when(
        // While auth stream is loading (first frame) — show branded splash
        loading: () => const SplashScreen(),
        // Auth state known — route to appropriate screen
        data: (authState) {
          final session = ref.read(sessionProvider);
          if (session != null) {
            return const MainNavigationScreen();
          }
          return const AuthScreen();
        },
        // Auth error — show auth screen so user can retry
        error: (e, _) => const AuthScreen(),
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

  final List<Widget> _screens = const [
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
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
