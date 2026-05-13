import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../tracker/providers/daily_log_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await AuthService.instance.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          await ref.read(dailyLogProvider.notifier).restoreFromCloud();
        }
      } else {
        await AuthService.instance.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification email sent! Check your inbox.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.surfaceCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.glassBorder),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  'Amal Tracker',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                    letterSpacing: -1.0,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _isLogin ? 'Sign in to continue' : 'Create your account',
                  style: TextStyle(
                    fontSize: 15,
                    color: context.textSecondary,
                  ),
                ),

                const SizedBox(height: 40),

                // Form
                Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.surfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.glassBorder),
                    ),
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          type: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email is required';
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password is required';
                            if (!_isLogin && v.length < 6) return 'Minimum 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        // Sign in button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _isLogin ? 'Sign In' : 'Create Account',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // OR divider
                Row(
                  children: [
                    Expanded(child: Divider(color: context.glassBorder)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: context.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: context.glassBorder)),
                  ],
                ),

                const SizedBox(height: 24),

                // Google button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            try {
                              await AuthService.instance.signInWithGoogle();
                            } catch (e) {
                              _showError(e.toString().replaceAll('Exception: ', ''));
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(color: context.glassBorder),
                    ),
                    icon: const Text(
                      'G',
                      style: TextStyle(
                        color: Color(0xFF4285F4),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    label: Text(
                      'Continue with Google',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Toggle login/signup
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: context.textSecondary, fontSize: 14),
                      children: [
                        TextSpan(text: _isLogin ? "Don't have an account? " : "Already have an account? "),
                        TextSpan(
                          text: _isLogin ? 'Sign Up' : 'Sign In',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      keyboardType: type,
      style: TextStyle(color: context.textPrimary),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.textMuted, fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: context.textMuted),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: context.textMuted,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: context.surfaceOverlay,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 11),
      ),
    );
  }
}
