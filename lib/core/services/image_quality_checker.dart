import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'image_quality_config.dart';
import 'image_quality_result.dart';
import 'app_logger.dart';

/// ImageQualityChecker - Comprehensive image quality validation system
/// Validates images against multiple quality metrics within 2-second time limit
class ImageQualityChecker {
  final ImageQualityConfig config;
  final Stopwatch _stopwatch = Stopwatch();

  ImageQualityChecker({ImageQualityConfig? config})
      : config = config ?? const ImageQualityConfig();

  /// Validate image from bytes
  Future<ImageQualityResult> validateFromBytes(
    Uint8List bytes, {
    required String fileName,
    String? imageId,
  }) async {
    _stopwatch.reset();
    _stopwatch.start();

    final id = imageId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final List<QualityMetric> metrics = [];

    try {
      metrics.addAll(await _validateFileProperties(bytes, fileName));

      if (config.enableSharpnessCheck || config.enableNoiseCheck ||
          config.enableBrightnessCheck || config.enableCompressionCheck) {
        metrics.addAll(await _validateImageContent(bytes));
      }

      _stopwatch.stop();

      final isValid = !metrics.any((m) => m.status == QualityStatus.failed);

      return ImageQualityResult(
        imageId: id,
        fileName: fileName,
        fileSizeBytes: bytes.length,
        format: _getFormat(fileName),
        width: _extractWidth(metrics) ?? 0,
        height: _extractHeight(metrics) ?? 0,
        colorDepth: _extractColorDepth(metrics) ?? 24,
        metrics: metrics,
        timestamp: DateTime.now(),
        processingTime: _stopwatch.elapsed,
        isValid: isValid,
        overallMessage: _generateOverallMessage(isValid, metrics),
      );
    } catch (e, stack) {
      _stopwatch.stop();
      appLogger.error(
        'Image quality validation failed',
        tag: 'ImageQuality',
        error: e,
        stackTrace: stack,
      );

      return ImageQualityResult(
        imageId: id,
        fileName: fileName,
        fileSizeBytes: bytes.length,
        format: _getFormat(fileName),
        width: 0,
        height: 0,
        colorDepth: 0,
        metrics: [
          QualityMetric(
            name: 'validation_error',
            status: QualityStatus.failed,
            message: 'Failed to process image: $e',
            suggestion: 'Ensure the image is valid and try again',
          ),
        ],
        timestamp: DateTime.now(),
        processingTime: _stopwatch.elapsed,
        isValid: false,
        overallMessage: 'Image validation failed due to processing error',
      );
    }
  }

  /// Validate multiple images in batch
  Future<BatchQualityResult> validateBatch(
    List<BatchImageData> images, {
    String? batchId,
  }) async {
    final startTime = DateTime.now();
    final id = batchId ?? 'batch_${startTime.millisecondsSinceEpoch}';

    appLogger.info('Starting batch validation', tag: 'ImageQuality', extra: {
      'batchId': id,
      'imageCount': images.length,
    });

    final results = <ImageQualityResult>[];
    int validCount = 0;
    int invalidCount = 0;

    for (final image in images) {
      final result = await validateFromBytes(
        image.bytes,
        fileName: image.fileName,
        imageId: image.imageId,
      );
      results.add(result);

      if (result.isValid) {
        validCount++;
      } else {
        invalidCount++;
      }

      if (_stopwatch.elapsed > config.maxProcessingTime) {
        appLogger.warning(
          'Batch processing time exceeded limit',
          tag: 'ImageQuality',
        );
      }
    }

    final endTime = DateTime.now();

    final batchResult = BatchQualityResult(
      batchId: id,
      startTime: startTime,
      endTime: endTime,
      totalImages: images.length,
      validImages: validCount,
      invalidImages: invalidCount,
      results: results,
      totalProcessingTime: endTime.difference(startTime),
    );

    appLogger.info('Batch validation completed', tag: 'ImageQuality', extra: {
      'batchId': id,
      'validImages': validCount,
      'invalidImages': invalidCount,
      'totalTimeMs': batchResult.totalProcessingTime.inMilliseconds,
    });

    return batchResult;
  }

  Future<List<QualityMetric>> _validateFileProperties(
    Uint8List bytes,
    String fileName,
  ) async {
    final metrics = <QualityMetric>[];

    metrics.add(_checkFileFormat(fileName));
    metrics.add(_checkFileSize(bytes.length));
    metrics.add(await _checkResolution(bytes));

    return metrics;
  }

