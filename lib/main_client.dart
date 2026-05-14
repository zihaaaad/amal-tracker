import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_core.dart';

/// Entry point for the Standard Employee Tracker.
void main() async {
  await AppCore.init();
  runApp(const ProviderScope(
    child: AmalTrackerApp(mode: AppMode.client),
  ));
}
