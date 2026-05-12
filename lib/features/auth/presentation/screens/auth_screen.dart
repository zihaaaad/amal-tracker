import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
        // Restore user history immediately after login
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
              content: Text('Verification email sent! Please check your inbox.'),
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
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: context.headerGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cinematic Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.surfaceCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.glassBorder.withValues(alpha: 0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 40,
                          spreadRadius: -10,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    'Amal Tracker',
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                      letterSpacing: -1.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0),
                  
                  Text(
                    _isLogin ? 'Transform your daily habits' : 'Join the path of excellence',
                    style: TextStyle(
                      fontSize: 16,
                      color: context.textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  
                  const SizedBox(height: 48),
                  
                  Form(
                    key: _formKey,
                    child: GlassmorphicCard(
                      padding: const EdgeInsets.all(28),
                      borderRadius: 24,
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            icon: Icons.email_outlined,
                            type: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Email is required';
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
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
                          const SizedBox(height: 32),
                          _buildPrimaryButton(),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.95, 0.95)),
                  
                  const SizedBox(height: 32),
                  
                  _buildSocialDivider(context),
                  
                  const SizedBox(height: 32),
                  
                  _buildGoogleButton(context),
                  
                  const SizedBox(height: 40),
                  
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    style: TextButton.styleFrom(foregroundColor: context.textSecondary),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: context.textSecondary, fontSize: 14),
                        children: [
                          TextSpan(text: _isLogin ? "New here? " : "Already tracking? "),
                          TextSpan(
                            text: _isLogin ? "Create Account" : "Login Now",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                ],
              ),
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
        fillColor: context.surfaceOverlay.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 11),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleAuth,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const SizedBox(
              height: 24, 
              width: 24, 
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            )
          : Text(
              _isLogin ? 'Sign In' : 'Get Started',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
      ),
    );
  }

  Widget _buildSocialDivider(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: context.glassBorder.withValues(alpha: 0.2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'OR CONTINUE WITH',
            style: TextStyle(
              color: context.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(child: Divider(color: context.glassBorder.withValues(alpha: 0.2))),
      ],
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : () async {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: context.glassBorder.withValues(alpha: 0.2)),
          backgroundColor: context.surfaceCard.withValues(alpha: 0.5),
        ),
        icon: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Text(
              'G',
              style: TextStyle(
                color: Color(0xFF4285F4),
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ),
        label: Text(
          'Continue with Google',
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

