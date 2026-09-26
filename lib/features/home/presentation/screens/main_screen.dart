import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/app_state_service.dart';
import '../../../../core/utils/app_routes.dart';

class MainScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({
    super.key,
    required this.navigationShell,
  });

  void _onTabTapped(BuildContext context, int index) {
    if (index == 2) {
      context.push(AppRoutes.scan);
      return;
    }
    AppStateService().saveRouteState(_routeForIndex(index));
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  String _routeForIndex(int index) {
    switch (index) {
      case 1:
        return AppRoutes.community;
      case 3:
        return AppRoutes.history;
      case 4:
        return AppRoutes.profile;
      default:
        return AppRoutes.main;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeBranchNavigator = _activeBranchNavigator;
    final isHomeRoot = navigationShell.currentIndex == 0;

    return PopScope(
      // Child routes and non-Home tabs are handled by this shell. Only a
      // childless Home branch is allowed to reach Android's root behavior.
      canPop: isHomeRoot && !(activeBranchNavigator?.canPop() ?? false),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (activeBranchNavigator?.canPop() == true) {
          await activeBranchNavigator!.maybePop();
          return;
        }

        if (navigationShell.currentIndex != 0) {
          AppStateService().saveRouteState(AppRoutes.main);
          navigationShell.goBranch(0, initialLocation: true);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: navigationShell,
        bottomNavigationBar: _GSBottomNavBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => _onTabTapped(context, index),
        ),
      ),
    );
  }

  NavigatorState? get _activeBranchNavigator =>
      AppRoutes.shellNavigatorKeys[navigationShell.currentIndex].currentState;
}

class _GSBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GSBottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bottomNavBackground,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 15,
            offset: Offset(0, -2),
            spreadRadius: 2,
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.people_outline_rounded,
                label: 'Community',
                index: 1,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _CameraCenter(onTap: () => onTap(2)),
              _NavItem(
                icon: Icons.history_outlined,
                label: 'History',
                index: 3,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                index: 4,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
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
    final bool isActive = index == currentIndex;
    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive
                  ? AppColors.bottomNavActive
                  : AppColors.bottomNavInactive,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isActive
                    ? AppColors.bottomNavActive
                    : AppColors.bottomNavInactive,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraCenter extends StatelessWidget {
  final VoidCallback onTap;

  const _CameraCenter({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.camera_alt_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
