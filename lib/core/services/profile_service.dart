import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeeProfile {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String department;
  final String employeeId;
  final String subInstitute;
  final String role;

  EmployeeProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.department,
    required this.employeeId,
    required this.subInstitute,
    required this.role,
  });

  factory EmployeeProfile.fromMetadata(Map<String, dynamic> metadata, String id, String email) {
    return EmployeeProfile(
      id: id,
      fullName: metadata['full_name'] ?? 'Unknown',
      email: email,
      phone: metadata['phone'] ?? '',
      department: metadata['department'] ?? '',
      employeeId: metadata['employee_id'] ?? '',
      subInstitute: metadata['sub_institute'] ?? '',
      role: metadata['role'] ?? 'employee',
    );
  }
}

class ProfileService {
  ProfileService._();
  static final instance = ProfileService._();
  final _supabase = Supabase.instance.client;

  /// Fetches all employees. In production, this would query a 'profiles' table.
  /// For this institutional app, we query the 'profiles' view or table.
  Future<List<EmployeeProfile>> getAllEmployees() async {
    // Note: This requires a 'profiles' table in Supabase that admins can read.
    final response = await _supabase.from('profiles').select();
    final List<dynamic> data = response as List<dynamic>;
    
    return data.map((json) => EmployeeProfile(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      phone: json['phone'],
      department: json['department'],
      employeeId: json['employee_id'],
      subInstitute: json['sub_institute'],
      role: json['role'] ?? 'employee',
    )).toList();
  }

  Future<void> updateEmployeeRole(String userId, String role) async {
    await _supabase.from('profiles').update({'role': role}).eq('id', userId);
  }

  Future<void> deleteEmployee(String userId) async {
    // Soft delete or remove from profiles
    await _supabase.from('profiles').delete().eq('id', userId);
  }
}
