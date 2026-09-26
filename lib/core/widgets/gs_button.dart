import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../services/haptic_service.dart';

class GSButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;
  final double? width;
  final double height;
  final IconData? prefixIcon;
  final Widget? prefixWidget;

  const GSButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.width,
    this.height = AppSpacing.buttonHeight,
    this.prefixIcon,
    this.prefixWidget,
  });

  @override
  State<GSButton> createState() => _GSButtonState();
}

class _GSButtonState extends State<GSButton> {
  bool _isPressed = false;

  void _handleTap() {
    if (widget.isLoading) return;
    hapticService.lightImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: _handleTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  widget.isPrimary ? AppColors.primary : Colors.transparent,
              foregroundColor: widget.isPrimary
                  ? AppColors.textOnPrimary
                  : AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.0),
                side: widget.isPrimary
                    ? BorderSide.none
                    : const BorderSide(color: AppColors.primary),
              ),
              elevation: 0,
              padding: EdgeInsets.zero,
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textOnPrimary),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.prefixWidget != null) ...[
                        widget.prefixWidget!,
                        const SizedBox(width: 10),
                      ] else if (widget.prefixIcon != null) ...[
                        Icon(widget.prefixIcon, size: 20),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.label,
                        style: AppTextStyles.buttonText.copyWith(
                          color: widget.isPrimary
                              ? AppColors.textOnPrimary
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class GSOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final Color? textColor;
  final Color? borderColor;

  const GSOutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.width,
    this.height = AppSpacing.buttonHeight,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? AppColors.primary,
          side: BorderSide(
            color: borderColor ?? AppColors.border,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: AppTextStyles.buttonTextSecondary.copyWith(
            color: textColor ?? AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class GSSocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;

  const GSSocialButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          backgroundColor: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Row(
          children: [
            SizedBox(width: 24, height: 24, child: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GSIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;

  const GSIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 44,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: IconButton(
        icon: Icon(icon, size: iconSize, color: iconColor),
        onPressed: () {
          hapticService.lightImpact();
          onPressed?.call();
        },
      ),
    );
  }
}
