import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_routes.dart';
import 'core/services/app_state_service.dart';
import 'core/services/auth_session_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/scan_history_service.dart';
import 'features/community/data/services/community_service.dart';
import 'core/repositories/scan_history_repository.dart';
import 'core/data_sources/scan_history_local_data_source.dart';
import 'core/data_sources/scan_history_remote_data_source.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    final scanHistoryRepository = ScanHistoryRepository(
      localDataSource: ScanHistoryLocalDataSource(),
      remoteDataSource: ScanHistoryRemoteDataSource(),
    );

    final scanHistoryService = ScanHistoryService(
      authSession: authSession,
      repository: scanHistoryRepository,
    );

    final communityService = CommunityService(
      authSession: authSession,
    );

    await Future.wait([
      _initializeSystemSettings(),
      _initializeFirebase(),
      AppConfig.initialize(),
      authSession.initialize(),
    ]).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        if (kDebugMode) {
          debugPrint('Initialization timed out, continuing...');
        }
        return [];
      },
    );
    await appNotifications.initialize();

    ErrorWidget.builder = (FlutterErrorDetails details) {
      return _GlobalErrorScreen(details: details);
    };

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthSessionService>.value(
            value: authSession,
          ),
          ChangeNotifierProvider<NotificationService>.value(
            value: appNotifications,
          ),
          ChangeNotifierProvider<ScanHistoryService>.value(
            value: scanHistoryService,
          ),
          ChangeNotifierProvider<CommunityService>.value(
            value: communityService,
          ),
        ],
        child: const BlightScanApp(),
      ),
    );
  }, (error, stack) {
    if (kDebugMode) {
      debugPrint('Critical root error: $error\n$stack');
    }
  });
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Firebase initialization failed: $e');
    }
  }
}

Future<void> _initializeSystemSettings() async {
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('System settings initialization failed: $e');
    }
  }
}

class BlightScanApp extends StatefulWidget {
  const BlightScanApp({super.key});

  @override
  State<BlightScanApp> createState() => _BlightScanAppState();
}

class _BlightScanAppState extends State<BlightScanApp>
    with WidgetsBindingObserver {
  late final AppStateService _appStateService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _appStateService = AppStateService();
    _appStateService.initializeApp(AppRoutes.splash);
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _appStateService.setRestoring(false);
        if (kDebugMode) {
          debugPrint('App resumed - preserving state');
        }
        break;
      case AppLifecycleState.paused:
        if (kDebugMode) {
          debugPrint('App paused - state persisted');
        }
        break;
      case AppLifecycleState.detached:
        if (kDebugMode) {
          debugPrint('App detached');
        }
        break;
      case AppLifecycleState.hidden:
        if (kDebugMode) {
          debugPrint('App hidden');
        }
        break;
      case AppLifecycleState.inactive:
        if (kDebugMode) {
          debugPrint('App inactive');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRoutes.router,
      builder: (context, child) {
        if (!_isInitialized) {
          return const SizedBox.shrink();
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

/// Fallback error screen for rendering failures
class _GlobalErrorScreen extends StatelessWidget {
  final FlutterErrorDetails details;
  const _GlobalErrorScreen({required this.details});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 60, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Application Error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Restart App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
