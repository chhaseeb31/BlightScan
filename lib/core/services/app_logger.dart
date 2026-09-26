import 'package:flutter/foundation.dart';

/// LogLevel - Enum for log severity levels
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// AppLogEntry - Model for log entries
class AppLogEntry {
  final String message;
  final LogLevel level;
  final String? tag;
  final DateTime timestamp;
  final dynamic error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? extra;

  AppLogEntry({
    required this.message,
    required this.level,
    this.tag,
    required this.timestamp,
    this.error,
    this.stackTrace,
    this.extra,
  });

  Map<String, dynamic> toJson() => {
        'message': message,
        'level': level.name,
        'tag': tag,
        'timestamp': timestamp.toIso8601String(),
        'error': error?.toString(),
        'stackTrace': stackTrace?.toString(),
        'extra': extra,
      };
}

/// AppLogger - Global error logging service
/// Provides structured logging for debugging and monitoring
/// Ready for future analytics integration
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  final List<AppLogEntry> _logs = [];
  static const int _maxLogs = 500;

  bool _isDebugMode = kDebugMode;
  final List<void Function(AppLogEntry)> _listeners = [];

  /// Enable/disable debug mode
  void setDebugMode(bool enabled) {
    _isDebugMode = enabled;
  }

  /// Add listener for log events (for analytics integration)
  void addListener(void Function(AppLogEntry) listener) {
    _listeners.add(listener);
  }

  /// Remove listener
  void removeListener(void Function(AppLogEntry) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(AppLogEntry entry) {
    for (final listener in _listeners) {
      try {
        listener(entry);
      } catch (e) {
        debugPrint('Logger listener error: $e');
      }
    }
  }

  void _log(AppLogEntry entry) {
    if (_logs.length >= _maxLogs) {
      _logs.removeAt(0);
    }
    _logs.add(entry);

    if (_isDebugMode) {
      _printLog(entry);
    }

    _notifyListeners(entry);
  }

  void _printLog(AppLogEntry entry) {
    final tag = entry.tag != null ? '[${entry.tag}] ' : '';
    final error = entry.error != null ? '\nError: ${entry.error}' : '';
    final stack =
        entry.stackTrace != null ? '\nStack: ${entry.stackTrace}' : '';

    switch (entry.level) {
      case LogLevel.debug:
        debugPrint('🔍 $tag${entry.message}$error$stack');
      case LogLevel.info:
        debugPrint('ℹ️ $tag${entry.message}');
      case LogLevel.warning:
        debugPrint('⚠️ $tag${entry.message}$error');
      case LogLevel.error:
        debugPrint('❌ $tag${entry.message}$error$stack');
      case LogLevel.critical:
        debugPrint('🚨 $tag${entry.message}$error$stack');
    }
  }

  /// Debug log
  void debug(String message, {String? tag, Map<String, dynamic>? extra}) {
    _log(AppLogEntry(
      message: message,
      level: LogLevel.debug,
      tag: tag,
      timestamp: DateTime.now(),
      extra: extra,
    ));
  }

  /// Info log
  void info(String message, {String? tag, Map<String, dynamic>? extra}) {
    _log(AppLogEntry(
      message: message,
      level: LogLevel.info,
      tag: tag,
      timestamp: DateTime.now(),
      extra: extra,
    ));
  }

  /// Warning log
  void warning(String message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(AppLogEntry(
      message: message,
      level: LogLevel.warning,
      tag: tag,
      timestamp: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    ));
  }

  /// Error log
  void error(String message,
      {String? tag,
      dynamic error,
      StackTrace? stackTrace,
      Map<String, dynamic>? extra}) {
    _log(AppLogEntry(
      message: message,
      level: LogLevel.error,
      tag: tag,
      timestamp: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
      extra: extra,
    ));
  }

  /// Critical log
  void critical(String message,
      {String? tag,
      dynamic error,
      StackTrace? stackTrace,
      Map<String, dynamic>? extra}) {
    _log(AppLogEntry(
      message: message,
      level: LogLevel.critical,
      tag: tag,
      timestamp: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
      extra: extra,
    ));
  }

  /// Log navigation events
  void logNavigation(String from, String to, {String? method}) {
    info('Navigation: $from -> $to',
        tag: 'NAV',
        extra: {'from': from, 'to': to, 'method': method});
  }

  /// Log screen view
  void logScreenView(String screenName, {Map<String, dynamic>? params}) {
    info('Screen: $screenName', tag: 'SCREEN', extra: params);
  }

  /// Log user action
  void logUserAction(String action, {String? screen, Map<String, dynamic>? params}) {
    info('Action: $action',
        tag: 'USER', extra: {'action': action, 'screen': screen, ...?params});
  }

  /// Log app lifecycle event
  void logLifecycle(String state) {
    debug('Lifecycle: $state', tag: 'LIFECYCLE');
  }

  /// Get recent logs
  List<AppLogEntry> getLogs({LogLevel? minLevel, int? limit}) {
    var logs = _logs.where((l) => l.level.index >= (minLevel?.index ?? 0));
    if (limit != null) {
      logs = logs.toList().reversed.take(limit);
    }
    return logs.toList().reversed.toList();
  }

  /// Clear logs
  void clearLogs() {
    _logs.clear();
  }
}

final appLogger = AppLogger();
