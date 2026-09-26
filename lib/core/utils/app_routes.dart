// lib/core/utils/app_routes.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/get_started_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/community/presentation/screens/create_post_screen.dart';
import '../../features/help/presentation/screens/help_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/main_screen.dart';
import '../../features/notifications/presentation/screens/notification_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/screens/about_app_screen.dart';
import '../../features/result/presentation/screens/result_screen.dart';
import '../../features/result/presentation/screens/treatment_plan_screen.dart';
import '../../features/scan/domain/models/scan_result.dart';
import '../../features/scan/presentation/screens/scan_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../config/app_config.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/auth_session_service.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String getStarted = '/get-started';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String otp = '/otp';
  static const String resetPassword = '/reset-password';
  static const String forgotPassword = '/forgot-password';
  static const String main = '/main';
  static const String community = '/community';
  static const String createPost = '/community/create';
  static const String scan = '/scan';
  static const String result = '/result';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String myProfile = '/profile/me';
  static const String settings = '/settings';
  static const String help = '/help';
  static const String about = '/about';
  static const String notifications = '/notifications';

  /// Hero animation tag shared across Scan → Result → Treatment.
  static const String scanImageHeroTag = 'scan_captured_leaf_image';

  static const Set<String> _publicRoutes = {
    splash,
    onboarding,
    getStarted,
    login,
    signup,
    forgotPassword,
  };

  static const Set<String> _signedInRedirectRoutes = {
    onboarding,
    getStarted,
    login,
    signup,
    otp,
  };

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final List<GlobalKey<NavigatorState>> shellNavigatorKeys = [
    GlobalKey<NavigatorState>(debugLabel: 'shell_home'),
    GlobalKey<NavigatorState>(debugLabel: 'shell_community'),
    GlobalKey<NavigatorState>(debugLabel: 'shell_scan'),
    GlobalKey<NavigatorState>(debugLabel: 'shell_history'),
    GlobalKey<NavigatorState>(debugLabel: 'shell_profile'),
  ];

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: splash,
    debugLogDiagnostics: AppConfig.isDevelopment,
    errorBuilder: (context, state) => const _RouteErrorScreen(),
    refreshListenable: authSession,
    redirect: (context, state) {
      final path = state.uri.path;
      final isPublicRoute = _publicRoutes.contains(path);

      if (!authSession.isReady) return null;
      if (!authSession.isSignedIn && !isPublicRoute) return login;
      if (authSession.isSignedIn && _signedInRedirectRoutes.contains(path)) {
        return main;
      }
      return null;
    },
    routes: [
      GoRoute(path: splash, builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: getStarted,
        builder: (context, state) => const GetStartedScreen(),
      ),
      GoRoute(path: login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: signup, builder: (context, state) => const SignupScreen()),
      GoRoute(
        path: createPost,
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: otp,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final flow = extra?['flow'] as String? ?? 'signup';
          return OtpScreen(flow: flow);
        },
      ),
      GoRoute(
        path: forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: shellNavigatorKeys[0],
            routes: [
              GoRoute(path: main, builder: (_, __) => const HomeScreen())
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellNavigatorKeys[1],
            routes: [
              GoRoute(
                  path: community, builder: (_, __) => const CommunityScreen()),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellNavigatorKeys[2],
            routes: [
              GoRoute(
                path: '/scan-tab',
                builder: (context, state) => const Offstage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellNavigatorKeys[3],
            routes: [
              GoRoute(path: history, builder: (_, __) => const HistoryScreen()),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellNavigatorKeys[4],
            routes: [
              GoRoute(path: profile, builder: (_, __) => const ProfileScreen()),
            ],
          ),
        ],
      ),
      GoRoute(path: scan, builder: (context, state) => const ScanScreen()),
      GoRoute(
        path: result,
        builder: (context, state) {
          final scanResult =
              state.extra is ScanResult ? state.extra as ScanResult : null;
          return ResultScreen(scanResult: scanResult);
        },
        routes: [
          GoRoute(
            path: 'detail',
            builder: (context, state) {
              final scanResult =
                  state.extra is ScanResult ? state.extra as ScanResult : null;
              return TreatmentPlanScreen(scanResult: scanResult);
            },
          ),
        ],
      ),
      GoRoute(path: settings, builder: (_, __) => const SettingsScreen()),
      GoRoute(path: myProfile, builder: (_, __) => const MyProfileScreen()),
      GoRoute(path: help, builder: (_, __) => const HelpScreen()),
      GoRoute(path: about, builder: (_, __) => const AboutAppScreen()),
      GoRoute(
        path: notifications,
        builder: (context, state) => const NotificationScreen(),
      ),
    ],
  );
}

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Unable to load screen',
                    style: AppTextStyles.headlineSmall),
                const SizedBox(height: 8),
                Text('Please try again.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.splash),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Text('Retry', style: AppTextStyles.buttonText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
