/// Tomato Late Blight detection service.
///
/// This file is intentionally isolated so the demo fallback can be replaced by
/// a real TensorFlow Lite interpreter later without changing UI screens.
library;

import 'package:flutter/foundation.dart';

class MLDiseaseDetectionService {
  static MLDiseaseDetectionService? _instance;

  MLDiseaseDetectionService._();

  factory MLDiseaseDetectionService() {
    _instance ??= MLDiseaseDetectionService._();
    return _instance!;
  }

  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Real integration point:
    // 1. Add the trained model at AppConfig.mlModelAssetPath.
    // 2. Add labels at AppConfig.mlLabelsAssetPath.
    // 3. Replace the fallback heuristic with a TFLite interpreter for model input/output matching.
    _isInitialized = true;
    if (kDebugMode) {
      debugPrint('[ML Service] BlightScan detector initialized.');
    }
    return true;
  }

  Future<DiseasePrediction> predictFromImage(
    Uint8List imageBytes, {
    double confidenceThreshold = 0.60,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (imageBytes.length < 2048) {
      return const DiseasePrediction(
        diseaseType: 'Unknown',
        confidence: 0.0,
        recommendation: 'Please upload a clear tomato leaf image.',
        allPredictions: [],
        isHealthy: false,
      );
    }

    final prediction = _predictWithFallbackClassifier(imageBytes);
    if (prediction.confidence < confidenceThreshold) {
      return DiseasePrediction(
        diseaseType: prediction.label,
        confidence: prediction.confidence,
        recommendation:
            'Prediction confidence is low. Retake the image in natural light and keep only the tomato leaf in frame.',
        allPredictions: [prediction],
        isHealthy: prediction.label == 'Healthy',
      );
    }

    return DiseasePrediction(
      diseaseType: prediction.label,
      confidence: prediction.confidence,
      recommendation: _getRecommendation(prediction.label),
      allPredictions: [prediction],
      isHealthy: prediction.label == 'Healthy',
    );
  }

  /// Deterministic fallback until the trained .tflite model is added.
  /// It keeps the app functional for UI/Firebase testing but should not be
  /// presented as a final trained AI result in the FYP defense.
  Prediction _predictWithFallbackClassifier(Uint8List bytes) {
    int red = 0;
    int green = 0;
    int dark = 0;
    int sampled = 0;

    // JPEG/PNG bytes are not decoded pixels; this lightweight heuristic is only
    // a safe deterministic fallback. Real inference must use decoded pixels.
    for (var i = 0; i + 2 < bytes.length; i += 37) {
      final r = bytes[i];
      final g = bytes[i + 1];
      final b = bytes[i + 2];
      red += r;
      green += g;
      if ((r + g + b) < 210) dark++;
      sampled++;
    }

    final avgRed = red / sampled;
    final avgGreen = green / sampled;
    final darkRatio = dark / sampled;
    final diseaseSignal = ((avgRed - avgGreen) / 255.0) + darkRatio;

    if (diseaseSignal > 0.37) {
      final confidence =
          (0.72 + diseaseSignal.clamp(0.0, 0.22)).clamp(0.60, 0.94).toDouble();
      return Prediction(label: 'Tomato Late Blight', confidence: confidence);
    }

    final confidence = (0.70 + (0.37 - diseaseSignal).clamp(0.0, 0.20))
        .clamp(0.60, 0.90)
        .toDouble();
    return Prediction(label: 'Healthy', confidence: confidence);
  }

  DiseaseDetails getDiseaseDetails(String diseaseName) {
    final normalized = diseaseName.toLowerCase();
    if (normalized.contains('healthy')) {
      return const DiseaseDetails(
        name: 'Healthy Tomato Leaf',
        description:
            'The tomato leaf appears healthy. No clear Late Blight symptoms were detected in this scan.',
        causes: [],
        symptoms: [
          'Leaf surface looks normal',
          'No major water-soaked patches detected',
          'No strong dark blight pattern visible',
        ],
        treatment: [
          'Continue regular crop monitoring',
          'Avoid overhead watering where possible',
          'Keep leaves dry and maintain airflow',
          'Re-scan if new brown or water-soaked spots appear',
        ],
        severity: 'None',
      );
    }

    if (normalized.contains('late blight')) {
      return const DiseaseDetails(
        name: 'Tomato Late Blight',
        description:
            'Tomato Late Blight is a serious disease that can damage leaves, stems, and fruits quickly under cool and humid conditions.',
        causes: [
          'Pathogen: Phytophthora infestans',
          'Cool, wet, and humid weather',
          'Poor airflow around plants',
          'Infected plant debris or nearby diseased plants',
        ],
        symptoms: [
          'Water-soaked irregular patches on leaves',
          'Brown to dark lesions that expand quickly',
          'White mold-like growth on leaf underside in humid weather',
          'Dark lesions on stems or fruit in severe cases',
        ],
        treatment: [
          'Remove and safely dispose of infected leaves',
          'Avoid overhead watering and keep foliage dry',
          'Improve spacing and airflow around tomato plants',
          'Use a recommended fungicide after consulting a local agriculture expert',
          'Disinfect tools after pruning infected parts',
        ],
        severity: 'High',
      );
    }

    return const DiseaseDetails(
      name: 'Unknown',
      description:
          'The scan could not produce a reliable Tomato/Late Blight result. Please upload a clear tomato leaf image.',
      causes: [],
      symptoms: [],
      treatment: [
        'Retake the image in good lighting with the leaf fully visible.',
      ],
      severity: 'Unknown',
    );
  }

  String _getRecommendation(String label) {
    if (label == 'Healthy') {
      return 'No Late Blight signs detected. Continue monitoring and prevention.';
    }
    if (label == 'Tomato Late Blight') {
      return 'Late Blight signs detected. Isolate affected leaves, improve airflow, and follow treatment guidance.';
    }
    return 'Please scan a clear tomato leaf image.';
  }

  Future<void> dispose() async {
    _isInitialized = false;
  }
}

// Backward-compatible alias for the earlier misspelled class name.
typedef MLDiseaseDectionService = MLDiseaseDetectionService;

class DiseasePrediction {
  final String diseaseType;
  final double confidence;
  final String recommendation;
  final List<Prediction> allPredictions;
  final bool isHealthy;

  const DiseasePrediction({
    required this.diseaseType,
    required this.confidence,
    required this.recommendation,
    required this.allPredictions,
    required this.isHealthy,
  });
}

class Prediction {
  final String label;
  final double confidence;

  const Prediction({required this.label, required this.confidence});
}

class DiseaseDetails {
  final String name;
  final String description;
  final List<String> causes;
  final List<String> symptoms;
  final List<String> treatment;
  final String severity;

  const DiseaseDetails({
    required this.name,
    required this.description,
    required this.causes,
    required this.symptoms,
    required this.treatment,
    required this.severity,
  });
}

class ImagePreprocessor {
  ImagePreprocessor._();

  static bool isValidImage(Uint8List imageBytes) {
    if (imageBytes.length < 2048) return false;

    final isJpeg = imageBytes.length > 3 &&
        imageBytes[0] == 0xFF &&
        imageBytes[1] == 0xD8 &&
        imageBytes[2] == 0xFF;
    final isPng = imageBytes.length > 8 &&
        imageBytes[0] == 0x89 &&
        imageBytes[1] == 0x50 &&
        imageBytes[2] == 0x4E &&
        imageBytes[3] == 0x47;

    return isJpeg || isPng;
  }
}
