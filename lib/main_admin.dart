import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_core.dart';

/// Entry point for the Foundation Admin Dashboard.
void main() async {
  try {
    await AppCore.init(AppMode.admin);
  } catch (e) {
    debugPrint('Critical Initialization Failure: $e');
  }

  runApp(const ProviderScope(
    child: AmalTrackerApp(mode: AppMode.admin),
  ));
}
