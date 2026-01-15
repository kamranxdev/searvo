import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Professional settings theme with clean, technical look
/// Uses clear hierarchy and spacing for configuration interfaces
class SettingsTheme {
  SettingsTheme._();

  // Settings Colors
  static const Color _settingsBlack = Color(0xFF1E1E1E);
  static const Color _settingsGray = Color(0xFF5D5D5D);
  static const Color _settingsLightGray = Color(0xFF9E9E9E);
  static const Color _settingsAccent = Color(0xFF00B4A6); // Teal accent
  static const Color _settingsDivider = Color(0xFFEEEEEE);
  static const Color _settingsError = Color(0xFFD32F2F);

  // Dark mode colors
  static const Color _darkSettingsWhite = Color(0xFFE0E0E0);
  static const Color _darkSettingsGray = Color(0xFFA0A0A0);
  static const Color _darkSettingsLightGray = Color(0xFF616161);
  static const Color _darkSettingsAccent = Color(0xFF4DB6AC); // Lighter teal
  static const Color _darkSettingsDivider = Color(0xFF424242);
  static const Color _darkSettingsError = Color(0xFFEF5350);

  /// Get colors based on brightness
  static SettingsColors colors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _darkColors : _lightColors;
  }

  static const SettingsColors _lightColors = SettingsColors(
    header: _settingsBlack,
    text: _settingsBlack,
    subtitle: _settingsGray,
    caption: _settingsLightGray,
    accent: _settingsAccent,
    divider: _settingsDivider,
    background: Color(0xFFF5F5F7),
    cardBackground: Colors.white,
    inputBackground: Color(0xFFFAFAFA),
    border: Color(0xFFE0E0E0),
    error: _settingsError,
    icon: _settingsGray,
    inverseText: Colors.white,
  );

  static const SettingsColors _darkColors = SettingsColors(
    header: _darkSettingsWhite,
    text: _darkSettingsWhite,
    subtitle: _darkSettingsGray,
    caption: _darkSettingsLightGray,
    accent: _darkSettingsAccent,
    divider: _darkSettingsDivider,
    background: Color(0xFF121212),
    cardBackground: Color(0xFF1E1E1E),
    inputBackground: Color(0xFF2C2C2C),
    border: Color(0xFF424242),
    error: _darkSettingsError,
    icon: _darkSettingsGray,
    inverseText: _settingsBlack,
  );

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
    required this.icon,
    required this.inverseText,
  });
}
