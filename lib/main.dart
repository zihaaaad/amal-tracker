import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_core.dart';

/// Default entry point (Client Mode)
void main() async {
  await AppCore.init(AppMode.client);
  runApp(const ProviderScope(
    child: AmalTrackerApp(mode: AppMode.client),
  ));
}
