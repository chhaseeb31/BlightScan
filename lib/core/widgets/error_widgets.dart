import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../services/haptic_service.dart';

/// ErrorStateWidget - Fallback UI for error states
/// Provides retry capability and user-friendly error messages
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final IconData icon;
  final bool showBack;

  const ErrorStateWidget({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'We encountered an unexpected error. Please try again.',
    this.retryLabel = 'Try Again',
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: showBack,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 50,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  title,
                  style: AppTextStyles.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxxl),
                if (onRetry != null)
                  SizedBox(
                    width: double.infinity,
                    height: AppSpacing.buttonHeight,
                    child: ElevatedButton(
                      onPressed: () {
                        hapticService.mediumImpact();
                        onRetry!();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(retryLabel!),
                    ),
                  ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// NetworkErrorWidget - Specialized error widget for network failures
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      title: 'No Internet Connection',
      message: 'Please check your internet connection and try again.',
      icon: Icons.wifi_off_rounded,
      onRetry: onRetry,
    );
  }
}

/// ServerErrorWidget - Specialized error widget for server failures
class ServerErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const ServerErrorWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      title: 'Server Error',
      message:
          'Our servers are having trouble. Please try again in a few moments.',
      icon: Icons.cloud_off_rounded,
      onRetry: onRetry,
    );
  }
}

/// UnknownErrorWidget - Catch-all error widget
class UnknownErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const UnknownErrorWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      title: 'Unexpected Error',
      message: 'Something unexpected happened. Please try again.',
      icon: Icons.error_outline_rounded,
      onRetry: onRetry,
    );
  }
}
