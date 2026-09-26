// lib/core/services/app_state_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_routes.dart';

/// AppStateService - Handles app state persistence and restoration
/// Prevents app restart on resume, handles lifecycle properly
class AppStateService extends ChangeNotifier {
  static final AppStateService _instance = AppStateService._internal();
  static const _lastRouteKey = 'last_main_route';
  static const _restorableRoutes = {
    AppRoutes.main,
    AppRoutes.community,
    AppRoutes.history,
    AppRoutes.profile,
  };

  factory AppStateService() {
    return _instance;
  }

  AppStateService._internal();

  String? _lastRoute;
  String _initialRoute = '/';
  bool _isRestoring = false;

  String? get lastRoute => _lastRoute;
  String get initialRoute => _initialRoute;
  bool get isRestoring => _isRestoring;

  /// Called when app initializes
  void initializeApp(String initialRoute) {
    _initialRoute = initialRoute;
    _isRestoring = false;
  }

  Future<void> loadSavedState() async {
    final preferences = await SharedPreferences.getInstance();
    final savedRoute = preferences.getString(_lastRouteKey);
    if (_restorableRoutes.contains(savedRoute)) {
      _lastRoute = savedRoute;
    }
  }

  /// Save current route for state preservation
  Future<void> saveRouteState(String route) async {
    if (!_restorableRoutes.contains(route) || _lastRoute == route) return;
    _lastRoute = route;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_lastRouteKey, route);
    notifyListeners();
  }

  /// Mark app as restoring from background
  void setRestoring(bool value) {
    _isRestoring = value;
    notifyListeners();
  }

  /// Get the route to restore to (or initial route if none saved)
  String getRouteToRestore() {
    return _lastRoute ?? _initialRoute;
  }

  /// Clear saved state (e.g., on logout)
  Future<void> clearState() async {
    _lastRoute = null;
    _isRestoring = false;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_lastRouteKey);
    notifyListeners();
  }
}
