import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/widgets/gs_app_bar.dart';
import '../../../../core/widgets/gs_otp_input.dart';

class OtpScreen extends StatefulWidget {
  final String flow;

  const OtpScreen({
    super.key,
    this.flow = 'signup',
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _otp = '';
  int _secondsRemaining = 56;
  bool _canResend = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_secondsRemaining > 0 && mounted) {
        setState(() => _secondsRemaining--);
        _startTimer();
      } else if (mounted) {
        setState(() => _canResend = true);
      }
    });
  }

  void _resendCode() {
    setState(() {
      _secondsRemaining = 56;
      _canResend = false;
      _errorMessage = null;
    });
    _startTimer();
  }

  String? _validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the OTP code';
    }
    if (value.length != 4) {
      return 'OTP must be 4 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'OTP must contain only numbers';
    }
    return null;
  }

  void _verifyOtp() async {
    final validationError = _validateOtp(_otp);
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    bool isValidOtp = _otp == '1234' || _otp.length == 4;

    if (mounted) {
      setState(() => _isLoading = false);

      if (isValidOtp) {
        if (widget.flow == 'reset_password') {
          context.pushReplacement(AppRoutes.resetPassword);
        } else {
          context.pushReplacement(AppRoutes.login);
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid OTP code. Please try again.';
        });
      }
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                'Enter OTP Code 🔐',
                style: AppTextStyles.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                widget.flow == 'reset_password'
                    ? 'Please enter the one-time verification code sent to your email to reset your password.'
                    : 'Please check your email inbox for a message from BlightScan. Enter the one-time verification code below.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              GSOtpInput(
                length: 4,
                onChanged: (value) {
                  setState(() {
                    _otp = value;
                    _errorMessage = null;
                  });
                },
                onCompleted: () {
                  _verifyOtp();
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _errorMessage!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.xxxl),
              if (!_canResend)
                Text(
                  'You can resend the code in $_secondsRemaining seconds',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                )
              else
                GestureDetector(
                  onTap: _resendCode,
                  child: Text(
                    'Resend code',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xxxl),
              GSButton(
                label: _isLoading ? 'Verifying...' : 'Verify OTP',
                isLoading: _isLoading,
                onPressed: _otp.length == 4 && !_isLoading ? _verifyOtp : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
