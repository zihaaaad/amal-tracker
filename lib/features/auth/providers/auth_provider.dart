import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/auth_service.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return AuthService.instance.authStateChanges;
});

final sessionProvider = Provider<Session?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  return authState?.session ?? AuthService.instance.currentSession;
});

final userProvider = Provider<User?>((ref) {
  final session = ref.watch(sessionProvider);
  return session?.user ?? AuthService.instance.currentUser;
});
