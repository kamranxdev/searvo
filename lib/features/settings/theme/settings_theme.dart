import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Professional settings theme with clean, technical look
/// Uses clear hierarchy and spacing for configuration interfaces
class SettingsTheme {
  SettingsTheme._();

  // Settings Colors
  /// Get colors based on brightness and app theme
  static SettingsColors colors(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (isDark) {
      return SettingsColors(
        header: colorScheme.onSurface,
        text: colorScheme.onSurface,
        subtitle: colorScheme.onSurfaceVariant,
        caption: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        accent: colorScheme.primary, // Gold
        divider: colorScheme.outlineVariant,
        background: colorScheme.surface,
        cardBackground: colorScheme.surfaceContainer,
        inputBackground: colorScheme.surfaceContainerHighest,
        border: colorScheme.outline,
        error: colorScheme.error,
        success: const Color(0xFF4CAF50), // Consistent success color
        icon: colorScheme.onSurfaceVariant,
        inverseText: colorScheme.onPrimary,
      );
    } else {
      return SettingsColors(
        header: colorScheme.onSurface,
        text: colorScheme.onSurface,
        subtitle: colorScheme.onSurfaceVariant,
        caption: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        accent: colorScheme.primary, // Gold
        divider: colorScheme.outlineVariant,
        background: colorScheme.surface,
        cardBackground: colorScheme.surface,
        inputBackground: colorScheme.surfaceContainer,
        border: colorScheme.outline,
        error: colorScheme.error,
        success: const Color(0xFF4CAF50), // Consistent success color
        icon: colorScheme.onSurfaceVariant,
        inverseText: colorScheme.onPrimary,
      );
    }
  }

  // Legacy static colors (kept for reference if needed, but unused in main logic now)
  // ...

  /// Page Title
  static TextStyle pageTitle(BuildContext context) {
    final colors = SettingsTheme.colors(context);
    return GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      height: 1.3,
      color: colors.header,
    );
  }

  /// Section Header
  static TextStyle sectionHeader(BuildContext context) {
    final colors = SettingsTheme.colors(context);
    return GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
      height: 1.5,
      color: colors.caption,
    );
  }

  /// Setting Title
  static TextStyle settingTitle(BuildContext context) {
    final colors = SettingsTheme.colors(context);
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.4,
      color: colors.text,
    );
  }

  /// Setting Description
  static TextStyle settingDescription(BuildContext context) {
    final colors = SettingsTheme.colors(context);
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.2,
      height: 1.5,
      color: colors.subtitle,
    );
  }

  /// Input Text
  static TextStyle inputText(BuildContext context) {
    final colors = SettingsTheme.colors(context);
    return GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      height: 1.4,
      color: colors.text,
    );
  }

  /// Input Label
  static TextStyle inputLabel(BuildContext context) {
    final colors = SettingsTheme.colors(context);
    return GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
      height: 1.4,
      color: colors.subtitle,
    );
  }

  /// Action Button
  static TextStyle actionButton(BuildContext context) {
    final colors = SettingsTheme.colors(context);
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      height: 1.4,
      color: colors.accent,
    );
  }

  /// Error Text
  static TextStyle errorText(BuildContext context) {
    final colors = SettingsTheme.colors(context);
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
      height: 1.4,
      color: colors.error,
    );
  }
}

/// Color palette for Settings feature
class SettingsColors {
  final Color header;
  final Color text;
  final Color subtitle;
  final Color caption;
  final Color accent;
  final Color divider;
  final Color background;
  final Color cardBackground;
  final Color inputBackground;
  final Color border;
  final Color error;
  final Color success;
  final Color icon;
  final Color inverseText;

  const SettingsColors({
    required this.header,
    required this.text,
    required this.subtitle,
    required this.caption,
    required this.accent,
    required this.divider,
    required this.background,
    required this.cardBackground,
    required this.inputBackground,
    required this.border,
    required this.error,
    required this.success,
    required this.icon,
    required this.inverseText,
  });
}
