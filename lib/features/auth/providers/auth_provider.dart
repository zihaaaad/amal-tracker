import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/auth_service.dart';

/// Streams future auth state changes (login, logout, token refresh).
final authStateProvider = StreamProvider<AuthState>((ref) {
  return AuthService.instance.authStateChanges;
});

/// The current session — reads DIRECTLY from Supabase (not from stream).
/// This is always immediately available without waiting for a stream event.
final sessionProvider = Provider<Session?>((ref) {
  // When auth stream fires, invalidate this provider to recompute
  ref.watch(authStateProvider);
  // Always read the ground-truth directly from Supabase client
  return Supabase.instance.client.auth.currentSession;
});

/// Current user derived from session.
final userProvider = Provider<User?>((ref) {
  return ref.watch(sessionProvider)?.user;
});

/// Whether auth state is fully determined (session check complete).
/// Used for routing — avoids showing wrong screen during initialization.
final isAuthReadyProvider = Provider<bool>((ref) {
  final authAsync = ref.watch(authStateProvider);
  // Auth is ready when: stream has emitted at least once OR we have a known session
  return authAsync.hasValue || 
         Supabase.instance.client.auth.currentSession != null;
});
