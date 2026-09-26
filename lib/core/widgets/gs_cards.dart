import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

// Base card with shadow
class GSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final Border? border;

  const GSCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppRadius.card,
    this.backgroundColor = AppColors.surface,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border ?? Border.all(color: AppColors.border, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// Status badge / tag
class GSTag extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;

  const GSTag(
      {super.key,
      required this.label,
      this.color = AppColors.primarySurface,
      this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: textColor ?? color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
