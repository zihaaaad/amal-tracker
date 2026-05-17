import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

 class SettingsState {
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool performanceMode;

  SettingsState({
    this.themeMode = ThemeMode.dark,
    this.notificationsEnabled = true,
    this.performanceMode = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? performanceMode,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      performanceMode: performanceMode ?? this.performanceMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SharedPreferences? _prefs;

  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

   Future<void> _loadSettings() async {
    final prefs = await _getPrefs();
    final isLight = prefs.getBool('isLightMode') ?? false;
    final notifs = prefs.getBool('notificationsEnabled') ?? true;
    final perf = prefs.getBool('performanceMode') ?? false;
    
    state = state.copyWith(
      themeMode: isLight ? ThemeMode.light : ThemeMode.dark,
      notificationsEnabled: notifs,
      performanceMode: perf,
    );
  }

  Future<void> toggleTheme(bool isLight) async {
    final prefs = await _getPrefs();
    await prefs.setBool('isLightMode', isLight);
    state = state.copyWith(themeMode: isLight ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> toggleNotifications(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool('notificationsEnabled', enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }

  Future<void> togglePerformanceMode(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool('performanceMode', enabled);
    state = state.copyWith(performanceMode: enabled);
  }
}
