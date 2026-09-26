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

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final result = await context
        .read<AuthSessionService>()
        .sendPasswordResetEmail(_emailCtrl.text);

    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.isSuccess ? AppColors.success : AppColors.error,
      ),
    );

    if (result.isSuccess) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GSAppBar(title: '', showBack: true),
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
                Text(
                  'Reset Your Password',
                  style: AppTextStyles.displayMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Enter your BlightScan account email. Firebase will send a secure password reset link to your inbox.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Text('Your Registered Email', style: AppTextStyles.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                GSInputField(
                  hint: 'Enter your email',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: InputValidators.email,
                  prefixIcon: const Icon(
                    Icons.mail_outline_rounded,
                    color: AppColors.iconDefault,
                    size: 20,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                GSButton(
                  label: 'Send Reset Link',
                  isLoading: _isLoading,
                  onPressed: _sendResetEmail,
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
