import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';

/// NavigationService - Centralized navigation handling for safe and reliable routing
/// Implements debounce protection and prevents multiple tap crashes
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  bool _isNavigating = false;
  DateTime? _lastNavigationTime;
  static const _debounceMs = 500;

  bool get isNavigating => _isNavigating;

  bool _shouldDebounce() {
    if (_isNavigating) return true;
    if (_lastNavigationTime != null) {
      final elapsed =
          DateTime.now().difference(_lastNavigationTime!).inMilliseconds;
      if (elapsed < _debounceMs) return true;
    }
    return false;
  }

  void _startNavigation() {
    _isNavigating = true;
    _lastNavigationTime = DateTime.now();
  }

  void _endNavigation() {
    Future.delayed(const Duration(milliseconds: _debounceMs), () {
      _isNavigating = false;
    });
  }

  /// Safe pop with debounce and validation
  Future<bool> pop<T extends Object?>(BuildContext context, [T? result]) async {
    if (_shouldDebounce() || !context.mounted) return false;

    _startNavigation();
    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(result);
        return true;
      }
      return false;
    } finally {
      _endNavigation();
    }
  }

  /// Safe push with debounce
  Future<void> push(BuildContext context, String route, {Object? extra}) async {
    if (_shouldDebounce() || !context.mounted) return;

    _startNavigation();
    try {
      context.push(route, extra: extra);
    } finally {
      _endNavigation();
    }
  }

  /// Safe push replacement with debounce
  Future<void> pushReplacement(BuildContext context, String route,
      {Object? extra}) async {
    if (_shouldDebounce() || !context.mounted) return;

    _startNavigation();
    try {
      context.pushReplacement(route, extra: extra);
    } finally {
      _endNavigation();
    }
  }

  /// Safe go with debounce - ONLY for root navigation
  Future<void> go(BuildContext context, String route, {Object? extra}) async {
    if (_shouldDebounce() || !context.mounted) return;

    _startNavigation();
    try {
      context.go(route, extra: extra);
    } finally {
      _endNavigation();
    }
  }

  /// Pop to first route (clear stack to root)
  Future<void> popToFirst(BuildContext context) async {
    if (_shouldDebounce() || !context.mounted) return;

    _startNavigation();
    try {
      context.go(AppRoutes.main);
    } finally {
      _endNavigation();
    }
  }
}

/// Global navigation service instance
final navigationService = NavigationService();

/// Debouncer mixin for widgets
mixin DebounceMixin<T extends StatefulWidget> on State<T> {
  bool _isDebouncing = false;

  bool get isDebouncing => _isDebouncing;

  void debounce(VoidCallback action, {int milliseconds = 500}) {
    if (_isDebouncing || !mounted) return;

    _isDebouncing = true;
    action();

    Future.delayed(Duration(milliseconds: milliseconds), () {
      if (mounted) {
        _isDebouncing = false;
      }
    });
  }
}

/// Global navigation utilities for safe and reliable navigation
class NavigationUtils {
  static bool _isNavigating = false;

  /// Safely navigate back with debounce protection
  static Future<void> safePop(BuildContext context,
      {String? fallbackRoute}) async {
    if (_isNavigating || !context.mounted) return;

    _isNavigating = true;

    try {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      } else if (fallbackRoute != null) {
        context.go(fallbackRoute);
      } else {
        context.go(AppRoutes.main);
      }
    } catch (e) {
      if (context.mounted) {
        context.go(AppRoutes.main);
      }
    } finally {
      Future.delayed(const Duration(milliseconds: 500), () {
        _isNavigating = false;
      });
    }
  }

  /// Check if navigation is currently in progress
  static bool get isNavigating => _isNavigating;

  /// Safe push navigation with debounce
  static Future<void> safePush(BuildContext context, String route) async {
    if (_isNavigating || !context.mounted) return;

    _isNavigating = true;

    try {
      context.push(route);
    } catch (e) {
      // Handle navigation errors
    } finally {
      Future.delayed(const Duration(milliseconds: 500), () {
        _isNavigating = false;
      });
    }
  }

  /// Safe go navigation with debounce
  static Future<void> safeGo(BuildContext context, String route) async {
    if (_isNavigating || !context.mounted) return;

    _isNavigating = true;

    try {
      context.go(route);
    } catch (e) {
      // Handle navigation errors
    } finally {
      Future.delayed(const Duration(milliseconds: 500), () {
        _isNavigating = false;
      });
    }
  }
}

/// Safe Back Button widget with built-in debounce and safety checks
class SafeBackButton extends StatefulWidget {
  final String? fallbackRoute;
  final Widget? child;
  final Color? color;
  final VoidCallback? onPressed;

  const SafeBackButton({
    super.key,
    this.fallbackRoute,
    this.child,
    this.color,
    this.onPressed,
  });

  @override
  State<SafeBackButton> createState() => _SafeBackButtonState();
}

class _SafeBackButtonState extends State<SafeBackButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: widget.child ?? const Icon(Icons.arrow_back_ios_rounded, size: 20),
      color: widget.color,
      onPressed: _isPressed ? null : _handleBack,
    );
  }

  Future<void> _handleBack() async {
    if (_isPressed) return;

    setState(() => _isPressed = true);

    if (widget.onPressed != null) {
      widget.onPressed!();
    } else {
      await NavigationUtils.safePop(
        context,
        fallbackRoute: widget.fallbackRoute,
      );
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isPressed = false);
      }
    });
  }
}

/// Safe PopScope wrapper for handling system back button
/// Uses Flutter 2026 standard PopScope (NOT deprecated WillPopScope)
class SafePopScope extends StatelessWidget {
  final Widget child;
  final Future<bool> Function()? onWillPop;
  final String? fallbackRoute;
  final bool canPop;

  const SafePopScope({
    super.key,
    required this.child,
    this.onWillPop,
    this.fallbackRoute,
    this.canPop = true,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop && _canNavigateBack(context),
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        if (onWillPop != null) {
          final shouldPop = await onWillPop!();
          if (!shouldPop || !context.mounted) return;
        }

        if (!context.mounted) return;

        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else if (fallbackRoute != null && context.mounted) {
          context.go(fallbackRoute!);
        }
      },
      child: child,
    );
  }

  bool _canNavigateBack(BuildContext context) {
    try {
      return Navigator.of(context).canPop();
    } catch (e) {
      return false;
    }
  }
}
