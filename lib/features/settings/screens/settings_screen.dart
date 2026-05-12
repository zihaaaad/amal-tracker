import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/database/database_service.dart';
import '../../../tracker/providers/daily_log_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Theme Section
          _buildSectionTitle('Appearance'),
          _buildSettingsTile(
            icon: Icons.dark_mode_rounded,
            title: 'Premium Dark Mode',
            subtitle: 'Amal Tracker is designed exclusively for dark mode',
            trailing: Switch(
              value: true,
              onChanged: null, // Always true for now based on requirements
              activeThumbColor: AppColors.sageGreenLight,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Notifications
          _buildSectionTitle('Smart Notifications'),
          _buildSettingsTile(
            icon: Icons.notifications_active_rounded,
            title: 'Allow Notifications',
            subtitle: 'Reminders for prayers, sleep, and streaks',
            trailing: Switch(
              value: true, // Typically managed by permissions
              onChanged: (val) {
                // Implementation for toggling permissions goes here
              },
              activeThumbColor: AppColors.sageGreenLight,
            ),
          ),
          
          const SizedBox(height: 24),

          // Account (Supabase placeholder)
          _buildSectionTitle('Account & Sync'),
          _buildSettingsTile(
            icon: Icons.cloud_sync_rounded,
            title: 'Cloud Backup',
            subtitle: 'Sync data to Supabase (Coming soon)',
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cloud sync requires authentication')),
              );
            },
          ),
          
          const SizedBox(height: 24),

          // Data Management
          _buildSectionTitle('Data Management'),
          _buildSettingsTile(
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
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
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
          const Center(
            child: Text(
              'Amal Tracker v1.0.0\nBuilt with Clean Architecture',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
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
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
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
            color: titleColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        trailing: trailing ?? (onTap != null 
            ? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted) 
            : null),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
