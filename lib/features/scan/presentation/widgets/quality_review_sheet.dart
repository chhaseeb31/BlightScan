import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/image_quality_classifier.dart';
import '../providers/scan_controller.dart';

class QualityReviewSheet extends StatelessWidget {
  final ScanController controller;
  final VoidCallback onStartAnalysis;

  const QualityReviewSheet({
    super.key,
    required this.controller,
    required this.onStartAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classification = controller.qualityClassification;

    if (classification == null) {
      return _buildLoadingCard(context);
    }

    final level = classification.level;
    final accentColor = _getAccentColor(level);
    final icon = _getIcon(level);
    final title = _getTitle(level);
    final subtitle = _getSubtitle(level);
    final isAcceptable = classification.isAcceptable;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.74,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: classification.suggestions
                    .map((s) => _SuggestionChip(label: s))
                    .toList(),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (level != ImageQualityLevel.poor || isAcceptable)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: controller.retake,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Retake'),
                      ),
                    ),
                  if (level != ImageQualityLevel.poor || isAcceptable)
                    const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          (level == ImageQualityLevel.poor && !isAcceptable)
                              ? controller.retake
                              : onStartAnalysis,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: AppColors.textOnPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        (level == ImageQualityLevel.poor && !isAcceptable)
                            ? 'Retake'
                            : (level == ImageQualityLevel.good
                                ? 'Analyze'
                                : 'Analyze Anyway'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Checking quality...',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Analyzing your capture',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAccentColor(ImageQualityLevel level) {
    switch (level) {
      case ImageQualityLevel.good:
        return AppColors.success;
      case ImageQualityLevel.moderate:
        return AppColors.warning;
      case ImageQualityLevel.poor:
        return AppColors.error;
    }
  }

  IconData _getIcon(ImageQualityLevel level) {
    switch (level) {
      case ImageQualityLevel.good:
        return Icons.verified_rounded;
      case ImageQualityLevel.moderate:
        return Icons.warning_amber_rounded;
      case ImageQualityLevel.poor:
        return Icons.error_outline_rounded;
    }
  }

  String _getTitle(ImageQualityLevel level) {
    switch (level) {
      case ImageQualityLevel.good:
        return 'Excellent quality';
      case ImageQualityLevel.moderate:
        return 'Acceptable quality';
      case ImageQualityLevel.poor:
        return 'Poor quality';
    }
  }

  String _getSubtitle(ImageQualityLevel level) {
    switch (level) {
      case ImageQualityLevel.good:
        return 'Ready for AI analysis';
      case ImageQualityLevel.moderate:
        return 'Results may vary slightly';
      case ImageQualityLevel.poor:
        return 'Try capturing a clearer image';
    }
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  const _SuggestionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.86),
        ),
      ),
    );
  }
}
