import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/scan_history_service.dart';
import '../../../../core/utils/app_routes.dart';
import '../providers/scan_controller.dart';
import '../widgets/analysis_overlay.dart';
import '../widgets/quality_review_sheet.dart';
import '../widgets/scan_camera_preview.dart';
import '../widgets/scan_controls.dart';
import '../widgets/scan_overlay.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ScanController(
        historyService: context.read<ScanHistoryService>(),
      )..initializeCamera(),
      child: const _ScanScreenContent(),
    );
  }
}

class _ScanScreenContent extends StatefulWidget {
  const _ScanScreenContent();

  @override
  State<_ScanScreenContent> createState() => _ScanScreenContentState();
}

class _ScanScreenContentState extends State<_ScanScreenContent> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ScanController>();
    final theme = Theme.of(context);

    if (controller.initError != null) {
      return _ErrorState(
          error: controller.initError!, onRetry: controller.initializeCamera);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.black,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final mediaQuery = MediaQuery.of(context);
            final topInset = mediaQuery.padding.top;
            final bottomInset = mediaQuery.padding.bottom;
            final frameWidth = (constraints.maxWidth - 64).clamp(220.0, 300.0);
            final frameHeight = frameWidth * 1.35;
            const frameBorderRadius = 16.0;
            const topControlsHeight = 64.0;
            const bottomControlsHeight = 112.0;
            final usableTop = topInset + topControlsHeight;
            final usableBottom =
                constraints.maxHeight - bottomInset - bottomControlsHeight;
            final usableHeight = math.max(0.0, usableBottom - usableTop);
            final frameRect = Rect.fromLTWH(
              (constraints.maxWidth - frameWidth) / 2,
              usableTop + math.max(0.0, (usableHeight - frameHeight) / 2),
              frameWidth,
              frameHeight,
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: ScanCameraPreview(controller: controller),
                ),
                if (controller.currentState != ScanUIState.analyzing)
                  Positioned.fill(
                    child: ScanOverlay(
                      frameRect: frameRect,
                      borderRadius: frameBorderRadius,
                      accentColor: theme.colorScheme.primary,
                    ),
                  ),
                if (controller.currentState == ScanUIState.analyzing)
                  Positioned.fill(
                    child: AnalysisOverlay(controller: controller),
                  ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: bottomInset + 16,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: _buildBottomOverlay(context, controller),
                  ),
                ),
                Positioned.fill(
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        _TopBar(controller: controller),
                        const Spacer(),
                        if (controller.currentState == ScanUIState.idle)
                          Padding(
                            padding: EdgeInsets.only(bottom: bottomInset + 8),
                            child: ScanControls(
                              controller: controller,
                              onShowGuide: () => _showScanGuide(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomOverlay(BuildContext context, ScanController controller) {
    if (controller.currentState == ScanUIState.qualityCheck ||
        controller.currentState == ScanUIState.preview) {
      return QualityReviewSheet(
        controller: controller,
        onStartAnalysis: () async {
          final ok = await controller.prepareForAnalysis();
          if (!ok || !context.mounted) return;

          try {
            final result = await controller.startAnalysis();
            if (result != null && context.mounted) {
              context.pushReplacement(AppRoutes.result, extra: result);
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          }
        },
      );
    }
    return const SizedBox.shrink();
  }

  void _showScanGuide(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scanning Tips',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _guideTip(context, 'Place leaf inside the frame'),
            _guideTip(context, 'Ensure entire leaf is visible'),
            _guideTip(context, 'Use good natural lighting'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideTip(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.check_circle,
              color: Theme.of(context).colorScheme.primary, size: 16),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final ScanController controller;
  const _TopBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _CircleAction(
            icon: Icons.close_rounded,
            onTap: () => context.pop(),
          ),
          const Spacer(),
          if (controller.currentState == ScanUIState.idle)
            _CircleAction(
              icon: controller.flashMode == FlashMode.off
                  ? Icons.flash_off_rounded
                  : Icons.flash_on_rounded,
              onTap: controller.toggleFlash,
            ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 22),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        fixedSize: const Size(48, 48),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined,
                  size: 64, color: AppColors.primary),
              const SizedBox(height: 20),
              Text('Camera Error',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      )),
              const SizedBox(height: 12),
              Text(error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 32),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
