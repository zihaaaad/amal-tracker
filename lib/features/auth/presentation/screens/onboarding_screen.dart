import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/theme_extension.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _deptController = TextEditingController();
  final _idController = TextEditingController();
  final _subInstController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = AuthService.instance.currentUser?.userMetadata?['full_name'] ?? '';
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _deptController.text.isEmpty || _idController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        department: _deptController.text.trim(),
        employeeId: _idController.text.trim(),
        subInstitute: _subInstController.text.trim(),
      );
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
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Complete Your Profile',
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: context.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Please provide your institutional details to continue.',
                style: TextStyle(color: context.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 40),
              _buildField('Full Name', _nameController, Icons.person_outline_rounded),
              const SizedBox(height: 20),
              _buildField('Phone Number', _phoneController, Icons.phone_android_rounded, TextInputType.phone),
              const SizedBox(height: 20),
              _buildField('Employee ID', _idController, Icons.badge_outlined),
              const SizedBox(height: 20),
              _buildField('Department', _deptController, Icons.account_tree_outlined),
              const SizedBox(height: 20),
              _buildField('Sub Institute', _subInstController, Icons.business_rounded, TextInputType.text, 'e.g. Dhaka Branch'),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.timeTint,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Save & Continue', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, [TextInputType? type, String? hint]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.glassBorder),
          ),
          child: TextField(
            controller: controller,
            keyboardType: type,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: context.timeTint),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
