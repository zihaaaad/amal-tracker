import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/database/database_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../admin/presentation/screens/admin_task_screen.dart';
import '../../auth/presentation/screens/onboarding_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tracker/providers/daily_log_provider.dart';
import '../providers/settings_provider.dart';
import 'notice_board_screen.dart';
import 'profile_edit_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        title: Text('settings.title'.tr()),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        physics: const BouncingScrollPhysics(),
        children: [
          // Profile Section
          _buildSectionTitle(context, 'PERSONAL INFORMATION'),
          profileAsync.when(
            data: (profile) => _buildSettingsTile(
              context,
              icon: Icons.person_rounded,
              title: profile?['full_name'] ?? 'Incomplete Profile',
              subtitle: profile != null 
                ? '${profile['department']} • ID: ${profile['employee_id']}'
                : 'Tap to complete institutional records',
              onTap: () {
                HapticFeedback.mediumImpact();
                if (profile == null) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OnboardingScreen()));
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileEditScreen()));
                }
              },
            ),
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())),
            error: (_, __) => _buildSettingsTile(
              context,
              icon: Icons.error_outline_rounded,
              title: 'Profile Error',
              subtitle: 'Institutional records could not be loaded',
              iconColor: AppColors.softCoral,
              onTap: () => ref.invalidate(profileProvider),
            ),
          ),
          const SizedBox(height: 32),

          // Theme Section
          _buildSectionTitle(context, 'settings.appearance'.tr().toUpperCase()),
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

          // Language Section
          _buildSectionTitle(context, 'settings.language'.tr().toUpperCase()),
          _buildSettingsTile(
            context,
            icon: Icons.language_rounded,
            title: 'settings.language'.tr(),
            subtitle: 'Current: ${context.locale.languageCode.toUpperCase()}',
            onTap: () => _showLanguageDialog(context),
          ),

          const SizedBox(height: 32),
          
          // Notifications
          _buildSectionTitle(context, 'COMMUNICATION'),
          _buildSettingsTile(context, 
            icon: Icons.campaign_rounded,
            title: 'Foundation Notices',
            subtitle: 'Official institutional announcements',
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NoticeBoardScreen()));
            },
          ),
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

          // Admin Dashboard (Institutional Control)
          profileAsync.when(
            data: (profile) {
              if (AuthService.instance.isAdmin) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'INSTITUTIONAL CONTROL'),
                    _buildSettingsTile(
                      context,
                      icon: Icons.admin_panel_settings_rounded,
                      title: 'Admin Dashboard',
                      subtitle: 'Manage Foundation tasks & employees',
                      onTap: () async {
                        await HapticFeedback.mediumImpact();
                        final auth = LocalAuthentication();
                        try {
                          final canAuth = await auth.canCheckBiometrics || await auth.isDeviceSupported();
                          if (canAuth) {
                            final didAuth = await auth.authenticate(
                              localizedReason: 'Authenticate to access Foundation Management',
                              options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
                            );
                            if (didAuth && context.mounted) {
                              unawaited(Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                              ));
                            }
                          } else if (context.mounted) {
                            unawaited(Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                            ));
                          }
                        } catch (_) {
                          if (context.mounted) {
                            unawaited(Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                            ));
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Account & Sync
          _buildSectionTitle(context, 'ACCOUNT'),
          _buildSettingsTile(context, 
            icon: Icons.sync_rounded,
            title: 'Cloud Backup',
            subtitle: 'Sync your progress now',
            onTap: () async {
              await HapticFeedback.mediumImpact();
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
            title: 'settings.logout'.tr(),
            subtitle: 'Securely exit your session',
            iconColor: AppColors.softCoral,
            titleColor: AppColors.softCoral,
            onTap: () async {
              await HapticFeedback.heavyImpact();
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
          _buildAboutCard(context, ref),
          const SizedBox(height: 120), // Bottom padding for floating nav

        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.textMuted.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'settings.language'.tr(),
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _buildLanguageTile(context, 'English', 'en'),
            _buildLanguageTile(context, 'বাংলা', 'bn'),
            _buildLanguageTile(context, 'العربية', 'ar'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context, String name, String code) {
    final isSelected = context.locale.languageCode == code;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? context.timeTint.withValues(alpha: 0.1) : context.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? context.timeTint : context.glassBorder.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        onTap: () {
          context.setLocale(Locale(code));
          Navigator.pop(context);
        },
        title: Text(
          name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? context.timeTint : context.textPrimary,
          ),
        ),
        trailing: isSelected 
            ? Icon(Icons.check_circle_rounded, color: context.timeTint) 
            : null,
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

  Widget _buildAboutCard(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(packageInfoProvider);
    
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
          packageInfo.when(
            data: (info) => Text(
              'Institutional Edition • v${info.version}+${info.buildNumber}',
              style: TextStyle(color: context.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const Text('Institutional Edition'),
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
