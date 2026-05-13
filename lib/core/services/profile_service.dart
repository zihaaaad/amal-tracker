import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

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

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    return EmployeeProfile(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? 'Unknown',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      department: json['department'] ?? 'Unassigned',
      employeeId: json['employee_id'] ?? '',
      subInstitute: json['sub_institute'] ?? '',
      role: json['role'] ?? 'employee',
    );
  }
}

class ProfileService {
  ProfileService._();
  static final instance = ProfileService._();
  final _supabase = Supabase.instance.client;

  /// Fetches all employees from the institutional profiles table.
  Future<List<EmployeeProfile>> getAllEmployees() async {
    try {
      final response = await _supabase.from('profiles').select();
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => EmployeeProfile.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Failed to fetch employees: $e');
      return [];
    }
  }

  Future<void> updateEmployeeRole(String userId, String role) async {
    try {
      await _supabase.from('profiles').update({'role': role}).eq('id', userId);
    } catch (e) {
      debugPrint('Failed to update role: $e');
    }
  }

  Future<void> deleteEmployee(String userId) async {
    try {
      await _supabase.from('profiles').delete().eq('id', userId);
    } catch (e) {
      debugPrint('Failed to delete employee: $e');
    }
  }
}
