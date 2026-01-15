import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium search interface theme with rich gold accents
/// Uses modern sans-serif fonts for a sleek, professional appearance
class SearchTheme {
  SearchTheme._();

  // Premium Gold Colors
  static const Color _premiumGold = Color(0xFFD4AF37); // Rich gold
  static const Color _premiumAmber = Color(0xFFFFBF00); // Amber gold
  static const Color _searchBlack = Color(0xFF1A1A1A);
  static const Color _searchGray = Color(0xFF4A4A4A);
  static const Color _searchLightGray = Color(0xFF8A8A8A);
  static const Color _searchDivider = Color(0xFFE5E5E5);
  static const Color _searchError = Color(0xFFB00020);

  // Dark mode colors
  static const Color _darkPremiumGold = Color(0xFFF4C430); // Bright gold
  static const Color _darkPremiumAmber = Color(0xFFFFD700); // Gold
  static const Color _darkSearchWhite = Color(0xFFF5F5F5);
  static const Color _darkSearchGray = Color(0xFFB0B0B0);
  static const Color _darkSearchLightGray = Color(0xFF707070);
  static const Color _darkSearchDivider = Color(0xFF333333);
  static const Color _darkSearchError = Color(0xFFCF6679);

  /// Get colors based on brightness
  static SearchColors colors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _darkColors : _lightColors;
  }

  static const SearchColors _lightColors = SearchColors(
    primary: _premiumGold,
    secondary: _premiumAmber,
    text: _searchBlack,
    subtitle: _searchGray,
    caption: _searchLightGray,
    accent: _premiumGold,
    divider: _searchDivider,
    background: Colors.white,
    surface: Color(0xFFF8F8F8),
    inputBackground: Colors.white,
    border: Color(0xFFE0E0E0),
    error: _searchError,
    surfaceContainerHighest: Color(0xFFF0F0F0),
    outline: Color(0xFFE0E0E0),
    onSurface: _searchBlack,
    onSurfaceVariant: _searchGray,
  );

  static const SearchColors _darkColors = SearchColors(
    primary: _darkPremiumGold,
    secondary: _darkPremiumAmber,
    text: _darkSearchWhite,
    subtitle: _darkSearchGray,
    caption: _darkSearchLightGray,
    accent: _darkPremiumGold,
    divider: _darkSearchDivider,
    background: Color(0xFF1A1A1A),
    surface: Color(0xFF2A2A2A),
    inputBackground: Color(0xFF2A2A2A),
    border: Color(0xFF404040),
    error: _darkSearchError,
    surfaceContainerHighest: Color(0xFF333333),
    outline: Color(0xFF404040),
    onSurface: _darkSearchWhite,
    onSurfaceVariant: _darkSearchGray,
  );

  /// Search input field
  static TextStyle searchInput(BuildContext context) {
    final colors = SearchTheme.colors(context);
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      height: 1.5,
      color: colors.text,
    );
  }

  /// Search placeholder text
  static TextStyle searchPlaceholder(BuildContext context) {
    final colors = SearchTheme.colors(context);
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      height: 1.5,
      color: colors.caption,
    );
  }

  /// Search result title
  static TextStyle resultTitle(BuildContext context) {
    final colors = SearchTheme.colors(context);
    return GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.3,
      color: colors.text,
    );
  }

  /// Search result snippet
  static TextStyle resultSnippet(BuildContext context) {
    final colors = SearchTheme.colors(context);
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      height: 1.6,
      color: colors.subtitle,
    );
  }

  /// Search result URL
  static TextStyle resultUrl(BuildContext context) {
    final colors = SearchTheme.colors(context);
    return GoogleFonts.robotoMono(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      height: 1.4,
      color: colors.accent,
    );
  }

  /// Search suggestion
  static TextStyle suggestion(BuildContext context) {
    final colors = SearchTheme.colors(context);
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.4,
      color: colors.text,
    );
  }

  /// Search filter label
  static TextStyle filterLabel(BuildContext context, {bool isActive = false}) {
    final colors = SearchTheme.colors(context);
    return GoogleFonts.inter(
      fontSize: 13,
      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.2,
      color: isActive ? colors.accent : colors.caption,
    );
  }

  /// Search mode indicator
  static TextStyle modeIndicator(BuildContext context) {
    final colors = SearchTheme.colors(context);
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
      height: 1.2,
      color: colors.accent,
    );
  }

  /// Search loading text
  static TextStyle loadingText(BuildContext context) {
    final colors = SearchTheme.colors(context);
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.4,
      color: colors.subtitle,
    );
  }

  /// Search error text
  static TextStyle errorText(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.4,
      color: Colors.red.shade600,
    );
  }

  /// Search empty state title
  static TextStyle emptyStateTitle(BuildContext context) {
    final colors = SearchTheme.colors(context);
    return GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      height: 1.3,
      color: colors.text,
    );
  }

  /// Search empty state subtitle
  static TextStyle emptyStateSubtitle(BuildContext context) {
    final colors = SearchTheme.colors(context);
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      height: 1.5,
      color: colors.subtitle,
    );
  }

  /// Message bubble text
  static TextStyle messageText(BuildContext context) {
    final colors = SearchTheme.colors(context);
    return GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      height: 1.5,
      color: colors.text,
    );
  }

  /// Message timestamp
  static TextStyle messageTimestamp(BuildContext context) {
    final colors = SearchTheme.colors(context);
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.3,
      color: colors.caption,
    );
  }

  /// Citation link
  static TextStyle citationLink(BuildContext context) {
    final colors = SearchTheme.colors(context);
    return GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.4,
      color: colors.accent,
      decoration: TextDecoration.underline,
      decorationColor: colors.accent,
    );
  }
}

/// Color palette for Search feature
class SearchColors {
  final Color primary;
  final Color secondary;
  final Color text;
  final Color subtitle;
  final Color caption;
  final Color accent;
  final Color divider;
  final Color background;
  final Color surface;
  final Color inputBackground;
  final Color border;
  final Color error;
  final Color surfaceContainerHighest;
  final Color outline;
  final Color onSurface;
  final Color onSurfaceVariant;

  const SearchColors({
    required this.primary,
    required this.secondary,
    required this.text,
    required this.subtitle,
    required this.caption,
    required this.accent,
    required this.divider,
    required this.background,
    required this.surface,
    required this.inputBackground,
    required this.border,
    required this.error,
    required this.surfaceContainerHighest,
    required this.outline,
    required this.onSurface,
    required this.onSurfaceVariant,
  });
}