/// Application configuration and settings
/// Centralized configuration for production deployment
library;

class AppConfig {
  AppConfig._();

  // App metadata
  static const String appName = 'BlightScan';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // Firebase configuration
  static const bool enableFirebase = true;
  static const String firebaseProjectId = 'blightscan-2026';

  // ML model configuration
  static const String mlModelName = 'blightscan_tomato_late_blight_v1.0';
  static const String mlModelAssetPath =
      'assets/models/blightscan_model.tflite';
  static const String mlLabelsAssetPath = 'assets/models/labels.txt';
  static const String mlModelOutputClass = 'Tomato Late Blight';
  static const double mlConfidenceThreshold = 0.60;
  static const int mlInputImageSize = 224;
  static const bool usesFallbackModel = true;

  // Feature flags
  static const bool enableOfflineMode = true;
  static const bool enableAnalytics = false;
  static const bool enableCrashReporting = false;

  // UI Configuration
  static const bool enableDarkMode = false;
  static const bool forcePortraitOnly = true;
  static const bool enableSearchFunctionality = true;

  // Performance settings
  static const int imageCacheSize = 50 * 1024 * 1024; // 50MB
  static const int maxConcurrentRequests = 5;
  static const Duration cacheDuration = Duration(days: 7);

  // Security
  static const bool enableBiometric = false;
  static const bool requireAuthentication = true;

  // Logging
  static const bool enableDebugLogging = false;
  static const bool enableAnalyticLogging = true;

  /// Environment configuration
  static String get environmentName {
    const String env =
        String.fromEnvironment('ENV', defaultValue: 'production');
    return env;
  }

  static bool get isProduction => environmentName == 'production';
  static bool get isDevelopment => environmentName == 'development';
  static bool get isStaging => environmentName == 'staging';

  /// Initialize app configuration
  static Future<void> initialize() async {
    // Initialize analytics if enabled
    if (enableAnalytics) {
      // Initialize analytics
    }

    // Initialize crash reporting if enabled
    if (enableCrashReporting) {
      // Initialize crash reporting
    }
  }

  /// Validate configuration for current environment
  static bool validateConfiguration() {
    if (isProduction) {
      // Production validations
      assert(mlConfidenceThreshold >= 0.5,
          'Low confidence threshold for production');
      assert(!enableDebugLogging,
          'Debug logging should be disabled in production');
    }
    return true;
  }
}

/// Supported languages
enum AppLanguage {
  english('en'),
  urdu('ur'),
  arabic('ar');

  final String code;
  const AppLanguage(this.code);
}

/// Supported regions
enum AppRegion {
  pakistan('PK'),
  india('IN'),
  global('Global');

  final String code;
  const AppRegion(this.code);
}

/// Device type detection
enum DeviceType { phone, tablet, desktop }

/// Connectivity status
enum ConnectivityStatus { online, offline, unknown }
