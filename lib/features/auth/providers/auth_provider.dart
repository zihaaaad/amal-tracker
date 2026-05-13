import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Streams every auth state change:
///   - Email login / signup
///   - Google OAuth callback (fires when user returns from browser)
///   - Token refresh
///   - Sign out
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Current session — reads directly from Supabase client (synchronous, always fresh).
/// Re-evaluates whenever authStateProvider emits so routing stays in sync.
final sessionProvider = Provider<Session?>((ref) {
  // Subscribe to auth stream so this provider invalidates on every auth event
  ref.watch(authStateProvider);
  // Return the live session directly from Supabase — never stale
  return Supabase.instance.client.auth.currentSession;
});

/// Current authenticated user.
final userProvider = Provider<User?>((ref) {
  return ref.watch(sessionProvider)?.user;
});
