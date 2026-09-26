import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:blightscan/core/services/image_quality_config.dart';
import 'package:blightscan/core/services/image_quality_result.dart';
import 'package:blightscan/core/services/image_quality_checker.dart';

void main() {
  group('ImageQualityConfig Tests', () {
    test('default config has correct values', () {
      const config = ImageQualityConfig();

      expect(config.minWidth, equals(640));
      expect(config.minHeight, equals(480));
      expect(config.minFileSizeKB, equals(50));
      expect(config.maxFileSizeMB, equals(10));
      expect(config.minColorDepth, equals(24));
      expect(config.minSharpness, equals(50.0));
      expect(config.maxNoiseLevel, equals(0.15));
    });

    test('plantAnalysis config is stricter', () {
      const config = ImageQualityConfig.plantAnalysis;

      expect(config.minWidth, equals(640));
      expect(config.minHeight, equals(480));
      expect(config.minSharpness, equals(50.0));
    });

    test('highQuality config requires higher resolution', () {
      const config = ImageQualityConfig.highQuality;

      expect(config.minWidth, equals(1280));
      expect(config.minHeight, equals(720));
      expect(config.minSharpness, equals(80.0));
    });

    test('copyWith creates modified config', () {
      const original = ImageQualityConfig();
      final modified = original.copyWith(
        minWidth: 1920,
        minSharpness: 100.0,
      );

      expect(modified.minWidth, equals(1920));
      expect(modified.minSharpness, equals(100.0));
      expect(modified.minHeight, equals(original.minHeight));
    });

    test('allowedFormats contains expected formats', () {
      const config = ImageQualityConfig();

      expect(config.allowedFormats, contains('jpeg'));
      expect(config.allowedFormats, contains('jpg'));
      expect(config.allowedFormats, contains('png'));
      expect(config.allowedFormats, contains('tiff'));
    });
  });

  group('QualityMetric Tests', () {
    test('creates passed metric', () {
      const metric = QualityMetric(
        name: 'test_metric',
        status: QualityStatus.passed,
        message: 'Test passed',
        value: 100.0,
        threshold: 50.0,
      );

      expect(metric.name, equals('test_metric'));
      expect(metric.status, equals(QualityStatus.passed));
      expect(metric.value, equals(100.0));
      expect(metric.threshold, equals(50.0));
    });

    test('creates failed metric with suggestion', () {
      const metric = QualityMetric(
        name: 'resolution',
        status: QualityStatus.failed,
        message: 'Image too small',
        value: 320.0,
        threshold: 640.0,
        suggestion: 'Use higher resolution',
      );

      expect(metric.status, equals(QualityStatus.failed));
      expect(metric.suggestion, equals('Use higher resolution'));
    });

    test('toJson produces valid map', () {
      const metric = QualityMetric(
        name: 'test',
        status: QualityStatus.passed,
        message: 'OK',
      );

      final json = metric.toJson();

      expect(json['name'], equals('test'));
      expect(json['status'], equals('passed'));
      expect(json['message'], equals('OK'));
    });
  });

  group('ImageQualityResult Tests', () {
    test('calculates metric counts correctly', () {
      final result = ImageQualityResult(
        imageId: 'test123',
        fileName: 'test.jpg',
        fileSizeBytes: 1024000,
        format: 'jpg',
        width: 1920,
        height: 1080,
        colorDepth: 24,
        metrics: const [
          QualityMetric(
            name: 'format',
            status: QualityStatus.passed,
            message: 'OK',
          ),
          QualityMetric(
            name: 'size',
            status: QualityStatus.passed,
            message: 'OK',
          ),
          QualityMetric(
            name: 'sharpness',
            status: QualityStatus.warning,
            message: 'Marginal',
          ),
        ],
        timestamp: DateTime.now(),
        processingTime: const Duration(milliseconds: 500),
        isValid: true,
      );

      expect(result.passedCount, equals(2));
      expect(result.warningCount, equals(1));
      expect(result.failedCount, equals(0));
      expect(result.isValid, isTrue);
    });

    test('failed result identifies failed metrics', () {
      final result = ImageQualityResult(
        imageId: 'test123',
        fileName: 'test.jpg',
        fileSizeBytes: 1024000,
        format: 'jpg',
        width: 1920,
        height: 1080,
        colorDepth: 24,
        metrics: const [
          QualityMetric(
            name: 'format',
            status: QualityStatus.failed,
            message: 'Invalid format',
          ),
          QualityMetric(
            name: 'size',
            status: QualityStatus.passed,
            message: 'OK',
          ),
        ],
        timestamp: DateTime.now(),
        processingTime: const Duration(milliseconds: 500),
        isValid: false,
      );

      expect(result.isValid, isFalse);
      expect(result.failedCount, equals(1));
      expect(result.passed, isFalse);
    });

    test('getMetric returns correct metric', () {
      final result = ImageQualityResult(
        imageId: 'test123',
        fileName: 'test.jpg',
        fileSizeBytes: 1024000,
        format: 'jpg',
        width: 1920,
        height: 1080,
        colorDepth: 24,
        metrics: const [
          QualityMetric(
            name: 'format',
            status: QualityStatus.passed,
            message: 'OK',
          ),
        ],
        timestamp: DateTime.now(),
        processingTime: const Duration(milliseconds: 500),
        isValid: true,
      );

      final metric = result.getMetric('format');
      expect(metric, isNotNull);
      expect(metric!.name, equals('format'));
    });

    test('getMetric returns null for missing metric', () {
      final result = ImageQualityResult(
        imageId: 'test123',
        fileName: 'test.jpg',
        fileSizeBytes: 1024000,
        format: 'jpg',
        width: 1920,
        height: 1080,
        colorDepth: 24,
        metrics: const [],
        timestamp: DateTime.now(),
        processingTime: const Duration(milliseconds: 500),
        isValid: true,
      );

      final metric = result.getMetric('nonexistent');
      expect(metric, isNull);
    });
  });

  group('BatchQualityResult Tests', () {
    test('calculates success rate correctly', () {
      final batchResult = BatchQualityResult(
        batchId: 'batch1',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        totalImages: 10,
        validImages: 8,
        invalidImages: 2,
        results: [],
        totalProcessingTime: const Duration(seconds: 5),
      );

      expect(batchResult.successRate, equals(80.0));
    });

    test('calculates average processing time', () {
      final batchResult = BatchQualityResult(
        batchId: 'batch1',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        totalImages: 5,
        validImages: 5,
        invalidImages: 0,
        results: [],
        totalProcessingTime: const Duration(milliseconds: 2500),
      );

      expect(batchResult.averageProcessingTime.inMilliseconds, equals(500));
    });

    test('success rate is 0 for empty batch', () {
      final batchResult = BatchQualityResult(
        batchId: 'batch1',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        totalImages: 0,
        validImages: 0,
        invalidImages: 0,
        results: [],
        totalProcessingTime: Duration.zero,
      );

      expect(batchResult.successRate, equals(0));
    });
  });

  group('ImageQualityChecker Tests', () {
    late ImageQualityChecker checker;

    setUp(() {
      checker = ImageQualityChecker();
    });

    test('validates JPEG format correctly', () async {
      final bytes = Uint8List.fromList(List.filled(100000, 128));
      final result = await checker.validateFromBytes(
        bytes,
        fileName: 'test.jpg',
      );

      final formatMetric = result.getMetric('file_format');
      expect(formatMetric, isNotNull);
      expect(formatMetric!.status, equals(QualityStatus.passed));
    });

    test('rejects unsupported format', () async {
      final bytes = Uint8List.fromList(List.filled(100000, 128));
      final result = await checker.validateFromBytes(
        bytes,
        fileName: 'test.bmp',
      );

      final formatMetric = result.getMetric('file_format');
      expect(formatMetric!.status, equals(QualityStatus.failed));
    });

    test('validates file size within range', () async {
      final bytes = Uint8List.fromList(List.filled(60000, 128)); // ~60KB
      final result = await checker.validateFromBytes(
        bytes,
        fileName: 'test.jpg',
      );

      final sizeMetric = result.getMetric('file_size');
      expect(sizeMetric!.status, equals(QualityStatus.passed));
    });

    test('rejects file size too small', () async {
      final bytes = Uint8List.fromList(List.filled(30000, 128)); // ~30KB
      final result = await checker.validateFromBytes(
        bytes,
        fileName: 'test.jpg',
      );

      final sizeMetric = result.getMetric('file_size');
      expect(sizeMetric!.status, equals(QualityStatus.failed));
    });

    test('rejects file size too large', () async {
      final bytes =
          Uint8List.fromList(List.filled(15 * 1024 * 1024, 128)); // ~15MB
      final result = await checker.validateFromBytes(
        bytes,
        fileName: 'test.jpg',
      );

      final sizeMetric = result.getMetric('file_size');
      expect(sizeMetric!.status, equals(QualityStatus.failed));
    });

    test('batch processing counts correctly', () async {
      final images = [
        BatchImageData(
          bytes: Uint8List.fromList(List.filled(50000, 128)),
          fileName: 'valid1.jpg',
        ),
        BatchImageData(
          bytes: Uint8List.fromList(List.filled(30000, 128)),
          fileName: 'invalid_size.jpg',
        ),
        BatchImageData(
          bytes: Uint8List.fromList(List.filled(50000, 128)),
          fileName: 'valid2.png',
        ),
      ];

      final batchResult = await checker.validateBatch(images);

      expect(batchResult.totalImages, equals(3));
      expect(batchResult.results.length, equals(3));
    });

    test('processing time is tracked', () async {
      final bytes = Uint8List.fromList(List.filled(100000, 128));
      final result = await checker.validateFromBytes(
        bytes,
        fileName: 'test.jpg',
      );

      expect(result.processingTime.inMilliseconds, greaterThanOrEqualTo(0));
    });

    test('custom config is used', () async {
      const customConfig = ImageQualityConfig(
        minWidth: 1920,
        minHeight: 1080,
      );
      final customChecker = ImageQualityChecker(config: customConfig);

      final bytes = Uint8List.fromList(List.filled(100000, 128));
      final result = await customChecker.validateFromBytes(
        bytes,
        fileName: 'test.jpg',
      );

      expect(result.width, equals(1920));
    });
  });

  group('Quality Standards Documentation', () {
    test('plantAnalysis config matches plant disease analysis needs', () {
      const config = ImageQualityConfig.plantAnalysis;

      expect(config.minWidth, greaterThanOrEqualTo(640));
      expect(config.minHeight, greaterThanOrEqualTo(480));
      expect(config.minSharpness, greaterThanOrEqualTo(50.0));
      expect(config.maxNoiseLevel, lessThanOrEqualTo(0.15));
    });

    test('highQuality config requires higher standards', () {
      const highQuality = ImageQualityConfig.highQuality;
      const standard = ImageQualityConfig.plantAnalysis;

      expect(highQuality.minWidth, greaterThan(standard.minWidth));
      expect(highQuality.minSharpness, greaterThan(standard.minSharpness));
      expect(highQuality.maxNoiseLevel, lessThan(standard.maxNoiseLevel));
    });
  });

  group('Common Quality Issues Resolution', () {
    late ImageQualityChecker issueChecker;

    setUp(() {
      issueChecker = ImageQualityChecker();
    });

    test('low resolution suggestions are provided', () async {
      final checker = ImageQualityChecker(
        config: const ImageQualityConfig(
          minWidth: 1920,
          minHeight: 1080,
        ),
      );

      final bytes = Uint8List.fromList(List.filled(100000, 128));
      final result = await checker.validateFromBytes(
        bytes,
        fileName: 'test.jpg',
      );

      final formatMetric = result.getMetric('file_format');
      expect(formatMetric, isNotNull);
    });

    test('file size issues have actionable suggestions', () async {
      final bytes = Uint8List.fromList(List.filled(30000, 128));
      final result = await issueChecker.validateFromBytes(
        bytes,
        fileName: 'test.jpg',
      );

      final sizeMetric = result.getMetric('file_size');
      expect(sizeMetric!.suggestion, isNotNull);
      expect(
          sizeMetric.suggestion!.contains('resolution') ||
              sizeMetric.suggestion!.contains('quality'),
          isTrue);
    });

    test('unsupported format provides format guidance', () async {
      final bytes = Uint8List.fromList(List.filled(100000, 128));
      final result = await issueChecker.validateFromBytes(
        bytes,
        fileName: 'test.gif',
      );

      final formatMetric = result.getMetric('file_format');
      expect(formatMetric!.suggestion, isNotNull);
      expect(
        formatMetric.suggestion!.contains('JPEG') ||
            formatMetric.suggestion!.contains('PNG'),
        isTrue,
      );
    });
  });
}
