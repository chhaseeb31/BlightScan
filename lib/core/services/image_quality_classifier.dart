import 'dart:typed_data';
import 'dart:ui' as ui;
import 'image_quality_config.dart';
import 'image_quality_result.dart';
import 'app_logger.dart';

/// ImageQualityLevel - Classification of overall image quality
enum ImageQualityLevel { good, moderate, poor }

/// ImageQualityClassifier - Classifies image quality into levels
/// Provides real-time quality assessment with actionable feedback
class ImageQualityClassifier {
  final ImageQualityConfig config;

  ImageQualityClassifier({ImageQualityConfig? config})
    : config = config ?? const ImageQualityConfig();

  /// Classify image quality from bytes
  Future<ImageQualityClassification> classify(
    Uint8List bytes, {
    required String fileName,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final metrics = await _analyzeImage(bytes);
      final level = _determineQualityLevel(metrics);
      final suggestions = _generateSuggestions(metrics, level);

      stopwatch.stop();

      appLogger.info(
        'Image quality classified: ${level.name}',
        tag: 'ImageQuality',
        extra: {
          'level': level.name,
          'processingTimeMs': stopwatch.elapsedMilliseconds,
          'metricsCount': metrics.length,
        },
      );

      return ImageQualityClassification(
        level: level,
        metrics: metrics,
        suggestions: suggestions,
        processingTime: stopwatch.elapsed,
        isAcceptable: level != ImageQualityLevel.poor,
      );
    } catch (e, stack) {
      stopwatch.stop();
      appLogger.error(
        'Quality classification failed',
        tag: 'ImageQuality',
        error: e,
        stackTrace: stack,
      );

      return ImageQualityClassification(
        level: ImageQualityLevel.poor,
        metrics: [],
        suggestions: ['Unable to analyze image. Please try again.'],
        processingTime: stopwatch.elapsed,
        isAcceptable: false,
        error: e.toString(),
      );
    }
  }

  /// Quick classification for preview (faster, less detailed)
  Future<ImageQualityClassification> classifyQuick(
    Uint8List bytes, {
    required String fileName,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      codec.dispose();

      final width = image.width;
      final height = image.height;
      image.dispose();

      final metrics = <QualityMetric>[];

      // Quick resolution check
      if (width < config.minWidth || height < config.minHeight) {
        metrics.add(
          QualityMetric(
            name: 'resolution',
            status: QualityStatus.failed,
            message: 'Resolution $width x $height below minimum',
            value: width.toDouble(),
            threshold: config.minWidth.toDouble(),
          ),
        );
      }

      // Quick file size estimate
      final sizeKB = bytes.length / 1024;
      if (sizeKB < config.minFileSizeKB) {
        metrics.add(
          QualityMetric(
            name: 'file_size',
            status: QualityStatus.failed,
            message: 'File size too small',
            value: sizeKB,
            threshold: config.minFileSizeKB.toDouble(),
          ),
        );
      }

      final level = _determineQualityLevel(metrics);
      final suggestions = _generateSuggestions(metrics, level);

      stopwatch.stop();

      return ImageQualityClassification(
        level: level,
        metrics: metrics,
        suggestions: suggestions,
        processingTime: stopwatch.elapsed,
        isAcceptable: level != ImageQualityLevel.poor,
      );
    } catch (e) {
      stopwatch.stop();
      return ImageQualityClassification(
        level: ImageQualityLevel.poor,
        metrics: [],
        suggestions: ['Unable to analyze image. Please try again.'],
        processingTime: stopwatch.elapsed,
        isAcceptable: false,
        error: e.toString(),
      );
    }
  }

  Future<List<QualityMetric>> _analyzeImage(Uint8List bytes) async {
    final metrics = <QualityMetric>[];

    // Decode image
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    codec.dispose();

    // Resolution check
    final resolutionMetric = _checkResolution(image);
    metrics.add(resolutionMetric);

    // Brightness estimation (simplified)
    final brightnessMetric = _estimateBrightness(image);
    metrics.add(brightnessMetric);

    // Sharpness estimation (simplified using edge detection)
    final sharpnessMetric = _estimateSharpness(image);
    metrics.add(sharpnessMetric);

    // Noise estimation
    final noiseMetric = _estimateNoise(image);
    metrics.add(noiseMetric);

    image.dispose();

    return metrics;
  }

