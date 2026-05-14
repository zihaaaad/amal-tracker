import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/theme_extension.dart';
import '../providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
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
    _nameController.text = AuthService.instance.currentUser?.userMetadata?['full_name'] ?? '';
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

      // Invalidate profile provider to trigger AppRouter redirection
      ref.invalidate(profileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile created successfully! Welcome to As-Sunnah Tracker.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: context.timeTint.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: Icon(Icons.verified_user_rounded, color: context.timeTint, size: 32),
              ),
              const SizedBox(height: 24),
              Text(
                'Institutional Onboarding',
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: context.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'As-Sunnah Foundation requires these details for employee records.',
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
                    : const Text('Complete Onboarding', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
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
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)),
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
            style: const TextStyle(fontWeight: FontWeight.w600),
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
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)),
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
