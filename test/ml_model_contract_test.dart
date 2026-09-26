import 'package:blightscan/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ml model contract exposes final asset locations and fallback status',
      () {
    expect(AppConfig.mlModelAssetPath, 'assets/models/blightscan_model.tflite');
    expect(AppConfig.mlLabelsAssetPath, 'assets/models/labels.txt');
    expect(AppConfig.usesFallbackModel, isTrue);
  });
}
