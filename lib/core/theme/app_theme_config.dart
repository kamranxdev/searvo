import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Application theme configuration
/// 
/// Provides professionally structured theme configuration with:
/// - Adaptive text themes for different screen sizes
/// - Consistent color system
/// - Proper Material 3 implementation
/// - No backward compatibility constraints
class AppThemeConfig {
  AppThemeConfig._();

  // ============================================================================
  // BRAND COLORS
  // ============================================================================
  
  static const Color primaryColor = Color(0xFF00B4A6);
  static const Color secondaryColor = Color(0xFF4A9EFF);
  static const Color errorColor = Color(0xFFFF6B6B);
  static const Color successColor = Color(0xFF51CF66);
  static const Color warningColor = Color(0xFFFFD93D);
  static const Color infoColor = Color(0xFF4DABF7);

  // ============================================================================
  // THEME DATA GETTERS
  // ============================================================================

  /// Returns the dark theme configuration
  static ThemeData getDarkTheme(BuildContext context) {
    final textTheme = _buildAdaptiveTextTheme(context, brightness: Brightness.dark);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: _DarkThemeColors.surface,
        surfaceContainerHighest: _DarkThemeColors.surfaceContainer,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: _DarkThemeColors.onSurface,
        onError: Colors.white,
        outline: _DarkThemeColors.outline,
        outlineVariant: _DarkThemeColors.outlineVariant,
      ),

      scaffoldBackgroundColor: _DarkThemeColors.background,
      
      textTheme: textTheme,
      
      appBarTheme: AppBarTheme(
        backgroundColor: _DarkThemeColors.background,
        foregroundColor: _DarkThemeColors.onSurface,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.titleLarge,
      ),

