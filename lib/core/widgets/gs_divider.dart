import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

class GSDividerWithText extends StatelessWidget {
  final String text;
  final Color? textColor;
  final Color? lineColor;

  const GSDividerWithText({
    super.key,
    required this.text,
    this.textColor,
    this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: lineColor ?? AppColors.border,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: textColor ?? AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: lineColor ?? AppColors.border,
          ),
        ),
      ],
    );
  }
}
