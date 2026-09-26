/// QualityMetric - Individual quality check result
class QualityMetric {
  final String name;
  final QualityStatus status;
  final String message;
  final double? value;
  final double? threshold;
  final String? suggestion;

  const QualityMetric({
    required this.name,
    required this.status,
    required this.message,
    this.value,
    this.threshold,
    this.suggestion,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'status': status.name,
    'message': message,
    'value': value,
    'threshold': threshold,
    'suggestion': suggestion,
  };
}

enum QualityStatus { passed, warning, failed }

/// ImageQualityResult - Complete quality validation result
class ImageQualityResult {
  final String imageId;
  final String fileName;
  final int fileSizeBytes;
  final String format;
  final int width;
  final int height;
  final int colorDepth;
  final List<QualityMetric> metrics;
  final DateTime timestamp;
  final Duration processingTime;
  final bool isValid;
  final String? overallMessage;

  const ImageQualityResult({
    required this.imageId,
    required this.fileName,
    required this.fileSizeBytes,
    required this.format,
    required this.width,
    required this.height,
    required this.colorDepth,
    required this.metrics,
    required this.timestamp,
    required this.processingTime,
    required this.isValid,
    this.overallMessage,
  });

  bool get passed =>
      isValid && metrics.every((m) => m.status != QualityStatus.failed);

  int get passedCount =>
      metrics.where((m) => m.status == QualityStatus.passed).length;
  int get warningCount =>
      metrics.where((m) => m.status == QualityStatus.warning).length;
  int get failedCount =>
      metrics.where((m) => m.status == QualityStatus.failed).length;

  List<QualityMetric> get failedMetrics =>
      metrics.where((m) => m.status == QualityStatus.failed).toList();

  List<QualityMetric> get warningMetrics =>
      metrics.where((m) => m.status == QualityStatus.warning).toList();

  QualityMetric? getMetric(String name) {
    try {
      return metrics.firstWhere((m) => m.name == name);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
    'imageId': imageId,
    'fileName': fileName,
    'fileSizeBytes': fileSizeBytes,
    'format': format,
    'width': width,
    'height': height,
    'colorDepth': colorDepth,
    'metrics': metrics.map((m) => m.toJson()).toList(),
    'timestamp': timestamp.toIso8601String(),
    'processingTimeMs': processingTime.inMilliseconds,
    'isValid': isValid,
    'overallMessage': overallMessage,
    'summary': {
      'passed': passedCount,
      'warnings': warningCount,
      'failed': failedCount,
    },
  };
}

/// BatchQualityResult - Results for batch processing
class BatchQualityResult {
  final String batchId;
  final DateTime startTime;
  final DateTime endTime;
  final int totalImages;
  final int validImages;
  final int invalidImages;
  final List<ImageQualityResult> results;
  final Duration totalProcessingTime;

  const BatchQualityResult({
    required this.batchId,
    required this.startTime,
    required this.endTime,
    required this.totalImages,
    required this.validImages,
    required this.invalidImages,
    required this.results,
    required this.totalProcessingTime,
  });

  double get successRate =>
      totalImages > 0 ? (validImages / totalImages) * 100 : 0;

  Duration get averageProcessingTime => totalImages > 0
      ? Duration(
          milliseconds: totalProcessingTime.inMilliseconds ~/ totalImages,
        )
      : Duration.zero;

  Map<String, dynamic> toJson() => {
    'batchId': batchId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'totalImages': totalImages,
    'validImages': validImages,
    'invalidImages': invalidImages,
    'successRate': successRate,
    'averageProcessingTimeMs': averageProcessingTime.inMilliseconds,
    'totalProcessingTimeMs': totalProcessingTime.inMilliseconds,
    'results': results.map((r) => r.toJson()).toList(),
  };
}
