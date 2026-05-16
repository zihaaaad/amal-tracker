import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/auth_service.dart';

/// Streams every auth state change:
///   - Email login / signup
///   - Google OAuth callback (fires when user returns from browser)
///   - Token refresh
///   - Sign out
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Current session — The single source of truth for the application's auth state.
/// This provider re-evaluates whenever the auth stream emits an event.
final sessionProvider = Provider<Session?>((ref) {
  // Subscribe to auth stream to trigger re-evaluation
  ref.watch(authStateProvider);
  
  // Always return the live session directly from memory
  final session = Supabase.instance.client.auth.currentSession;
  
  if (session != null) {
    debugPrint('PROVIDER: Session Active for ${session.user.email}');
  }
  
  return session;
});

/// Current authenticated user.
final userProvider = Provider<User?>((ref) {
  return ref.watch(sessionProvider)?.user;
});

/// Reactive provider for the user's database profile.
/// Refreshes automatically on auth changes.
final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) {
    AuthService.instance.clearProfile();
    return null;
  }
  
  try {
    // Fetch live profile from Supabase
    await AuthService.instance.refreshProfile();
    return AuthService.instance.currentProfile;
  } catch (e) {
    debugPrint('Profile Provider Error: $e');
    return null; // Graceful fallback
  }
});
