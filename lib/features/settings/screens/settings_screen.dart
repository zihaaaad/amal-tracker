import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/database/database_service.dart';
import '../../tracker/providers/daily_log_provider.dart';
import '../providers/settings_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../admin/presentation/screens/admin_task_screen.dart';
import 'package:local_auth/local_auth.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Force a background refresh of the profile to pick up any manual role changes
    AuthService.instance.refreshProfile().then((_) {
      // If we are on this screen, we might need to rebuild if the role changed
      if (context.mounted) ref.invalidate(authStateProvider);
    });
    
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        title: const Text('Preferences'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        physics: const BouncingScrollPhysics(),
        children: [
          // Theme Section
          _buildSectionTitle(context, 'APPEARANCE'),
          _buildSettingsTile(context, 
            icon: Icons.dark_mode_rounded,
            title: 'Dark Mode',
            subtitle: 'Toggle deep night theme',
            trailing: Switch(
              value: settings.themeMode == ThemeMode.dark,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                ref.read(settingsProvider.notifier).toggleTheme(!val);
              },
              activeThumbColor: context.timeTint,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Notifications
          _buildSectionTitle(context, 'COMMUNICATION'),
          _buildSettingsTile(context, 
            icon: Icons.notifications_active_rounded,
            title: 'Smart Reminders',
            subtitle: 'Never miss a spiritual goal',
            trailing: Switch(
              value: settings.notificationsEnabled,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                ref.read(settingsProvider.notifier).toggleNotifications(val);
              },
              activeThumbColor: context.timeTint,
            ),
          ),
          
          const SizedBox(height: 32),

          const SizedBox(height: 24),

          // Admin Dashboard (Institutional Control)
          if (AuthService.instance.isAdmin) ...[
            _buildSectionTitle(context, 'INSTITUTIONAL CONTROL'),
            _buildSettingsTile(context,
              icon: Icons.admin_panel_settings_rounded,
              title: 'Admin Dashboard',
              subtitle: 'Manage Foundation tasks & employees',
              onTap: () async {
                HapticFeedback.mediumImpact();
                final auth = LocalAuthentication();
                try {
                  final canAuth = await auth.canCheckBiometrics || await auth.isDeviceSupported();
                  if (canAuth) {
                    final didAuth = await auth.authenticate(
                      localizedReason: 'Authenticate to access Foundation Management',
                      options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
                    );
                    if (didAuth && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                      );
                    }
                  } else if (context.mounted) {
                    // Fallback if no biometrics
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 24),
          ],

          // Account & Sync
          _buildSectionTitle(context, 'ACCOUNT'),
          _buildSettingsTile(context, 
            icon: Icons.sync_rounded,
            title: 'Cloud Backup',
            subtitle: 'Sync your progress now',
            onTap: () async {
              HapticFeedback.mediumImpact();
              try {
                await DatabaseService.instance.syncToCloud();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data secured in the cloud.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sync error: $e'), backgroundColor: AppColors.softCoral),
                  );
                }
              }
            },
          ),
          _buildSettingsTile(context, 
            icon: Icons.logout_rounded,
            title: 'Sign Out',
            subtitle: 'Securely exit your session',
            iconColor: AppColors.softCoral,
            titleColor: AppColors.softCoral,
            onTap: () async {
              HapticFeedback.heavyImpact();
              await AuthService.instance.signOut();
            },
          ),
          
          const SizedBox(height: 32),

          // Data Management
          _buildSectionTitle(context, 'STORAGE'),
          _buildSettingsTile(context, 
            icon: Icons.delete_sweep_rounded,
            title: 'Clear Local Cache',
            subtitle: 'Reset this device data',
            onTap: () {
              HapticFeedback.vibrate();
              _showDeleteDialog(context, ref);
            },
          ),
          
          const SizedBox(height: 48),
          
          // Branded About Section
          _buildAboutCard(context),
          const SizedBox(height: 120), // Bottom padding for floating nav
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Wipe Data?', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        content: const Text('This will permanently delete all tracking history from this device. Cloud data remains safe.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep Data', style: TextStyle(color: context.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseService.instance.clearAllData();
              ref.read(dailyLogProvider.notifier).refreshToday();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.softCoral, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 8),
      child: Text(
        title,
        style: TextStyle(
          color: context.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? iconColor,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.glassBorder.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (iconColor ?? context.timeTint).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: iconColor ?? context.timeTint,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor ?? context.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: context.textMuted,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        trailing: trailing ?? (onTap != null 
            ? Icon(Icons.chevron_right_rounded, color: context.textMuted.withValues(alpha: 0.4)) 
            : null),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.timeTint.withValues(alpha: 0.05),
            context.surfaceCard,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.timeTint.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.timeTint.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome_rounded, color: context.timeTint, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'As-Sunnah Tracker',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Institutional Edition • v1.0.0',
            style: TextStyle(color: context.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            'Dedicated to the employees of As-Sunnah Foundation.\nMay this serve as a means for our shared spiritual growth.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
