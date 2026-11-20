import 'package:blightscan/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blightscan/core/repositories/plant_disease_repository.dart';
import 'dart:typed_data';

void main() {
  test('missing trained model never produces a diagnosis', () async {
    final result = await PlantDiseaseRepository().analyzeImage(Uint8List(4096));
    expect(result.success, isFalse);
    expect(result.prediction, isNull);
    expect(result.errorMessage, contains('trained model'));
  });
  test('ml model contract exposes final asset locations and fallback status',
      () {
    expect(AppConfig.mlModelAssetPath, 'assets/models/blightscan_model.tflite');
    expect(AppConfig.mlLabelsAssetPath, 'assets/models/labels.txt');
    expect(AppConfig.usesFallbackModel, isTrue);
  });
}
