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
/// This provider is designed to be resilient during browser-to-app redirects.
final sessionProvider = Provider<Session?>((ref) {
  final authAsync = ref.watch(authStateProvider);
  
  // Big Tech Pattern: Direct client read as primary, stream as trigger.
  // This ensures that even if the stream is 'loading', we check the actual client memory.
  final currentSession = Supabase.instance.client.auth.currentSession;

  authAsync.when(
    data: (data) {
      debugPrint('AUTH_DEBUG: Event ${data.event} | Session valid: ${data.session != null}');
    },
    loading: () => debugPrint('AUTH_DEBUG: Auth stream is warming up...'),
    error: (e, _) => debugPrint('AUTH_DEBUG: Auth stream error: $e'),
  );

  if (currentSession != null) {
    debugPrint('AUTH_DEBUG: Session confirmed for ${currentSession.user.email}');
  }
  
  return currentSession;
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
