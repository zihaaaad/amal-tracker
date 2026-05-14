import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_core.dart';

/// Default entry point (Client Mode)
void main() async {
  try {
    await AppCore.init(AppMode.client);
  } catch (e) {
    debugPrint('Critical Initialization Failure: $e');
  }
  
  runApp(const ProviderScope(
    child: AmalTrackerApp(mode: AppMode.client),
  ));
}
