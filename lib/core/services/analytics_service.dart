/// AnalyticsService - Structure for future analytics integration
/// Provides clean architecture for screen tracking, user actions, and errors
/// Ready for Firebase Analytics, Amplitude, Mixpanel, etc.
abstract class AnalyticsService {
  void initialize();
  void setUserId(String? userId);
  void setUserProperties(Map<String, dynamic> properties);
  void trackScreen(String screenName, {Map<String, dynamic>? params});
  void trackEvent(String eventName, {Map<String, dynamic>? params});
  void trackError(String error, {StackTrace? stackTrace, String? source});
  void setEnabled(bool enabled);
  bool get isEnabled;
}

class NoOpAnalyticsService implements AnalyticsService {
  @override
  void initialize() {}

  @override
  void setUserId(String? userId) {}

  @override
  void setUserProperties(Map<String, dynamic> properties) {}

  @override
  void trackScreen(String screenName, {Map<String, dynamic>? params}) {}

  @override
  void trackEvent(String eventName, {Map<String, dynamic>? params}) {}

  @override
  void trackError(String error, {StackTrace? stackTrace, String? source}) {}

  @override
  void setEnabled(bool enabled) {}

  @override
  bool get isEnabled => false;
}

/// AnalyticsServiceFactory - Creates analytics service based on environment
class AnalyticsServiceFactory {
  static AnalyticsService create({required bool isProduction}) {
    if (!isProduction) {
      return NoOpAnalyticsService();
    }
    return NoOpAnalyticsService();
  }
}

/// User session tracking
class UserSession {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  int screenViews = 0;
  int events = 0;

  UserSession({required this.id, required this.startTime});

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  Map<String, dynamic> toJson() => {
        'sessionId': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'durationSeconds': duration.inSeconds,
        'screenViews': screenViews,
        'events': events,
      };
}
