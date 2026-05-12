import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final ThemeMode themeMode;
  final bool notificationsEnabled;

  SettingsState({
    this.themeMode = ThemeMode.dark,
    this.notificationsEnabled = true,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isLight = prefs.getBool('isLightMode') ?? false;
    final notifs = prefs.getBool('notificationsEnabled') ?? true;
    
    state = state.copyWith(
      themeMode: isLight ? ThemeMode.light : ThemeMode.dark,
      notificationsEnabled: notifs,
    );
  }

  Future<void> toggleTheme(bool isLight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLightMode', isLight);
    state = state.copyWith(themeMode: isLight ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> toggleNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }
}
