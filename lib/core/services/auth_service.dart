import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool get isAdmin {
    if (_currentProfile != null) {
      return _currentProfile!['role'] == 'admin';
    }
    final user = currentUser;
    if (user == null) return false;
    final metadata = user.userMetadata ?? {};
    return metadata['role'] == 'admin' || user.email?.endsWith('@assunnahfoundation.org') == true;
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
  Future<void> refreshProfile() async {
    final user = currentUser;
    if (user == null) return;
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      _currentProfile = response;
    } catch (e) {
      debugPrint('Error refreshing profile: $e');
    }
  }

  /// Updates user profile metadata in Supabase.
  Future<void> updateProfile({
    required String name,
    required String phone,
    required String department,
    required String employeeId,
    required String subInstitute,
  }) async {
    await _supabase.auth.updateUser(
      UserAttributes(
        data: {
          'full_name': name,
          'is_profile_complete': true,
        },
      ),
    );

    // Also update the public profiles table
    await _supabase.from('profiles').update({
      'full_name': name,
      'phone': phone,
      'department': department,
      'employee_id': employeeId,
      'sub_institute': subInstitute,
      'is_profile_complete': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', currentUser!.id);

    await refreshProfile();
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({required String email, required String password}) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'com.amaltracker.auth://callback',
    );
  }

  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.amaltracker.auth://callback',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}