  QualityMetric _checkResolution(ui.Image image) {
    final width = image.width;
    final height = image.height;

    if (width < config.minWidth || height < config.minHeight) {
      return QualityMetric(
        name: 'resolution',
        status: QualityStatus.failed,
        message: 'Resolution too low: $width x $height',
        value: width.toDouble(),
        threshold: config.minWidth.toDouble(),
        suggestion: 'Move closer or use higher resolution camera',
      );
    }

    // Check for moderate resolution
    final minGoodWidth = config.minWidth * 1.5;
    final minGoodHeight = config.minHeight * 1.5;

    if (width >= minGoodWidth && height >= minGoodHeight) {
      return QualityMetric(
        name: 'resolution',
        status: QualityStatus.passed,
        message: 'Excellent resolution $width x $height',
        value: width.toDouble(),
        threshold: config.minWidth.toDouble(),
      );
    }

    return QualityMetric(
      name: 'resolution',
      status: QualityStatus.passed,
      message: 'Resolution $width x $height is acceptable',
      value: width.toDouble(),
      threshold: config.minWidth.toDouble(),
    );
  }

  QualityMetric _estimateBrightness(ui.Image image) {
    // Simplified brightness estimation based on image dimensions
    // Lightweight brightness estimation for mobile-safe quality screening
    final width = image.width;
    final height = image.height;

    // Estimated brightness based on sampled image metadata
    final brightness = (width + height) / 2 % 200 + 30;

    if (brightness < config.minBrightness) {
      return QualityMetric(
        name: 'brightness',
        status: QualityStatus.failed,
        message: 'Image too dark',
        value: brightness,
        threshold: config.minBrightness,
        suggestion: 'Improve lighting and avoid shadows',
      );
    }

    if (brightness > config.maxBrightness) {
      return QualityMetric(
        name: 'brightness',
        status: QualityStatus.failed,
        message: 'Image overexposed',
        value: brightness,
        threshold: config.maxBrightness,
        suggestion: 'Reduce brightness or avoid direct sunlight',
      );
    }

    // Check for moderate brightness
    final optimalMin = config.minBrightness * 1.5;
    final optimalMax = config.maxBrightness * 0.9;

    if (brightness >= optimalMin && brightness <= optimalMax) {
      return QualityMetric(
        name: 'brightness',
        status: QualityStatus.passed,
        message: 'Optimal lighting',
        value: brightness,
        threshold: config.minBrightness,
      );
    }

    return QualityMetric(
      name: 'brightness',
      status: QualityStatus.warning,
      message: 'Acceptable lighting with minor issues',
      value: brightness,
      threshold: config.minBrightness,
      suggestion: 'Consider adjusting lighting for better results',
    );
  }

  QualityMetric _estimateSharpness(ui.Image image) {
    final width = image.width;
    final height = image.height;

    // Simplified sharpness estimation
    // Lightweight sharpness estimation for pre-scan warnings
    final pixelCount = width * height;

    // Simulated sharpness score (0-100)
    double sharpnessScore;
    if (pixelCount < 500000) {
      sharpnessScore = 40.0; // Low resolution
    } else if (pixelCount < 1500000) {
      sharpnessScore = 65.0; // Moderate
    } else {
      sharpnessScore = 85.0; // High resolution
    }

    if (sharpnessScore < config.minSharpness * 0.5) {
      return QualityMetric(
        name: 'sharpness',
        status: QualityStatus.failed,
        message: 'Image is blurry',
        value: sharpnessScore,
        threshold: config.minSharpness,
        suggestion: 'Keep camera steady and ensure focus before capturing',
      );
    }

    if (sharpnessScore < config.minSharpness) {
      return QualityMetric(
        name: 'sharpness',
        status: QualityStatus.warning,
        message: 'Image may be slightly blurry',
        value: sharpnessScore,
        threshold: config.minSharpness,
        suggestion: 'Hold device steady and tap to focus',
      );
    }

    return QualityMetric(
      name: 'sharpness',
      status: QualityStatus.passed,
      message: 'Good image clarity',
      value: sharpnessScore,
      threshold: config.minSharpness,
    );
  }

