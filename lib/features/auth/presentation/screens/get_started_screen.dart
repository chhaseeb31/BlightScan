import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/widgets/gs_button.dart';
import '../../../../core/widgets/gs_logo.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
          child: Column(
            children: [
              const Spacer(),
              // Logo/Illustration
              const Center(
                child: GSLogo(size: 120),
              ),
              const SizedBox(height: 40),
              Text(
                'Detect Tomato Late Blight Early',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Scan tomato leaf images, view confidence-based results, and get practical treatment and prevention guidance.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              GSButton(
                label: 'Sign Up',
                onPressed: () => context.push(AppRoutes.signup),
              ),
              const SizedBox(height: 12),
              GSButton(
                label: 'Log In',
                isPrimary: false,
                onPressed: () => context.push(AppRoutes.login),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
