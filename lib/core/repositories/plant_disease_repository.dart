/// BlightScan Tomato Late Blight detection repository/service
/// Handles business logic and data flow for disease detection
library;

import 'package:flutter/foundation.dart';
import '../services/ml_disease_detection_service.dart';

class PlantDiseaseRepository {
  static PlantDiseaseRepository? _instance;
  final MLDiseaseDectionService _mlService = MLDiseaseDectionService();

  PlantDiseaseRepository._();

  factory PlantDiseaseRepository() {
    _instance ??= PlantDiseaseRepository._();
    return _instance!;
  }

  bool _initialized = false;

  /// Initialize disease detection
  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _mlService.initialize();
    return _initialized;
  }

  /// Analyze a tomato leaf image for Late Blight
  Future<DiseaseAnalysisResult> analyzeImage(Uint8List imageBytes) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      // Validate image
      if (!ImagePreprocessor.isValidImage(imageBytes)) {
        return DiseaseAnalysisResult.failure(
            'Invalid image. Please try another.');
      }

      // Get prediction
      final prediction = await _mlService.predictFromImage(imageBytes);

      // Get disease details
      final details = _mlService.getDiseaseDetails(prediction.diseaseType);

      return DiseaseAnalysisResult.success(
        prediction: prediction,
        details: details,
      );
    } catch (e) {
      debugPrint('[Repository] Analysis error: $e');
      return DiseaseAnalysisResult.failure(
          'Analysis failed. Please try again.');
    }
  }

  /// Get expert recommendations for a disease
  List<String> getRecommendations(String diseaseType) {
    final details = _mlService.getDiseaseDetails(diseaseType);
    return details.treatment;
  }

  Future<void> dispose() async {
    await _mlService.dispose();
  }
}

/// Analysis result wrapper
class DiseaseAnalysisResult {
  final bool success;
  final DiseasePrediction? prediction;
  final DiseaseDetails? details;
  final String? errorMessage;

  const DiseaseAnalysisResult({
    required this.success,
    this.prediction,
    this.details,
    this.errorMessage,
  });

  factory DiseaseAnalysisResult.success({
    required DiseasePrediction prediction,
    required DiseaseDetails details,
  }) {
    return DiseaseAnalysisResult(
      success: true,
      prediction: prediction,
      details: details,
    );
  }

  factory DiseaseAnalysisResult.failure(String message) {
    return DiseaseAnalysisResult(
      success: false,
      errorMessage: message,
    );
  }
}
