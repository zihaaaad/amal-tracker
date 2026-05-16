import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        final response = await AuthService.instance.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (response.session == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification email sent! Please check your inbox.')),
          );
        }
      } else {
        await AuthService.instance.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.softCoral),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogle() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signInWithGoogle();
      // Note: We do NOT set _isLoading = false here because 
      // the redirect will resume the app and sessionProvider will update.
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.softCoral),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch session to clear local loading state if redirect happens
    ref.listen(sessionProvider, (prev, next) {
      if (next != null && mounted) {
        setState(() => _isLoading = false);
      }
    });

    return Scaffold(
      backgroundColor: context.surface,
      body: Stack(
        children: [
          // Background Gradient Flair
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.timeTint.withValues(alpha: 0.05),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  // App Icon / Logo
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.timeTint.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: context.timeTint.withValues(alpha: 0.2)),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 48,
                        color: context.timeTint,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Welcome Text
                  Center(
                    child: Text(
                      _isSignUp ? 'Join Amal Tracker' : 'Welcome Back',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: context.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _isSignUp 
                        ? 'Begin your journey of spiritual excellence' 
                        : 'Continue your spiritual journey today',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Form Fields
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    icon: Icons.email_outlined,
                    hint: 'name@example.com',
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    hint: '••••••••',
                    isPassword: true,
                  ),
                  const SizedBox(height: 32),

                  // Primary Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.timeTint,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: _isLoading 
                        ? const SizedBox(
                            width: 20, height: 20, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _isSignUp ? 'Create Account' : 'Sign In',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: context.glassBorder)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: TextStyle(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                      Expanded(child: Divider(color: context.glassBorder)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Google Sign In
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogle,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.glassBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      icon: _isLoading 
                        ? const SizedBox.shrink() 
                        : const Icon(Icons.g_mobiledata_rounded, size: 32),
                      label: Text(
                        _isLoading ? 'Waiting...' : 'Continue with Google',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Toggle Auth Mode
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: context.textSecondary, fontSize: 14),
                          children: [
                            TextSpan(text: _isSignUp ? 'Already have an account? ' : "Don't have an account? "),
                            TextSpan(
                              text: _isSignUp ? 'Sign In' : 'Sign Up',
                              style: TextStyle(color: context.timeTint, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: context.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.glassBorder),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: context.textMuted.withValues(alpha: 0.5), fontSize: 14),
              prefixIcon: Icon(icon, size: 20, color: context.timeTint.withValues(alpha: 0.6)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
