import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Centralized logo widget for BlightScan app branding.
class GSLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final bool usePlaceholderIfFailed;

  const GSLogo({
    super.key,
    this.size = 24.0,
    this.color,
    this.usePlaceholderIfFailed = true,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/blightscan_logo.png',
      width: size,
      height: size,
      color: color,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        if (!usePlaceholderIfFailed) return const SizedBox.shrink();

        // Minimal professional fallback if image fails
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.circle,
              size: size * 0.5,
              color: color ?? AppColors.primary,
            ),
          ),
        );
      },
    );
  }
}
