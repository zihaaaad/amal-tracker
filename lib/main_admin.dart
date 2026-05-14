import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_core.dart';

/// Entry point for the Foundation Admin Dashboard.
void main() async {
  await AppCore.init(AppMode.admin);
  runApp(const ProviderScope(
    child: AmalTrackerApp(mode: AppMode.admin),
  ));
}
