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
  final stream = Supabase.instance.client.auth.onAuthStateChange;
  return stream;
});

/// Current session — reads directly from Supabase client (synchronous, always fresh).
/// Re-evaluates whenever authStateProvider emits so routing stays in sync.
final sessionProvider = Provider<Session?>((ref) {
  // Subscribe to auth stream so this provider invalidates on every auth event
  final authState = ref.watch(authStateProvider);
  
  final session = Supabase.instance.client.auth.currentSession;
  
  if (session != null) {
    debugPrint('Session Detected: ${session.user.id}');
  } else {
    debugPrint('No Session (Auth State: ${authState.value?.event})');
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
    await AuthService.instance.refreshProfile();
    return AuthService.instance.currentProfile;
  } catch (e) {
    debugPrint('Profile Provider Error: $e');
    return null; // Fallback to null instead of throwing and hanging the router
  }
});
