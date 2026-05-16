import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app_core.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _currentProfile;

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  Map<String, dynamic>? get currentProfile => _currentProfile;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Returns true if the user is an authorized admin for As-Sunnah Foundation.
  /// PRIORITIZES: Live Database Profile > Auth Metadata (Fallback)
  bool get isAdmin {
    final user = currentUser;
    if (user == null) return false;

    // 1. Check fresh profile from database (Source of Truth)
    if (_currentProfile != null) {
      final role = _currentProfile!['role'];
      return role == 'admin' || role == 'manager';
    }

    // 2. Check Auth Metadata (Cached/Fallback)
    final metadata = user.userMetadata ?? {};
    final metaRole = metadata['role'];
    
    return metaRole == 'admin' || metaRole == 'manager';
  }

  /// Returns true if the user has completed their institutional onboarding.
  bool get isProfileComplete {
    if (_currentProfile != null) {
      return _currentProfile!['is_profile_complete'] == true;
    }
    final user = currentUser;
    if (user == null) return false;
    final metadata = user.userMetadata ?? {};
    return metadata['is_profile_complete'] == true;
  }

  /// Fetches the latest profile data from the Supabase 'profiles' table.
  /// Falls back gracefully if the profiles table doesn't exist yet.
  Future<void> refreshProfile() async {
    final user = currentUser;
    if (user == null) return;
    try {
      // Big Tech Reliability: Network timeout for profile fetch
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
      
      debugPrint('Profile Refreshed: ${response != null ? 'Found' : 'Not Found'}');
      _currentProfile = response;
    } catch (e) {
      debugPrint('Profile refresh error: $e');
      _currentProfile = null;
    }
  }

  /// Clears cached profile data on sign out.
  void clearProfile() {
    _currentProfile = null;
  }

  /// Updates user profile metadata in both Auth and profiles table.
  Future<void> updateProfile({
    required String name,
    required String phone,
    required String department,
    required String employeeId,
    required String subInstitute,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No authenticated user');

    // 1. Update the public profiles table FIRST
    // This is the source of truth. If this fails, we shouldn't mark auth as complete.
    try {
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'email': user.email ?? '',
        'full_name': name,
        'phone': phone,
        'department': department,
        'employee_id': employeeId,
        'sub_institute': subInstitute,
        'is_profile_complete': true,
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('Database profile updated successfully');
    } catch (e) {
      debugPrint('DB Profile Update FAILED: $e');
      rethrow; // Ensure UI knows it failed
    }

    // 2. Update auth metadata (Secondary cache for faster routing)
    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': name,
            'is_profile_complete': true,
          },
        ),
      );
      debugPrint('Auth metadata updated successfully');
    } catch (e) {
      debugPrint('Auth metadata update warning: $e');
      // We don't rethrow here because DB is already updated
    }

    await refreshProfile();
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    // Refresh profile after login
    await refreshProfile();
    return response;
  }

  Future<AuthResponse> signUp({required String email, required String password}) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'com.amaltracker.auth://callback',
    );
  }

  Future<void> signInWithGoogle() async {
    final isClient = AppCore.mode == AppMode.client;
    // Standardized Redirect: Added trailing slash for protocol robustness
    final redirectUrl = isClient 
        ? 'com.amaltracker.auth://callback/' 
        : 'com.amaltracker.admin.auth://callback/';

    debugPrint('Initiating Google Login with Redirect: $redirectUrl');

    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
      authScreenLaunchMode: LaunchMode.inAppBrowserView,
    );
  }

  Future<void> signOut() async {
    clearProfile();
    await _supabase.auth.signOut();
  }
}
