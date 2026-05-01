import 'package:flutter/material.dart';

/// Responsive design helper for adaptive layouts
class ResponsiveHelper {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return const EdgeInsets.all(12);
    } else if (width < tabletBreakpoint) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(24);
    }
  }

  /// Get responsive font size
  static double getResponsiveFontSize(BuildContext context, {
    required double mobileSize,
    double? tabletSize,
    double? desktopSize,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return mobileSize;
    } else if (width < desktopBreakpoint) {
      return tabletSize ?? mobileSize + 2;
    } else {
      return desktopSize ?? mobileSize + 4;
    }
  }

  /// Get responsive width for grid/spacing
  static double getResponsiveWidth(BuildContext context, double fraction) {
    return MediaQuery.of(context).size.width * fraction;
  }

  /// Get number of columns for grid
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return 1;
    } else if (width < tabletBreakpoint) {
      return 2;
    } else {
      return 3;
    }
  }

  /// Get responsive spacing
  static double getResponsiveSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return 8;
    } else if (width < tabletBreakpoint) {
      return 12;
    } else {
      return 16;
    }
  }

  /// Get responsive border radius
  static double getResponsiveBorderRadius(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return 8;
    } else if (width < tabletBreakpoint) {
      return 12;
    } else {
      return 16;
    }
  }

  /// Check if landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if portrait orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Get safe area constraints
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
}

// ─────────────────────────────────────────────────────────────────
//  RESPONSIVE CONTEXT HELPER (R.of pattern)
// ─────────────────────────────────────────────────────────────────

class R extends InheritedWidget {
  final double screenWidth;
  final double screenHeight;

  const R({
    Key? key,
    required this.screenWidth,
    required this.screenHeight,
    required Widget child,
  }) : super(key: key, child: child);

  static R of(BuildContext context) {
    try {
      final result = context.dependOnInheritedWidgetOfExactType<R>();
      if (result != null) return result;
    } catch (e) {
      print('⚠️  R.of() error: $e');
    }
    
    // If no R found, throw clear error
    throw FlutterError(
      'ResponsiveBuilder not found in widget tree.\n'
      'Ensure your app is wrapped with ResponsiveBuilder:\n'
      '  ResponsiveBuilder(\n'
      '    child: YourWidget(),\n'
      '  )\n'
      'This typically goes in main.dart wrapping AppEntryPoint or MaterialApp.'
    );
  }

  /// Static helper when R is not available - use MediaQuery directly
  static double fsSafe(BuildContext context, double baseSize) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < ResponsiveHelper.mobileBreakpoint) return baseSize;
    if (width < ResponsiveHelper.desktopBreakpoint) return baseSize + 2;
    return baseSize + 4;
  }

  /// Static helper for grid columns
  static int navGridColsSafe(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < ResponsiveHelper.mobileBreakpoint) return 2;
    if (width < ResponsiveHelper.desktopBreakpoint) return 3;
    return 4;
  }

  /// Static helper for card ratio
  static double navCardRatioSafe(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < ResponsiveHelper.mobileBreakpoint) return 1.1;
    if (width < ResponsiveHelper.desktopBreakpoint) return 1.15;
    return 1.2;
  }

  bool get _isMobile => screenWidth < ResponsiveHelper.mobileBreakpoint;
  bool get _isTablet => screenWidth >= ResponsiveHelper.mobileBreakpoint && 
                        screenWidth < ResponsiveHelper.desktopBreakpoint;
  bool get _isDesktop => screenWidth >= ResponsiveHelper.desktopBreakpoint;

  /// Responsive font size - use as R.of(context).fs(baseSize)
  double fs(double baseSize) {
    if (_isMobile) return baseSize;
    if (_isTablet) return baseSize + 2;
    return baseSize + 4;
  }

  /// Navigation grid columns
  int get navGridCols {
    if (_isMobile) return 2;
    if (_isTablet) return 3;
    return 4;
  }

  /// Navigation card aspect ratio
  double get navCardRatio {
    if (_isMobile) return 1.1;
    if (_isTablet) return 1.15;
    return 1.2;
  }

  /// Responsive padding
  EdgeInsets get responsivePadding {
    if (_isMobile) return const EdgeInsets.all(12);
    if (_isTablet) return const EdgeInsets.all(16);
    return const EdgeInsets.all(24);
  }

  /// Responsive spacing
  double get spacing {
    if (_isMobile) return 8;
    if (_isTablet) return 12;
    return 16;
  }

  /// Responsive border radius
  double get borderRadius {
    if (_isMobile) return 8;
    if (_isTablet) return 12;
    return 16;
  }

  @override
  bool updateShouldNotify(R oldWidget) {
    return oldWidget.screenWidth != screenWidth ||
        oldWidget.screenHeight != screenHeight;
  }
}

/// Wrapper widget to provide R to the widget tree
class ResponsiveBuilder extends StatelessWidget {
  final Widget child;

  const ResponsiveBuilder({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return R(
      screenWidth: size.width,
      screenHeight: size.height,
      child: child,
    );
  }
}
