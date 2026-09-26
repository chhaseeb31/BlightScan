import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../providers/scan_controller.dart';

class ScanCameraPreview extends StatelessWidget {
  final ScanController controller;

  const ScanCameraPreview({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (controller.capturedImage != null &&
        controller.currentState != ScanUIState.idle) {
      if (kIsWeb) {
        return Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: Icon(
            Icons.image_not_supported_outlined,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            size: 48,
          ),
        );
      }

      final mediaQuery = MediaQuery.of(context);
      return Image.file(
        File(controller.capturedImage!.path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: (mediaQuery.size.width * mediaQuery.devicePixelRatio)
            .round()
            .clamp(1, 1600),
        cacheHeight: (mediaQuery.size.height * mediaQuery.devicePixelRatio)
            .round()
            .clamp(1, 2400),
      );
    }

    if (controller.isInitialized && controller.cameraController != null) {
      final previewSize = controller.cameraController!.value.previewSize;
      return ColoredBox(
        color: Colors.black,
        child: previewSize == null
            ? CameraPreview(controller.cameraController!)
            : FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: previewSize.height,
                  height: previewSize.width,
                  child: CameraPreview(controller.cameraController!),
                ),
              ),
      );
    }

    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Initializing Camera',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
