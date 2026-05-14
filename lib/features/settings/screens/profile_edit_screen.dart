import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/theme_extension.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idController = TextEditingController();
  
  String? _selectedDept;
  String? _selectedSubInst;
  bool _isLoading = false;

  final List<String> _departments = [
    'Da\'wah & Education',
    'Media & IT',
    'Social Welfare',
    'Finance & Admin',
    'Zakat Management',
    'Research & Fatwa',
  ];

  final List<String> _subInstitutes = [
    'Dhaka Central',
    'Chittagong Branch',
    'Sylhet Center',
    'Rajshahi Unit',
    'Khulna Center',
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).value;
    if (profile != null) {
      _nameController.text = profile['full_name'] ?? '';
      _phoneController.text = profile['phone'] ?? '';
      _idController.text = profile['employee_id'] ?? '';
      _selectedDept = _departments.contains(profile['department']) ? profile['department'] : null;
      _selectedSubInst = _subInstitutes.contains(profile['sub_institute']) ? profile['sub_institute'] : null;
    } else {
       _nameController.text = AuthService.instance.currentUser?.userMetadata?['full_name'] ?? '';
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || 
        _phoneController.text.isEmpty || 
        _selectedDept == null || 
        _idController.text.isEmpty || 
        _selectedSubInst == null) {
      await HapticFeedback.vibrate();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all institutional fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await HapticFeedback.mediumImpact();
    
    try {
      await AuthService.instance.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        department: _selectedDept!,
        employeeId: _idController.text.trim(),
        subInstitute: _selectedSubInst!,
      );
      ref.invalidate(profileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Institutional profile updated successfully.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Professional Records',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: context.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Keep your institutional metadata updated for Foundation records.',
                style: TextStyle(color: context.textSecondary, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 40),
              _buildField('Full Name', _nameController, Icons.person_outline_rounded),
              const SizedBox(height: 20),
              _buildField('Phone Number', _phoneController, Icons.phone_android_rounded, TextInputType.phone),
              const SizedBox(height: 20),
              _buildField('Employee ID', _idController, Icons.badge_outlined),
              const SizedBox(height: 20),
              _buildDropdown('Department', _selectedDept, _departments, Icons.account_tree_outlined, (v) => setState(() => _selectedDept = v)),
              const SizedBox(height: 20),
              _buildDropdown('Sub Institute', _selectedSubInst, _subInstitutes, Icons.business_rounded, (v) => setState(() => _selectedSubInst = v)),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.timeTint,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, [TextInputType? type]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: context.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.glassBorder),
          ),
          child: TextField(
            controller: controller,
            keyboardType: type,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: context.timeTint, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, IconData icon, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: context.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.glassBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text('Select $label', style: TextStyle(color: context.textMuted, fontSize: 14)),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.timeTint),
              dropdownColor: context.surfaceCard,
              borderRadius: BorderRadius.circular(18),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
