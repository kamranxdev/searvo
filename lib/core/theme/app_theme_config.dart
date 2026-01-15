import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Application theme configuration
///
/// Provides professionally structured theme configuration with:
/// - Premium Gold & Dark aesthetic
/// - Adaptive text themes for different screen sizes
/// - Consistent color system
/// - Proper Material 3 implementation
class AppThemeConfig {
  AppThemeConfig._();

  // ============================================================================
  // BRAND COLORS - PREMIUM GOLD
  // ============================================================================

  static const Color primaryColor = Color(0xFFD4AF37); // Rich gold
  static const Color secondaryColor = Color(0xFFFFBF00); // Amber gold
  static const Color errorColor = Color(0xFFB00020);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color infoColor = Color(0xFF2196F3);

  // Dark variant specific brand colors
  static const Color _darkPrimaryColor = Color(0xFFF4C430); // Bright gold
  static const Color _darkSecondaryColor = Color(0xFFFFD700); // Gold
  static const Color _darkErrorColor = Color(0xFFCF6679);

  // ============================================================================
  // THEME DATA GETTERS
  // ============================================================================

  /// Returns the dark theme configuration
  static ThemeData getDarkTheme(BuildContext context) {
    final textTheme = _buildAdaptiveTextTheme(
      context,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        primary: _darkPrimaryColor,
        secondary: _darkSecondaryColor,
        surface: _DarkThemeColors.surface,
        surfaceContainerHighest: _DarkThemeColors.surfaceContainer,
        error: _darkErrorColor,
        onPrimary: Colors.black, // Dark text on gold looks better
        onSecondary: Colors.black,
        onSurface: _DarkThemeColors.onSurface,
        onError: Colors.black,
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
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: _DarkThemeColors.onSurface,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: _DarkThemeColors.onSurfaceVariant),
      ),

      cardTheme: CardThemeData(
        color: _DarkThemeColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _DarkThemeColors.outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _DarkThemeColors.surface, // Matches card/surface
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
          borderSide: const BorderSide(color: _darkPrimaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _darkErrorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _darkErrorColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimaryColor,
          foregroundColor: Colors.black, // Better contrast
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkPrimaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _darkPrimaryColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      iconTheme: IconThemeData(
        color: _DarkThemeColors.onSurfaceVariant,
        size: 24,
      ),

      dividerTheme: DividerThemeData(
        color: _DarkThemeColors.outline.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: _DarkThemeColors.onSurfaceVariant,
        textColor: _DarkThemeColors.onSurface,
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _darkPrimaryColor;
          }
          return _DarkThemeColors.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _darkPrimaryColor.withValues(alpha: 0.3);
          }
          return _DarkThemeColors.surfaceContainer;
        }),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _DarkThemeColors.surfaceContainer,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _DarkThemeColors.outline),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: _DarkThemeColors.onSurface,
        ),
      ),
    );
  }

  /// Returns the light theme configuration
  static ThemeData getLightTheme(BuildContext context) {
    final textTheme = _buildAdaptiveTextTheme(
      context,
      brightness: Brightness.light,
    );

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
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: _LightThemeColors.onSurface,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: _LightThemeColors.onSurfaceVariant),
      ),

      cardTheme: CardThemeData(
        color: _LightThemeColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _LightThemeColors.outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _LightThemeColors.surface,
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
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      iconTheme: IconThemeData(
        color: _LightThemeColors.onSurfaceVariant,
        size: 24,
      ),

      dividerTheme: DividerThemeData(
        color: _LightThemeColors.outline.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: _LightThemeColors.onSurfaceVariant,
        textColor: _LightThemeColors.onSurface,
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            return primaryColor.withValues(alpha: 0.3);
          }
          return _LightThemeColors.surfaceContainer;
        }),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _LightThemeColors.onSurface,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: Colors.white),
      ),
    );
  }

  // ============================================================================
  // ADAPTIVE TEXT THEME - INTER
  // ============================================================================

  /// Builds an adaptive text theme based on screen size and brightness
  /// Uses GoogleFonts.inter for a modern, clean look
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

    // Base text theme from Google Fonts
    final baseTextTheme = GoogleFonts.interTextTheme();

    return TextTheme(
      // Display styles - Large, prominent text
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontSize: 57 * scaleFactor,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        height: 1.12,
        color: color,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontSize: 45 * scaleFactor,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.16,
        color: color,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontSize: 36 * scaleFactor,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.22,
        color: color,
      ),

      // Headline styles - High emphasis, shorter text
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontSize: 32 * scaleFactor,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.25,
        color: color,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: 28 * scaleFactor,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.29,
        color: color,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontSize: 24 * scaleFactor,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.33,
        color: color,
      ),

      // Title styles - Medium emphasis
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 22 * scaleFactor,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.27,
        color: color,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 16 * scaleFactor,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.50,
        color: color,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontSize: 14 * scaleFactor,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        color: color,
      ),

      // Body styles - Paragraph text
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 16 * scaleFactor,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.50,
        color: color,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14 * scaleFactor,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
        color: color,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: 12 * scaleFactor,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
        color: colorVariant,
      ),

      // Label styles - Buttons, tabs
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 14 * scaleFactor,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        color: color,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 12 * scaleFactor,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
        color: colorVariant,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
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

/// Dark theme color palette - Premium Dark Integration
class _DarkThemeColors {
  const _DarkThemeColors();

  static const Color background = Color(0xFF1A1A1A); // Deep rich black
  static const Color surface = Color(0xFF2A2A2A); // Slightly lighter surface
  static const Color surfaceContainer = Color(0xFF333333); // For containers
  static const Color onSurface = Color(0xFFF5F5F5); // High emphasis white
  static const Color onSurfaceVariant = Color(
    0xFFB0B0B0,
  ); // Medium emphasis gray
  static const Color outline = Color(0xFF404040); // Subtle borders
  static const Color outlineVariant = Color(0xFF2A2A2A);
}

/// Light theme color palette - Clean & Bright
class _LightThemeColors {
  const _LightThemeColors();

  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F8F8);
  static const Color surfaceContainer = Color(0xFFF0F0F0);
  static const Color onSurface = Color(0xFF1A1A1A); // High emphasis black
  static const Color onSurfaceVariant = Color(
    0xFF4A4A4A,
  ); // Medium emphasis gray
  static const Color outline = Color(0xFFE0E0E0);
  static const Color outlineVariant = Color(0xFFF0F0F0);
}
