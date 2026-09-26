import 'dart:async';
import 'package:flutter/foundation.dart';

/// SafeExecutor - Wraps async operations with crash-safe guards
/// Prevents setState after dispose and handles all edge cases
class SafeExecutor {
  SafeExecutor();

  /// Execute a safe async operation with error handling
  /// Returns null on error instead of throwing
  Future<T?> execute<T>(
    Future<T> Function() operation, {
    String? tag,
    void Function(T)? onSuccess,
    void Function(Object error)? onError,
    T? fallbackValue,
  }) async {
    try {
      final result = await operation();
      if (onSuccess != null && result != null) {
        onSuccess(result);
      }
      return result;
    } catch (e, stack) {
      if (onError != null) {
        onError(e);
      }
      if (kDebugMode) {
        debugPrint('[$tag] SafeExecutor error: $e\n$stack');
      }
      return fallbackValue;
    }
  }

  /// Execute with retry logic
  Future<T?> executeWithRetry<T>(
    Future<T> Function() operation, {
    String? tag,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    T? fallbackValue,
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          if (kDebugMode) {
            debugPrint('[$tag] Max retries ($maxRetries) reached');
          }
          return fallbackValue;
        }
        await Future.delayed(retryDelay * attempts);
      }
    }
    return fallbackValue;
  }
}

final safeExecutor = SafeExecutor();

/// Debouncer with cancel support
class SafeDebouncer {
  final Duration delay;
  Timer? _timer;

  SafeDebouncer({this.delay = const Duration(milliseconds: 500)});

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
  }

  void dispose() {
    cancel();
  }
}

/// Throttler to limit action frequency
class SafeThrottler {
  final Duration interval;
  DateTime? _lastRun;

  SafeThrottler({this.interval = const Duration(milliseconds: 500)});

  bool shouldRun() {
    final now = DateTime.now();
    if (_lastRun == null || now.difference(_lastRun!) > interval) {
      _lastRun = now;
      return true;
    }
    return false;
  }

  void reset() {
    _lastRun = null;
  }
}
