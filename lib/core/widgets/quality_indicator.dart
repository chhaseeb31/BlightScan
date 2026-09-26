import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../services/image_quality_classifier.dart';
import '../services/image_quality_result.dart';

/// QualityIndicator - Real-time quality feedback widget
/// Shows quality level with color-coded indicator
class QualityIndicator extends StatelessWidget {
  final ImageQualityLevel level;
  final bool showLabel;
  final double size;

  const QualityIndicator({
    super.key,
    required this.level,
    this.showLabel = true,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _indicatorColor,
              shape: BoxShape.circle,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 8),
            Text(
              _labelText,
              style: AppTextStyles.labelSmall.copyWith(
                color: _textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color get _indicatorColor {
    switch (level) {
      case ImageQualityLevel.good:
        return AppColors.success;
      case ImageQualityLevel.moderate:
        return AppColors.warning;
      case ImageQualityLevel.poor:
        return AppColors.error;
    }
  }

  Color get _backgroundColor {
    switch (level) {
      case ImageQualityLevel.good:
        return AppColors.success;
      case ImageQualityLevel.moderate:
        return AppColors.warning;
      case ImageQualityLevel.poor:
        return AppColors.error;
    }
  }

  Color get _borderColor {
    switch (level) {
      case ImageQualityLevel.good:
        return AppColors.success.withValues(alpha: 0.3);
      case ImageQualityLevel.moderate:
        return AppColors.warning.withValues(alpha: 0.3);
      case ImageQualityLevel.poor:
        return AppColors.error.withValues(alpha: 0.3);
    }
  }

  Color get _textColor {
    switch (level) {
      case ImageQualityLevel.good:
        return AppColors.success;
      case ImageQualityLevel.moderate:
        return AppColors.warning;
      case ImageQualityLevel.poor:
        return AppColors.error;
    }
  }

  String get _labelText {
    switch (level) {
      case ImageQualityLevel.good:
        return 'Good';
      case ImageQualityLevel.moderate:
        return 'Moderate';
      case ImageQualityLevel.poor:
        return 'Poor';
    }
  }
}

/// QualitySuggestionsPanel - Shows improvement suggestions
class QualitySuggestionsPanel extends StatelessWidget {
  final List<String> suggestions;
  final VoidCallback? onRetake;

  const QualitySuggestionsPanel({
    super.key,
    required this.suggestions,
    this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tips_and_updates_outlined,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'How to improve',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...suggestions.map((suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          if (onRetake != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRetake,
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Retake Photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// QualityMetricsDisplay - Shows detailed metric breakdown
class QualityMetricsDisplay extends StatelessWidget {
  final List<QualityMetric> metrics;
  final bool expanded;

  const QualityMetricsDisplay({
    super.key,
    required this.metrics,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quality Details',
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...metrics.map((metric) => _buildMetricRow(metric)),
        ],
      ),
    );
  }

  Widget _buildMetricRow(QualityMetric metric) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _statusColor(metric.status).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _statusIcon(metric.status),
              size: 14,
              color: _statusColor(metric.status),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatName(metric.name),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  metric.message,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(QualityStatus status) {
    switch (status) {
      case QualityStatus.passed:
        return AppColors.success;
      case QualityStatus.warning:
        return AppColors.warning;
      case QualityStatus.failed:
        return AppColors.error;
    }
  }

  IconData _statusIcon(QualityStatus status) {
    switch (status) {
      case QualityStatus.passed:
        return Icons.check;
      case QualityStatus.warning:
        return Icons.warning;
      case QualityStatus.failed:
        return Icons.close;
    }
  }

  String _formatName(String name) {
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

/// AnimatedQualityIndicator - Animated version with pulse effect
class AnimatedQualityIndicator extends StatefulWidget {
  final ImageQualityLevel level;
  final double size;

  const AnimatedQualityIndicator({
    super.key,
    required this.level,
    this.size = 12,
  });

  @override
  State<AnimatedQualityIndicator> createState() =>
      _AnimatedQualityIndicatorState();
}

class _AnimatedQualityIndicatorState extends State<AnimatedQualityIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.level == ImageQualityLevel.poor) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedQualityIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.level == ImageQualityLevel.poor) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size * _animation.value,
          height: widget.size * _animation.value,
          decoration: BoxDecoration(
            color: _color,
            shape: BoxShape.circle,
            boxShadow: widget.level == ImageQualityLevel.poor
                ? [
                    BoxShadow(
                      color: _color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }

  Color get _color {
    switch (widget.level) {
      case ImageQualityLevel.good:
        return AppColors.success;
      case ImageQualityLevel.moderate:
        return AppColors.warning;
      case ImageQualityLevel.poor:
        return AppColors.error;
    }
  }
}
