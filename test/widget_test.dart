import 'package:flutter_test/flutter_test.dart';
import 'package:blightscan/core/config/app_config.dart';

void main() {
  test('app configuration uses BlightScan branding', () {
    expect(AppConfig.appName, 'BlightScan');
    expect(AppConfig.firebaseProjectId, 'blightscan-2026');
    expect(AppConfig.mlModelName, 'blightscan_tomato_late_blight_v1.0');
  });
}
