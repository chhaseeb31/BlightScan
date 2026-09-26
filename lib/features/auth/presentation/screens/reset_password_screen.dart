import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../core/widgets/gs_app_bar.dart';
import '../../../../core/widgets/gs_input_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passCtrl.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final result = await context
        .read<AuthSessionService>()
        .updatePassword(_passCtrl.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.isSuccess ? AppColors.success : AppColors.error,
      ),
    );

    if (result.isSuccess) {
      context.go(AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GSAppBar(title: 'Change Password', showBack: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
            vertical: AppSpacing.pageVertical,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Text('Secure Your Account', style: AppTextStyles.displayMedium),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Create a strong new password for your BlightScan account.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                GSInputField(
                  label: 'New Password',
                  hint: 'Enter new password',
                  controller: _passCtrl,
                  isPassword: true,
                  validator: InputValidators.strongPassword,
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.iconDefault,
                    size: 20,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Use at least 8 characters with uppercase, lowercase, and a number.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                GSInputField(
                  label: 'Confirm New Password',
                  hint: 'Confirm password',
                  controller: _confirmPassCtrl,
                  isPassword: true,
                  validator: _validateConfirmPassword,
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.iconDefault,
                    size: 20,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                GSButton(
                  label: 'Save New Password',
                  isLoading: _isLoading,
                  onPressed: _resetPassword,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
