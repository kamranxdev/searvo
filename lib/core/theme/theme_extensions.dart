import 'package:flutter/material.dart';
import 'theme_manager.dart';

/// Extension on BuildContext for convenient theme access
/// 
/// Provides easy access to:
/// - Theme data and color schemes
/// - Text themes with adaptive sizing
/// - Theme manager for theme switching
/// - Brightness checks
extension ThemeExtensions on BuildContext {
  // ============================================================================
  // THEME DATA ACCESS
  // ============================================================================

  /// Access the current theme data
  ThemeData get theme => Theme.of(this);

  /// Access the current color scheme
  ColorScheme get colorScheme => theme.colorScheme;

  /// Access the current text theme (with adaptive sizing)
  TextTheme get textTheme => theme.textTheme;

  /// Access the theme manager for theme operations
  ThemeManager get themeManager => ThemeManager();

  // ============================================================================
  // BRIGHTNESS HELPERS
  // ============================================================================

  /// Check if the current theme is dark
  bool get isDark => theme.brightness == Brightness.dark;

  /// Check if the current theme is light
  bool get isLight => theme.brightness == Brightness.light;

  /// Get the current brightness
  Brightness get brightness => theme.brightness;

  // ============================================================================
  // ADAPTIVE COLOR HELPERS
  // ============================================================================

  /// Get a color that adapts to the current theme
  /// 
  /// Usage:
  /// ```dart
  /// final color = context.adaptiveColor(
  ///   light: Colors.black,
  ///   dark: Colors.white,
  /// );
  /// ```
  Color adaptiveColor({
    required Color light,
    required Color dark,
  }) {
    return isDark ? dark : light;
  }

  /// Get the appropriate text color based on background
  /// 
  /// Returns onPrimary, onSecondary, onSurface, etc. based on the background
  Color textColorOnBackground(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  // ============================================================================
  // QUICK THEME MODE SWITCHING
  // ============================================================================

  /// Set light theme mode
  Future<bool> setLightTheme() => themeManager.setLightMode();

  /// Set dark theme mode
  Future<bool> setDarkTheme() => themeManager.setDarkMode();

  /// Set system theme mode
  Future<bool> setSystemTheme() => themeManager.setSystemMode();

  /// Toggle between light and dark themes
  Future<bool> toggleTheme() => themeManager.toggleTheme();

  /// Cycle through all theme modes
  Future<bool> cycleThemeMode() => themeManager.cycleThemeMode();

  // ============================================================================
  // RESPONSIVE HELPERS
  // ============================================================================

  /// Check if the screen is in mobile layout
  bool get isMobile => MediaQuery.of(this).size.width < 600;

  /// Check if the screen is in tablet layout
  bool get isTablet {
    final width = MediaQuery.of(this).size.width;
    return width >= 600 && width < 1200;
  }

  /// Check if the screen is in desktop layout
  bool get isDesktop => MediaQuery.of(this).size.width >= 1200;

  /// Get the current screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get the current screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Get responsive padding based on screen size
  EdgeInsets get responsivePadding {
    if (isMobile) {
      return const EdgeInsets.all(16);
    } else if (isTablet) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

  /// Get responsive horizontal padding
  EdgeInsets get responsiveHorizontalPadding {
    if (isMobile) {
      return const EdgeInsets.symmetric(horizontal: 16);
    } else if (isTablet) {
      return const EdgeInsets.symmetric(horizontal: 24);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32);
    }
  }
}

/// Extension on ColorScheme for additional color utilities
extension ColorSchemeExtensions on ColorScheme {
  /// Get a slightly lighter version of a color
  Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightened = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return lightened.toColor();
  }

  /// Get a slightly darker version of a color
  Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final darkened = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return darkened.toColor();
  }

  /// Get a color with adjusted opacity
  Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
}

/// Extension on TextTheme for additional text style utilities
extension TextThemeExtensions on TextTheme {
  /// Get a text style with a specific color
  TextStyle? withColor(TextStyle? style, Color color) {
    return style?.copyWith(color: color);
  }

  /// Get a text style with a specific font weight
  TextStyle? withWeight(TextStyle? style, FontWeight weight) {
    return style?.copyWith(fontWeight: weight);
  }

  /// Get a text style with a specific font size
  TextStyle? withSize(TextStyle? style, double size) {
    return style?.copyWith(fontSize: size);
  }

  /// Get a text style with multiple properties
  TextStyle? customize(
    TextStyle? style, {
    Color? color,
    FontWeight? weight,
    double? size,
    double? height,
    double? letterSpacing,
  }) {
    return style?.copyWith(
      color: color,
      fontWeight: weight,
      fontSize: size,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