      cardTheme: CardThemeData(
        color: _DarkThemeColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _DarkThemeColors.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: _DarkThemeColors.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: _DarkThemeColors.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _DarkThemeColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _DarkThemeColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      iconTheme: IconThemeData(
        color: _DarkThemeColors.onSurfaceVariant,
        size: 24,
      ),

      dividerTheme: DividerThemeData(
        color: _DarkThemeColors.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: _DarkThemeColors.onSurfaceVariant,
        textColor: _DarkThemeColors.onSurface,
        tileColor: Colors.transparent,
        selectedTileColor: primaryColor.withOpacity(0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return _DarkThemeColors.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withOpacity(0.3);
          }
          return _DarkThemeColors.surfaceContainer;
        }),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _DarkThemeColors.surfaceContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: _DarkThemeColors.onSurface,
        ),
      ),
    );
  }

  /// Returns the light theme configuration
  static ThemeData getLightTheme(BuildContext context) {
    final textTheme = _buildAdaptiveTextTheme(context, brightness: Brightness.light);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: _LightThemeColors.surface,
        surfaceContainerHighest: _LightThemeColors.surfaceContainer,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: _LightThemeColors.onSurface,
        onError: Colors.white,
        outline: _LightThemeColors.outline,
        outlineVariant: _LightThemeColors.outlineVariant,
      ),

      scaffoldBackgroundColor: _LightThemeColors.background,
      
      textTheme: textTheme,
      
      appBarTheme: AppBarTheme(
        backgroundColor: _LightThemeColors.background,
        foregroundColor: _LightThemeColors.onSurface,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge,
      ),

      cardTheme: CardThemeData(
        color: _LightThemeColors.surface,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.05),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _LightThemeColors.surfaceContainer,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: _LightThemeColors.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: _LightThemeColors.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _LightThemeColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _LightThemeColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.black.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      iconTheme: IconThemeData(
        color: _LightThemeColors.onSurfaceVariant,
        size: 24,
      ),

      dividerTheme: DividerThemeData(
        color: _LightThemeColors.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: _LightThemeColors.onSurfaceVariant,
        textColor: _LightThemeColors.onSurface,
        tileColor: Colors.transparent,
        selectedTileColor: primaryColor.withOpacity(0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return _LightThemeColors.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withOpacity(0.3);
          }
          return _LightThemeColors.surfaceContainer;
        }),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _LightThemeColors.onSurface,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }

  // ============================================================================
  // ADAPTIVE TEXT THEME
  // ============================================================================

  /// Builds an adaptive text theme based on screen size and brightness
  /// 
  /// Automatically scales text sizes for:
  /// - Mobile: Base sizes
  /// - Tablet: 1.1x scale
  /// - Desktop: 1.15x scale
  static TextTheme _buildAdaptiveTextTheme(
    BuildContext context, {
    required Brightness brightness,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = _getTextScaleFactor(screenWidth);
    final color = brightness == Brightness.dark 
        ? _DarkThemeColors.onSurface 
        : _LightThemeColors.onSurface;
    final colorVariant = brightness == Brightness.dark 
        ? _DarkThemeColors.onSurfaceVariant 
        : _LightThemeColors.onSurfaceVariant;

    return TextTheme(
      // Display styles - Large, prominent text
      displayLarge: TextStyle(
        fontSize: 57 * scaleFactor,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.12,
        color: color,
      ),
      displayMedium: TextStyle(
        fontSize: 45 * scaleFactor,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.16,
        color: color,
      ),
      displaySmall: TextStyle(
        fontSize: 36 * scaleFactor,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.22,
        color: color,
      ),

      // Headline styles - High emphasis, shorter text
      headlineLarge: TextStyle(
        fontSize: 32 * scaleFactor,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.25,
        color: color,
      ),
      headlineMedium: TextStyle(
        fontSize: 28 * scaleFactor,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.29,
        color: color,
      ),
      headlineSmall: TextStyle(
        fontSize: 24 * scaleFactor,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.33,
        color: color,
      ),

      // Title styles - Medium emphasis
      titleLarge: TextStyle(
        fontSize: 22 * scaleFactor,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.27,
        color: color,
      ),
      titleMedium: TextStyle(
        fontSize: 16 * scaleFactor,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.50,
        color: color,
      ),
      titleSmall: TextStyle(
        fontSize: 14 * scaleFactor,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        color: color,
      ),

      // Body styles - Paragraph text
      bodyLarge: TextStyle(
        fontSize: 16 * scaleFactor,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.50,
        color: color,
      ),
      bodyMedium: TextStyle(
        fontSize: 14 * scaleFactor,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
        color: color,
      ),
      bodySmall: TextStyle(
        fontSize: 12 * scaleFactor,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
        color: colorVariant,
      ),

      // Label styles - Buttons, tabs
      labelLarge: TextStyle(
        fontSize: 14 * scaleFactor,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        color: color,
      ),
      labelMedium: TextStyle(
        fontSize: 12 * scaleFactor,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
        color: colorVariant,
      ),
      labelSmall: TextStyle(
        fontSize: 11 * scaleFactor,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.45,
        color: colorVariant,
      ),
    );
  }

  /// Calculates text scale factor based on screen width
  static double _getTextScaleFactor(double screenWidth) {
    if (screenWidth < 600) {
      // Mobile
      return 1.0;
    } else if (screenWidth < 1200) {
      // Tablet
      return 1.1;
    } else {
      // Desktop
      return 1.15;
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Returns true if the current theme is dark
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Returns the appropriate color based on theme brightness
  static Color adaptiveColor(
    BuildContext context, {
    required Color light,
    required Color dark,
  }) {
    return isDark(context) ? dark : light;
  }
}

// ==============================================================================
// PRIVATE COLOR CLASSES
// ==============================================================================

/// Dark theme color palette
class _DarkThemeColors {
  const _DarkThemeColors();

  static const Color background = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFF2A2A2A);
  static const Color surfaceContainer = Color(0xFF3A3A3A);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFFB3B3B3);
  static const Color outline = Color(0xFF3A3A3A);
  static const Color outlineVariant = Color(0xFF2A2A2A);
}

/// Light theme color palette
class _LightThemeColors {
  const _LightThemeColors();

  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFF5F5F5);
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color onSurfaceVariant = Color(0xFF666666);
  static const Color outline = Color(0xFFE5E5E5);
  static const Color outlineVariant = Color(0xFFF0F0F0);
}