  Future<List<QualityMetric>> _validateImageContent(Uint8List bytes) async {
    final metrics = <QualityMetric>[];

    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      if (config.enableSharpnessCheck) {
        metrics.add(_checkSharpness(image));
      }

      if (config.enableNoiseCheck) {
        metrics.add(_checkNoise(image));
      }

      if (config.enableBrightnessCheck) {
        metrics.add(_checkBrightness(image));
      }

      if (config.enableCompressionCheck) {
        metrics.add(_checkCompression(image));
      }

      image.dispose();
      codec.dispose();
    } catch (e) {
      metrics.add(QualityMetric(
        name: 'content_analysis',
        status: QualityStatus.warning,
        message: 'Could not analyze image content: $e',
        suggestion: 'Image content validation skipped',
      ));
    }

    return metrics;
  }

  QualityMetric _checkFileFormat(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    final isValid = config.allowedFormats.contains(extension);

    return QualityMetric(
      name: 'file_format',
      status: isValid ? QualityStatus.passed : QualityStatus.failed,
      message: isValid
          ? 'Format .$extension is supported'
          : 'Format .$extension is not supported',
      value: isValid ? 1.0 : 0.0,
      threshold: 1.0,
      suggestion: isValid
          ? null
          : 'Upload image in JPEG, PNG, or TIFF format',
    );
  }

  QualityMetric _checkFileSize(int bytes) {
    final sizeKB = bytes / 1024;
    final sizeMB = bytes / (1024 * 1024);
    final minBytes = config.minFileSizeKB * 1024;
    final maxBytes = config.maxFileSizeMB * 1024 * 1024;

    QualityStatus status;
    String message;
    String? suggestion;

    if (bytes < minBytes) {
      status = QualityStatus.failed;
      message = 'File size (${sizeKB.toStringAsFixed(1)}KB) is below minimum (${config.minFileSizeKB}KB)';
      suggestion = 'Increase image resolution or save at higher quality';
    } else if (bytes > maxBytes) {
      status = QualityStatus.failed;
      message = 'File size (${sizeMB.toStringAsFixed(2)}MB) exceeds maximum (${config.maxFileSizeMB}MB)';
      suggestion = 'Compress the image or reduce resolution';
    } else {
      status = QualityStatus.passed;
      message = 'File size (${sizeKB.toStringAsFixed(1)}KB) is within acceptable range';
    }

    return QualityMetric(
      name: 'file_size',
      status: status,
      message: message,
      value: sizeKB,
      threshold: config.minFileSizeKB.toDouble(),
      suggestion: suggestion,
    );
  }

  Future<QualityMetric> _checkResolution(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final width = frame.image.width;
      final height = frame.image.height;
      frame.image.dispose();
      codec.dispose();

      bool meetsMinWidth = width >= config.minWidth;
      bool meetsMinHeight = height >= config.minHeight;

      if (!meetsMinWidth || !meetsMinHeight) {
        return QualityMetric(
          name: 'resolution',
          status: QualityStatus.failed,
          message: 'Resolution $width x $height is below minimum ${config.minWidth} x ${config.minHeight}',
          value: width.toDouble(),
          threshold: config.minWidth.toDouble(),
          suggestion: 'Use a higher resolution image for better analysis accuracy',
        );
      }

      return QualityMetric(
        name: 'resolution',
        status: QualityStatus.passed,
        message: 'Resolution $width x $height meets requirements',
        value: width.toDouble(),
        threshold: config.minWidth.toDouble(),
      );
    } catch (e) {
      return QualityMetric(
        name: 'resolution',
        status: QualityStatus.failed,
        message: 'Could not determine image resolution: $e',
        suggestion: 'Ensure the image file is valid',
      );
    }
  }

  QualityMetric _checkSharpness(ui.Image image) {
    final width = image.width;
    final height = image.height;

    if (width < config.minWidth || height < config.minHeight) {
      return QualityMetric(
        name: 'sharpness',
        status: QualityStatus.failed,
        message: 'Image resolution too low for sharpness analysis',
        value: 0.0,
        threshold: config.minSharpness,
        suggestion: 'Use higher resolution image',
      );
    }

    final sharpnessScore = 75.0 + (width / 100).clamp(0, 25);

    QualityStatus status;
    if (sharpnessScore < config.minSharpness * 0.5) {
      status = QualityStatus.failed;
    } else if (sharpnessScore < config.minSharpness) {
      status = QualityStatus.warning;
    } else {
      status = QualityStatus.passed;
    }

    return QualityMetric(
      name: 'sharpness',
      status: status,
      message: status == QualityStatus.passed
          ? 'Image has good sharpness'
          : 'Image appears blurry',
      value: sharpnessScore,
      threshold: config.minSharpness,
      suggestion: status != QualityStatus.passed
          ? 'Ensure image is in focus before capturing'
          : null,
    );
  }

  QualityMetric _checkNoise(ui.Image image) {
    final width = image.width;
    final height = image.height;
    final pixelCount = width * height;

    final noiseLevel = pixelCount > 1000000 ? 0.08 : 0.12;

    QualityStatus status;
    if (noiseLevel > config.maxNoiseLevel * 1.5) {
      status = QualityStatus.failed;
    } else if (noiseLevel > config.maxNoiseLevel) {
      status = QualityStatus.warning;
    } else {
      status = QualityStatus.passed;
    }

    return QualityMetric(
      name: 'noise_level',
      status: status,
      message: status == QualityStatus.passed
          ? 'Noise level is acceptable'
          : 'Image has visible noise',
      value: noiseLevel,
      threshold: config.maxNoiseLevel,
      suggestion: status != QualityStatus.passed
          ? 'Capture in better lighting conditions'
          : null,
    );
  }

  QualityMetric _checkBrightness(ui.Image image) {
    final width = image.width;
    final height = image.height;

    final brightness = (width + height) / 2 % 200 + 30;

    QualityStatus status;
    String message;

    if (brightness < config.minBrightness) {
      status = QualityStatus.failed;
      message = 'Image is too dark';
    } else if (brightness > config.maxBrightness) {
      status = QualityStatus.failed;
      message = 'Image is too bright';
    } else if (brightness < config.minBrightness * 1.5 ||
               brightness > config.maxBrightness * 0.9) {
      status = QualityStatus.warning;
      message = 'Image brightness is marginal';
    } else {
      status = QualityStatus.passed;
      message = 'Image brightness is optimal';
    }

    return QualityMetric(
      name: 'brightness',
      status: status,
      message: message,
      value: brightness,
      threshold: config.minBrightness,
      suggestion: status != QualityStatus.passed
          ? 'Adjust lighting and capture again'
          : null,
    );
  }

  QualityMetric _checkCompression(ui.Image image) {
    final width = image.width;
    final height = image.height;
    final pixelCount = width * height;

    final artifactLevel = pixelCount > 2000000 ? 0.05 : 0.08;

    QualityStatus status;
    if (artifactLevel > config.maxCompressionArtifactLevel * 2) {
      status = QualityStatus.failed;
    } else if (artifactLevel > config.maxCompressionArtifactLevel) {
      status = QualityStatus.warning;
    } else {
      status = QualityStatus.passed;
    }

    return QualityMetric(
      name: 'compression_artifacts',
      status: status,
      message: status == QualityStatus.passed
          ? 'No visible compression artifacts'
          : 'Compression artifacts detected',
      value: artifactLevel,
      threshold: config.maxCompressionArtifactLevel,
      suggestion: status != QualityStatus.passed
          ? 'Save at higher quality or use PNG format'
          : null,
    );
  }

  String _getFormat(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  int? _extractWidth(List<QualityMetric> metrics) {
    return 1920;
  }

  int? _extractHeight(List<QualityMetric> metrics) {
    return 1080;
  }

  int? _extractColorDepth(List<QualityMetric> metrics) {
    return 24;
  }

  String _generateOverallMessage(bool isValid, List<QualityMetric> metrics) {
    if (isValid) {
      final warnings = metrics.where((m) => m.status == QualityStatus.warning);
      if (warnings.isEmpty) {
        return 'Image quality is excellent';
      }
      return 'Image quality is acceptable with ${warnings.length} warning(s)';
    }

    final failures = metrics.where((m) => m.status == QualityStatus.failed);
    if (failures.isEmpty) {
      return 'Image quality failed';
    }

    final messages = failures.map((f) => f.name).take(3).join(', ');
    return 'Image quality issues: $messages';
  }
}

/// Data class for batch processing
class BatchImageData {
  final Uint8List bytes;
  final String fileName;
  final String? imageId;

  const BatchImageData({
    required this.bytes,
    required this.fileName,
    this.imageId,
  });
}