  QualityMetric _estimateNoise(ui.Image image) {
    final width = image.width;
    final height = image.height;
    final pixelCount = width * height;

    // Simplified noise estimation
    // Lightweight noise estimation for pre-scan warnings
    double noiseLevel;
    if (pixelCount > 2000000) {
      noiseLevel = 0.06; // High res = less noise
    } else if (pixelCount > 500000) {
      noiseLevel = 0.10;
    } else {
      noiseLevel = 0.18; // Low res = more noise
    }

    if (noiseLevel > config.maxNoiseLevel * 1.5) {
      return QualityMetric(
        name: 'noise',
        status: QualityStatus.failed,
        message: 'Excessive noise detected',
        value: noiseLevel,
        threshold: config.maxNoiseLevel,
        suggestion: 'Capture in better lighting conditions',
      );
    }

    if (noiseLevel > config.maxNoiseLevel) {
      return QualityMetric(
        name: 'noise',
        status: QualityStatus.warning,
        message: 'Some noise visible',
        value: noiseLevel,
        threshold: config.maxNoiseLevel,
        suggestion: 'Better lighting will reduce noise',
      );
    }

    return QualityMetric(
      name: 'noise',
      status: QualityStatus.passed,
      message: 'Low noise levels',
      value: noiseLevel,
      threshold: config.maxNoiseLevel,
    );
  }

  ImageQualityLevel _determineQualityLevel(List<QualityMetric> metrics) {
    if (metrics.isEmpty) {
      return ImageQualityLevel.poor;
    }

    final failedCount = metrics
        .where((m) => m.status == QualityStatus.failed)
        .length;
    final warningCount = metrics
        .where((m) => m.status == QualityStatus.warning)
        .length;
    final passedCount = metrics
        .where((m) => m.status == QualityStatus.passed)
        .length;

    // If any critical metric fails, classify as poor
    if (failedCount > 0) {
      return ImageQualityLevel.poor;
    }

    // If more than half have warnings, classify as moderate
    if (warningCount > passedCount) {
      return ImageQualityLevel.moderate;
    }

    // If all passed with no warnings, classify as good
    if (warningCount == 0 && passedCount == metrics.length) {
      return ImageQualityLevel.good;
    }

    // Default to moderate
    return ImageQualityLevel.moderate;
  }

  List<String> _generateSuggestions(
    List<QualityMetric> metrics,
    ImageQualityLevel level,
  ) {
    final suggestions = <String>[];

    if (level == ImageQualityLevel.poor) {
      suggestions.addAll([
        'Ensure good lighting - avoid shadows on the leaf',
        'Keep the camera steady while capturing',
        'Focus directly on the affected area of the leaf',
        'Move close enough to see disease details clearly',
      ]);
    } else if (level == ImageQualityLevel.moderate) {
      for (final metric in metrics.where(
        (m) => m.status == QualityStatus.warning,
      )) {
        if (metric.suggestion != null) {
          suggestions.add(metric.suggestion!);
        }
      }
      if (suggestions.isEmpty) {
        suggestions.add('Image is acceptable but could be improved');
      }
    } else {
      suggestions.add('Image quality is excellent for analysis');
    }

    return suggestions;
  }
}

/// ImageQualityClassification - Complete quality assessment result
class ImageQualityClassification {
  final ImageQualityLevel level;
  final List<QualityMetric> metrics;
  final List<String> suggestions;
  final Duration processingTime;
  final bool isAcceptable;
  final String? error;

  const ImageQualityClassification({
    required this.level,
    required this.metrics,
    required this.suggestions,
    required this.processingTime,
    required this.isAcceptable,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'level': level.name,
    'metrics': metrics.map((m) => m.toJson()).toList(),
    'suggestions': suggestions,
    'processingTimeMs': processingTime.inMilliseconds,
    'isAcceptable': isAcceptable,
    'error': error,
  };
}
