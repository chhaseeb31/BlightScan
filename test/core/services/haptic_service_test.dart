import 'package:flutter_test/flutter_test.dart';
import 'package:blightscan/core/services/haptic_service.dart';

void main() {
  group('HapticService Tests', () {
    test('HapticService singleton works', () {
      final instance1 = HapticService();
      final instance2 = HapticService();
      expect(instance1, equals(instance2));
    });

    test('isEnabled defaults to true', () {
      final service = HapticService();
      expect(service.isEnabled, isTrue);
    });

    test('setEnabled changes isEnabled', () {
      final service = HapticService();
      service.setEnabled(false);
      expect(service.isEnabled, isFalse);
      service.setEnabled(true);
      expect(service.isEnabled, isTrue);
    });
  });
}
