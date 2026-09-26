import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../utils/navigation_utils.dart';
export 'gs_button.dart';

// Custom App Bar
class GSAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;
  final Widget? leading;
  final Color backgroundColor;
  final VoidCallback? onBackPressed;
  final String? fallbackRoute;

  const GSAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.actions,
    this.leading,
    this.backgroundColor = AppColors.background,
    this.onBackPressed,
    this.fallbackRoute,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.appBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: showBack
          ? (leading ??
              SafeBackButton(
                fallbackRoute: fallbackRoute,
                onPressed: onBackPressed,
              ))
          : leading,
      title: Text(title, style: AppTextStyles.appBarTitle),
      actions: actions,
    );
  }
}

// Bottom Navigation Bar
class GSBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GSBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bottomNavBackground,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: AppSpacing.bottomNavHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                  currentIndex: currentIndex,
                  onTap: onTap),
              _NavItem(
                  icon: Icons.shield_outlined,
                  label: 'Diagnose',
                  index: 1,
                  currentIndex: currentIndex,
                  onTap: onTap),
              _CameraNavItem(onTap: () => onTap(2)),
              _NavItem(
                  icon: Icons.history_outlined,
                  label: 'History',
                  index: 3,
                  currentIndex: currentIndex,
                  onTap: onTap),
              _NavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Account',
                  index: 4,
                  currentIndex: currentIndex,
                  onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive
                  ? AppColors.bottomNavActive
                  : AppColors.bottomNavInactive,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isActive
                    ? AppColors.bottomNavActive
                    : AppColors.bottomNavInactive,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraNavItem extends StatelessWidget {
  final VoidCallback onTap;

  const _CameraNavItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.camera_alt_rounded,
          color: AppColors.textOnPrimary,
          size: 28,
        ),
      ),
    );
  }
}

// Section header with "View All"
class GSSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const GSSectionHeader({super.key, required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.headlineSmall),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              children: [
                Text('View All',
                    style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded,
                    size: 16, color: AppColors.primary),
              ],
            ),
          ),
      ],
    );
  }
}

// Divider with "or"
class GSDividerWithText extends StatelessWidget {
  final String text;

  const GSDividerWithText({super.key, this.text = 'or'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text, style: AppTextStyles.bodySmall),
        ),
        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      ],
    );
  }
}
