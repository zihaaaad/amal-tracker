import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Checks if the current user has admin privileges.
  /// Typically stored in user metadata or a separate 'profiles' table.
  bool get isAdmin {
    final user = currentUser;
    if (user == null) return false;
    // For production, this should check a dedicated 'role' field.
    // Here we check metadata or email domain for institutional control.
    final metadata = user.userMetadata ?? {};
    return metadata['role'] == 'admin' || user.email?.endsWith('@assunnahfoundation.org') == true;
  }

  /// Returns true if the user has completed their institutional onboarding.
  bool get isProfileComplete {
    final user = currentUser;
    if (user == null) return false;
    final metadata = user.userMetadata ?? {};
    return metadata['is_profile_complete'] == true;
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
          'phone': phone,
          'department': department,
          'employee_id': employeeId,
          'sub_institute': subInstitute,
          'is_profile_complete': true,
        },
      ),
    );
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

