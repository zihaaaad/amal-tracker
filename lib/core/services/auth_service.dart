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
  /// PRIORITIZES: Live Database Profile > Email Domain > Auth Metadata (Fallback)
  bool get isAdmin {
    // 1. Check fresh profile from database (Source of Truth)
    if (_currentProfile != null) {
      return _currentProfile!['role'] == 'admin';
    }

    // 2. Check Auth Metadata (Cached/Fallback)
    final user = currentUser;
    if (user == null) return false;
    final metadata = user.userMetadata ?? {};
    
    if (metadata['role'] == 'admin') return true;

    // 3. Institutional Email Domain Protection
    return user.email?.endsWith('@assunnahfoundation.org') == true;
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
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      _currentProfile = response;
    } catch (e) {
      debugPrint('Profile refresh: $e');
      // If profiles table doesn't exist yet, use auth metadata as fallback
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
    // Update auth metadata
    await _supabase.auth.updateUser(
      UserAttributes(
        data: {
          'full_name': name,
          'is_profile_complete': true,
        },
      ),
    );

    // Update the public profiles table
    try {
      await _supabase.from('profiles').upsert({
        'id': currentUser!.id,
        'email': currentUser!.email ?? '',
        'full_name': name,
        'phone': phone,
        'department': department,
        'employee_id': employeeId,
        'sub_institute': subInstitute,
        'is_profile_complete': true,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Profile table update failed: $e');
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
    final redirectUrl = isClient 
        ? 'com.amaltracker.auth://callback' 
        : 'com.amaltracker.admin.auth://callback';

    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() async {
    clearProfile();
    await _supabase.auth.signOut();
  }
}
