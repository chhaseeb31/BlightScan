import 'package:flutter_test/flutter_test.dart';
import 'package:blightscan/core/services/safe_executor.dart';

void main() {
  group('SafeExecutor Tests', () {
    test('execute returns result on success', () async {
      final executor = SafeExecutor();
      final result = await executor.execute(() async => 42);
      expect(result, equals(42));
    });

    test('execute returns fallbackValue on error', () async {
      final executor = SafeExecutor();
      final result = await executor.execute<int>(
        () async => throw Exception('Test error'),
        fallbackValue: -1,
      );
      expect(result, equals(-1));
    });

    test('executeWithRetry retries on failure', () async {
      final executor = SafeExecutor();
      int attempts = 0;
      final result = await executor.executeWithRetry<int>(
        () async {
          attempts++;
          if (attempts < 3) throw Exception('Fail');
          return 42;
        },
        maxRetries: 3,
      );
      expect(result, equals(42));
      expect(attempts, equals(3));
    });

    test('executeWithRetry returns fallback after max retries', () async {
      final executor = SafeExecutor();
      final result = await executor.executeWithRetry<int>(
        () async => throw Exception('Always fails'),
        maxRetries: 2,
        fallbackValue: -1,
      );
      expect(result, equals(-1));
    });
  });

  group('SafeDebouncer Tests', () {
    test('debouncer runs action after delay', () async {
      final debouncer = SafeDebouncer(delay: const Duration(milliseconds: 100));
      bool ran = false;
      debouncer.run(() => ran = true);
      expect(ran, isFalse);
      await Future.delayed(const Duration(milliseconds: 150));
      expect(ran, isTrue);
      debouncer.dispose();
    });

    test('debouncer cancels previous action', () async {
      final debouncer = SafeDebouncer(delay: const Duration(milliseconds: 100));
      int count = 0;
      debouncer.run(() => count++);
      debouncer.run(() => count++);
      await Future.delayed(const Duration(milliseconds: 150));
      expect(count, equals(1));
      debouncer.dispose();
    });
  });

  group('SafeThrottler Tests', () {
    test('throttler allows first run', () {
      final throttler = SafeThrottler(interval: const Duration(seconds: 1));
      expect(throttler.shouldRun(), isTrue);
    });

    test('throttler blocks rapid calls', () {
      final throttler = SafeThrottler(interval: const Duration(seconds: 1));
      expect(throttler.shouldRun(), isTrue);
      expect(throttler.shouldRun(), isFalse);
      expect(throttler.shouldRun(), isFalse);
    });
  });
}
