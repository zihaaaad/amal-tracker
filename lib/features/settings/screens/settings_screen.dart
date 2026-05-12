import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/database/database_service.dart';
import '../../tracker/providers/daily_log_provider.dart';
import '../providers/settings_provider.dart';
import '../../../../core/services/auth_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Theme Section
          _buildSectionTitle(context, 'Appearance'),
          _buildSettingsTile(context, 
            icon: Icons.dark_mode_rounded,
            title: 'Dark Mode',
            subtitle: 'Switch between dark and light theme',
            trailing: Switch(
              value: settings.themeMode == ThemeMode.dark,
              onChanged: (val) {
                // val = true means user wants dark mode
                ref.read(settingsProvider.notifier).toggleTheme(!val);
              },
              activeThumbColor: AppColors.sageGreenLight,
            ),
          ),
          _buildSettingsTile(context,
            icon: Icons.speed_rounded,
            title: 'Performance Mode',
            subtitle: 'Disable blur effects for smoother scrolling on older devices',
            trailing: Switch(
              value: settings.performanceMode,
              onChanged: (val) {
                ref.read(settingsProvider.notifier).togglePerformanceMode(val);
              },
              activeThumbColor: AppColors.sageGreenLight,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Notifications
          _buildSectionTitle(context, 'Smart Notifications'),
          _buildSettingsTile(context, 
            icon: Icons.notifications_active_rounded,
            title: 'Allow Notifications',
            subtitle: 'Reminders for prayers, sleep, and streaks',
            trailing: Switch(
              value: settings.notificationsEnabled, // Typically managed by permissions
              onChanged: (val) {
                ref.read(settingsProvider.notifier).toggleNotifications(val);
              },
              activeThumbColor: AppColors.sageGreenLight,
            ),
          ),
          
          const SizedBox(height: 24),

          // Account & Sync
          _buildSectionTitle(context, 'Account & Sync'),
          _buildSettingsTile(context, 
            icon: Icons.cloud_sync_rounded,
            title: 'Sync Now',
            subtitle: 'Backup your data to the cloud',
            onTap: () async {
              try {
                await DatabaseService.instance.syncToCloud();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sync completed successfully!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sync failed: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
          ),
          _buildSettingsTile(context, 
            icon: Icons.logout_rounded,
            title: 'Logout',
            subtitle: 'Sign out from your account',
            onTap: () async {
              await AuthService.instance.signOut();
            },
          ),
          
          const SizedBox(height: 24),

          // Data Management
          _buildSectionTitle(context, 'Data Management'),
          _buildSettingsTile(context, 
            icon: Icons.delete_outline_rounded,
            title: 'Clear Local Data',
            subtitle: 'Permanently delete all logs from this device',
            iconColor: AppColors.softCoral,
            titleColor: AppColors.softCoral,
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear All Data?'),
                  content: const Text('This will permanently delete all your tracking history. This cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel', style: TextStyle(color: context.textSecondary)),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await DatabaseService.instance.clearAllData();
                        ref.read(dailyLogProvider.notifier).refreshToday();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All data cleared successfully')),
                          );
                        }
                      },
                      child: const Text('Delete', style: TextStyle(color: AppColors.softCoral)),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 40),
          Center(
            child: Text(
              'Amal Tracker v1.0.0\nBuilt with Clean Architecture',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: context.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.glassBorder),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.sageGreen).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.sageGreenLight,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor ?? context.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: context.textMuted,
            fontSize: 12,
          ),
        ),
        trailing: trailing ?? (onTap != null 
            ? Icon(Icons.chevron_right_rounded, color: context.textMuted) 
            : null),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
