/// ImageQualityConfig - Configuration for image quality validation
/// Defines all thresholds and constraints for acceptable image quality
class ImageQualityConfig {
  final int minWidth;
  final int minHeight;
  final int maxWidth;
  final int maxHeight;
  final int minFileSizeKB;
  final int maxFileSizeMB;
  final int minColorDepth;
  final double minSharpness;
  final double maxBrightness;
  final double minBrightness;
  final double maxNoiseLevel;
  final double maxCompressionArtifactLevel;
  final Set<String> allowedFormats;
  final Duration maxProcessingTime;
  final bool enableSharpnessCheck;
  final bool enableNoiseCheck;
  final bool enableCompressionCheck;
  final bool enableBrightnessCheck;

  const ImageQualityConfig({
    this.minWidth = 640,
    this.minHeight = 480,
    this.maxWidth = 10000,
    this.maxHeight = 10000,
    this.minFileSizeKB = 50,
    this.maxFileSizeMB = 10,
    this.minColorDepth = 24,
    this.minSharpness = 50.0,
    this.maxBrightness = 240.0,
    this.minBrightness = 20.0,
    this.maxNoiseLevel = 0.15,
    this.maxCompressionArtifactLevel = 0.1,
    this.allowedFormats = const {'jpeg', 'jpg', 'png', 'tiff', 'tif'},
    this.maxProcessingTime = const Duration(seconds: 2),
    this.enableSharpnessCheck = true,
    this.enableNoiseCheck = true,
    this.enableCompressionCheck = true,
    this.enableBrightnessCheck = true,
  });

  ImageQualityConfig copyWith({
    int? minWidth,
    int? minHeight,
    int? maxWidth,
    int? maxHeight,
    int? minFileSizeKB,
    int? maxFileSizeMB,
    int? minColorDepth,
    double? minSharpness,
    double? maxBrightness,
    double? minBrightness,
    double? maxNoiseLevel,
    double? maxCompressionArtifactLevel,
    Set<String>? allowedFormats,
    Duration? maxProcessingTime,
    bool? enableSharpnessCheck,
    bool? enableNoiseCheck,
    bool? enableCompressionCheck,
    bool? enableBrightnessCheck,
  }) {
    return ImageQualityConfig(
      minWidth: minWidth ?? this.minWidth,
      minHeight: minHeight ?? this.minHeight,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
      minFileSizeKB: minFileSizeKB ?? this.minFileSizeKB,
      maxFileSizeMB: maxFileSizeMB ?? this.maxFileSizeMB,
      minColorDepth: minColorDepth ?? this.minColorDepth,
      minSharpness: minSharpness ?? this.minSharpness,
      maxBrightness: maxBrightness ?? this.maxBrightness,
      minBrightness: minBrightness ?? this.minBrightness,
      maxNoiseLevel: maxNoiseLevel ?? this.maxNoiseLevel,
      maxCompressionArtifactLevel:
          maxCompressionArtifactLevel ?? this.maxCompressionArtifactLevel,
      allowedFormats: allowedFormats ?? this.allowedFormats,
      maxProcessingTime: maxProcessingTime ?? this.maxProcessingTime,
      enableSharpnessCheck: enableSharpnessCheck ?? this.enableSharpnessCheck,
      enableNoiseCheck: enableNoiseCheck ?? this.enableNoiseCheck,
      enableCompressionCheck:
          enableCompressionCheck ?? this.enableCompressionCheck,
      enableBrightnessCheck:
          enableBrightnessCheck ?? this.enableBrightnessCheck,
    );
  }

  static const ImageQualityConfig plantAnalysis = ImageQualityConfig(
    minWidth: 640,
    minHeight: 480,
    minFileSizeKB: 50,
    maxFileSizeMB: 10,
    minColorDepth: 24,
    minSharpness: 50.0,
    maxBrightness: 240.0,
    minBrightness: 20.0,
    maxNoiseLevel: 0.15,
    maxCompressionArtifactLevel: 0.1,
  );

  static const ImageQualityConfig highQuality = ImageQualityConfig(
    minWidth: 1280,
    minHeight: 720,
    minFileSizeKB: 100,
    maxFileSizeMB: 5,
    minColorDepth: 24,
    minSharpness: 80.0,
    maxBrightness: 230.0,
    minBrightness: 30.0,
    maxNoiseLevel: 0.08,
    maxCompressionArtifactLevel: 0.05,
  );

  static const ImageQualityConfig lowBandwidth = ImageQualityConfig(
    minWidth: 320,
    minHeight: 240,
    minFileSizeKB: 20,
    maxFileSizeMB: 2,
    minColorDepth: 16,
    minSharpness: 30.0,
    maxBrightness: 250.0,
    minBrightness: 10.0,
    maxNoiseLevel: 0.25,
    maxCompressionArtifactLevel: 0.2,
  );
}
