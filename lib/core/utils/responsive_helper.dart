/// Responsive utilities for adapting UI to different screen sizes
/// Ensures pixel-perfect responsive design across all devices
library;

import 'package:flutter/material.dart';

class ResponsiveHelper {
  static late MediaQueryData _mediaQuery;

  static void init(BuildContext context) {
    _mediaQuery = MediaQuery.of(context);
  }

  /// Screen dimensions
  static double get width => _mediaQuery.size.width;
  static double get height => _mediaQuery.size.height;
  static double get diagonal => _mediaQuery.size.longestSide;

  /// Device type detection
  static DeviceType get deviceType {
    if (width < 600) return DeviceType.phone;
    if (width < 1024) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Break points
  static bool get isPhone => width < 600;
  static bool get isTablet => width >= 600 && width < 1024;
  static bool get isDesktop => width >= 1024;

  /// Screen ratio helper
  static double widthPercent(double percent) => width * percent / 100;
  static double heightPercent(double percent) => height * percent / 100;

  /// Responsive font sizes
  static double responsiveFontSize(double baseSize) {
    final scaleFactor = width / 400; // Base reference is 400px
    return baseSize * scaleFactor;
  }

  /// Responsive padding
  static EdgeInsets responsivePadding({
    double horizontal = 16,
    double vertical = 12,
  }) {
    final hScale = isTablet
        ? 1.2
        : isDesktop
            ? 1.5
            : 1.0;
    final vScale = isTablet
        ? 1.1
        : isDesktop
            ? 1.3
            : 1.0;

    return EdgeInsets.symmetric(
      horizontal: horizontal * hScale,
      vertical: vertical * vScale,
    );
  }

  /// Responsive box constraints
  static BoxConstraints responsiveBoxConstraints({
    double minWidth = 0,
    double maxWidth = double.infinity,
    double minHeight = 0,
    double maxHeight = double.infinity,
  }) {
    final double constrainedMaxWidth = isTablet
        ? 800.0
        : isDesktop
            ? 1200.0
            : double.infinity;
    final double finalMaxWidth =
        maxWidth < constrainedMaxWidth ? maxWidth : constrainedMaxWidth;

    return BoxConstraints(
      minWidth: minWidth,
      maxWidth: finalMaxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight,
    );
  }

  /// Responsive grid configuration
  static int get gridCrossAxisCount {
    if (isDesktop) return 4;
    if (isTablet) return 3;
    return 2;
  }

  /// Safe area padding (accounts for notches, etc.)
  static EdgeInsets get safeAreaPadding => _mediaQuery.padding;

  /// View insets (keyboard height, etc.)
  static EdgeInsets get viewInsets => _mediaQuery.viewInsets;

  /// Orientation
  static Orientation get orientation => _mediaQuery.orientation;
  static bool get isPortrait => orientation == Orientation.portrait;
  static bool get isLandscape => orientation == Orientation.landscape;

  /// Safe view padding
  static double get topSafeArea => safeAreaPadding.top;
  static double get bottomSafeArea => safeAreaPadding.bottom;
  static double get leftSafeArea => safeAreaPadding.left;
  static double get rightSafeArea => safeAreaPadding.right;

  /// Device pixel ratio (for handling different pixel densities)
  static double get devicePixelRatio => _mediaQuery.devicePixelRatio;

  /// Text scale factor
  static TextScaler get textScaler => _mediaQuery.textScaler;
}

enum DeviceType { phone, tablet, desktop }

/// Widget builder for responsive layouts
class ResponsiveBuilder extends StatelessWidget {
  final WidgetBuilder phoneBuilder;
  final WidgetBuilder? tabletBuilder;
  final WidgetBuilder? desktopBuilder;

  const ResponsiveBuilder({super.key, 
    required this.phoneBuilder,
    this.tabletBuilder,
    this.desktopBuilder,
  });

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);

    if (ResponsiveHelper.isDesktop && desktopBuilder != null) {
      return desktopBuilder!(context);
    }
    if (ResponsiveHelper.isTablet && tabletBuilder != null) {
      return tabletBuilder!(context);
    }
    return phoneBuilder(context);
  }
}

/// Responsive container with max width constraint
class ResponsiveConstrainedBox extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveConstrainedBox({super.key, 
    required this.child,
    this.maxWidth = 800,
  });

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);

    return Center(
      child: ConstrainedBox(
        constraints: ResponsiveHelper.responsiveBoxConstraints(
          maxWidth: maxWidth,
        ),
        child: child,
      ),
    );
  }
}

/// Responsive grid with responsive column count
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final EdgeInsets padding;

  const ResponsiveGridView({super.key, 
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);

    return Padding(
      padding: padding,
      child: GridView.count(
        crossAxisCount: ResponsiveHelper.gridCrossAxisCount,
        mainAxisSpacing: runSpacing,
        crossAxisSpacing: spacing,
        children: children,
      ),
    );
  }
}
