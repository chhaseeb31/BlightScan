import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/scan_controller.dart';

class AnalysisOverlay extends StatefulWidget {
  final ScanController controller;

  const AnalysisOverlay({super.key, required this.controller});

  @override
  State<AnalysisOverlay> createState() => _AnalysisOverlayState();
}

class _AnalysisOverlayState extends State<AnalysisOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent =
        (widget.controller.analysisProgress * 100).toInt().clamp(0, 100);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) => Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.16),
                          ),
                          child: Icon(Icons.auto_awesome_rounded,
                              size: 34, color: theme.colorScheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: CircularProgressIndicator(
                            value: widget.controller.analysisProgress,
                            strokeWidth: 5,
                            backgroundColor: theme.colorScheme.onSurface
                                .withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '$percent%',
                              style: AppTextStyles.displayMedium.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'AI CORE',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: theme.colorScheme.primary,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.controller.statusMessage,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMedium
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.controller.statusSubtitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
