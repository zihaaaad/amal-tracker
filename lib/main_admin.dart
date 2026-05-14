import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_core.dart';

/// Entry point for the Foundation Admin Dashboard.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  
  try {
    await AppCore.init(AppMode.admin);
  } catch (e) {
    debugPrint('Critical Initialization Failure: $e');
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('bn'),
        Locale('ar'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(
        child: AmalTrackerApp(mode: AppMode.admin),
      ),
    ),
  );
}
