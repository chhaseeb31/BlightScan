import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/navigation_utils.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile =
        _UserProfile.fromSession(context.watch<AuthSessionService>());
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, profile),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  _buildAccountSection(context),
                  const SizedBox(height: AppSpacing.xl),
                  _buildAppSection(context),
                  const SizedBox(height: AppSpacing.xl),
                  _buildLogoutButton(context),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, _UserProfile profile) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(45),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Profile avatar with edit button
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primarySurface,
                      child: Icon(Icons.person,
                          size: 50, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                profile.displayName,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile.displayEmail,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account Settings', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildMenuTile(
                icon: Icons.person_outline_rounded,
                label: 'Personal Information',
                onTap: () => context.push(AppRoutes.myProfile),
              ),
              _buildMenuTile(
                icon: Icons.history_rounded,
                label: 'Scan History',
                onTap: () => context.go(AppRoutes.history),
              ),
              _buildMenuTile(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                onTap: () => context.push(AppRoutes.notifications),
              ),
              _buildMenuTile(
                icon: Icons.security_rounded,
                label: 'Account Security',
                onTap: () => context.push(AppRoutes.settings),
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preferences', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildMenuTile(
                icon: Icons.settings_outlined,
                label: 'App Settings',
                onTap: () => context.push(AppRoutes.settings),
              ),
              _buildMenuTile(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                onTap: () => context.push(AppRoutes.help),
              ),
              _buildMenuTile(
                icon: Icons.info_outline_rounded,
                label: 'About BlightScan',
                onTap: () => context.push(AppRoutes.about),
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _showLogoutDialog(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        child: const Text('Log Out',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String label,
    String? trailing,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: Ink(
            child: ListTile(
              onTap: onTap,
              leading: Icon(icon, color: AppColors.primary, size: 22),
              title: Text(label, style: AppTextStyles.bodyMedium),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (trailing != null)
                    Text(
                      trailing,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.iconDefault),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(
              height: 1, indent: 56, endIndent: 16, color: AppColors.border),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.dialog)),
        title: Text('Log Out', style: AppTextStyles.headlineSmall),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthSessionService>().signOut();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full)),
            ),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// My Profile detail screen
class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile =
        _UserProfile.fromSession(context.watch<AuthSessionService>());
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('My Profile', style: AppTextStyles.appBarTitle),
        centerTitle: true,
        leading: const SafeBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primarySurface,
              child: Icon(Icons.person, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 28),
            _ProfileField(label: 'Full Name', value: profile.displayName),
            const SizedBox(height: 16),
            _ProfileField(label: 'Email', value: profile.displayEmail),
            const SizedBox(height: 16),
            _ProfileField(label: 'Phone Number', value: profile.displayPhone),
            const SizedBox(height: 16),
            _ProfileField(label: 'Farm Location', value: profile.displayFarm),
            const SizedBox(height: 16),
            _ProfileField(
                label: 'Primary Crop', value: profile.displayPrimaryCrop),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Text(
                'Profile data is created from Firebase Authentication and used to keep your scan history private.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserProfile {
  final String? name;
  final String? email;
  final String? phone;
  final String? farmLocation;
  final String? primaryCrop;
  final int totalScans;

  const _UserProfile({
    this.name,
    this.email,
    this.phone,
    this.farmLocation,
    this.primaryCrop,
    this.totalScans = 0,
  });

  factory _UserProfile.empty() => const _UserProfile(
        name: null,
        email: null,
        phone: null,
        farmLocation: null,
        primaryCrop: null,
        totalScans: 0,
      );

  factory _UserProfile.fromSession(AuthSessionService session) {
    final user = session.currentUser;
    if (user == null) {
      return _UserProfile.empty();
    }
    return _UserProfile(
      name: user.displayName,
      email: user.email,
      totalScans: 0,
    );
  }

  String get displayName =>
      name?.trim().isNotEmpty == true ? name!.trim() : 'Your Name';

  String get displayEmail =>
      email?.trim().isNotEmpty == true ? email!.trim() : 'you@example.com';

  String get displayPhone =>
      phone?.trim().isNotEmpty == true ? phone!.trim() : 'Not set';

  String get displayFarm => farmLocation?.trim().isNotEmpty == true
      ? farmLocation!.trim()
      : 'Sahiwal / Pakistan';

  String get displayPrimaryCrop =>
      primaryCrop?.trim().isNotEmpty == true ? primaryCrop!.trim() : 'Tomato';
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.titleSmall),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(value, style: AppTextStyles.bodyMedium),
        ),
      ],
    );
  }
}
