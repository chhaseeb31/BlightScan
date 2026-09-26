// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/widgets/gs_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Theme & Language
  String selectedTheme = 'Light';
  String selectedLanguage = 'English (US)';

  // Scan alert toggles
  bool scanQualityAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: const GSAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          // Scan alerts section
          _buildSection(
            label: 'SCAN ALERTS',
            children: [
              _ToggleTile(
                icon: Icons.notifications_active_outlined,
                label: 'Scan Quality Alerts',
                subtitle: 'Show warnings for blurry or low-light tomato leaf images',
                value: scanQualityAlerts,
                onChanged: (v) => setState(() => scanQualityAlerts = v),
                showDivider: false,
              ),
            ],
          ),

          // Account section
          _buildSection(
            label: 'ACCOUNT',
            children: [
              _NavTile(
                icon: Icons.lock_outline_rounded,
                label: 'Change Password',
                onTap: () => context.push(AppRoutes.resetPassword),
              ),
            ],
          ),

          // App Settings section
          _buildSection(
            label: 'APP SETTINGS',
            children: [
              _NavTile(
                icon: Icons.palette_outlined,
                label: 'Theme',
                trailing: selectedTheme,
                onTap: () => _showThemeDialog(context),
              ),
              _NavTile(
                icon: Icons.language_rounded,
                label: 'App Language',
                trailing: selectedLanguage,
                onTap: () => _showLanguageSheet(context),
                showDivider: false,
              ),
            ],
          ),

          // Support & Info section
          _buildSection(
            label: 'SUPPORT & INFO',
            children: [
              _NavTile(
                icon: Icons.info_outline_rounded,
                label: 'About BlightScan',
                onTap: () => context.push(AppRoutes.about),
              ),
              const _StaticTile(
                icon: Icons.verified_user_outlined,
                label: 'App Version',
                trailing: 'v1.0.0',
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildSection(
      {required String label, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal, 0, AppSpacing.pageHorizontal, 12),
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              fontSize: 11,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal, 0, AppSpacing.pageHorizontal, 24),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.dialog)),
        title: Text('Choose Theme', style: AppTextStyles.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['System Default', 'Light', 'Dark']
              .map(
                (t) => RadioListTile<String>(
                  title: Text(t, style: AppTextStyles.bodyMedium),
                  value: t,
                  groupValue: selectedTheme,
                  onChanged: (value) {
                    setState(() {
                      selectedTheme = value!;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full))),
            child: Text('OK',
                style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final langs = [
      ('🇺🇸', 'English (US)'),
      ('🇬🇧', 'English (UK)'),
      ('🇵🇰', 'Urdu'),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        maxChildSize: 0.45,
        minChildSize: 0.45,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.bottomSheet)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('App Language', style: AppTextStyles.headlineSmall),
              ),
              Expanded(
                child: ListView.builder(
                  controller: ctrl,
                  itemCount: langs.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedLanguage = langs[i].$2;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: selectedLanguage == langs[i].$2
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 1.5),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        color: selectedLanguage == langs[i].$2
                            ? AppColors.primarySurface
                            : Colors.transparent,
                      ),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 3),
                      child: Row(
                        children: [
                          Text(langs[i].$1,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(langs[i].$2,
                                  style: AppTextStyles.bodyMedium)),
                          if (selectedLanguage == langs[i].$2)
                            const Icon(Icons.check_rounded,
                                color: AppColors.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.white,
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 56, endIndent: 16),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  final bool showDivider;

  const _NavTile({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(label,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded,
                    size: 20, color: AppColors.iconDefault),
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 56, endIndent: 16),
      ],
    );
  }
}

class _StaticTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String trailing;
  final bool showDivider;

  const _StaticTile({
    required this.icon,
    required this.label,
    required this.trailing,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(label,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
              Text(
                trailing,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 56, endIndent: 16),
      ],
    );
  }
}
