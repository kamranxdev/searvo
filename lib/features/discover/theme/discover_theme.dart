import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Editorial typography and theme configuration for Discover feature
/// Uses classic editorial fonts for a magazine-style appearance
class DiscoverTheme {
  DiscoverTheme._();

  // Editorial Colors
  static const Color _editorialBlack = Color(0xFF1A1A1A);
  static const Color _editorialGray = Color(0xFF4A4A4A);
  static const Color _editorialLightGray = Color(0xFF8A8A8A);
  static const Color _editorialAccent = Color(0xFFB8860B); // Dark goldenrod
  static const Color _editorialDivider = Color(0xFFE5E5E5);

  // Dark mode colors
  static const Color _darkEditorialWhite = Color(0xFFF5F5F5);
  static const Color _darkEditorialGray = Color(0xFFB0B0B0);
  static const Color _darkEditorialLightGray = Color(0xFF707070);
  static const Color _darkEditorialAccent = Color(0xFFDAA520); // Goldenrod
  static const Color _darkEditorialDivider = Color(0xFF333333);

  /// Get colors based on brightness
  static DiscoverColors colors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _darkColors : _lightColors;
  }

  static const DiscoverColors _lightColors = DiscoverColors(
    headline: _editorialBlack,
    subheadline: _editorialGray,
    body: _editorialGray,
    caption: _editorialLightGray,
    accent: _editorialAccent,
    divider: _editorialDivider,
    cardBackground: Colors.white,
    overlay: Color(0x99000000),
  );

  static const DiscoverColors _darkColors = DiscoverColors(
    headline: _darkEditorialWhite,
    subheadline: _darkEditorialGray,
    body: _darkEditorialGray,
    caption: _darkEditorialLightGray,
    accent: _darkEditorialAccent,
    divider: _darkEditorialDivider,
    cardBackground: Color(0xFF1E1E1E),
    overlay: Color(0xCC000000),
  );

  /// Masthead title - Large editorial title
  static TextStyle mastheadTitle(BuildContext context) {
    final colors = DiscoverTheme.colors(context);
    return GoogleFonts.playfairDisplay(
      fontSize: 56,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.5,
      height: 1.0,
      color: colors.headline,
    );
  }

  /// Hero headline - For featured articles
  static TextStyle heroHeadline(BuildContext context) {
    final colors = DiscoverTheme.colors(context);
    return GoogleFonts.playfairDisplay(
      fontSize: 42,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      height: 1.15,
      color: colors.headline,
    );
  }

  /// Section headline - For major article cards
  static TextStyle sectionHeadline(BuildContext context) {
    final colors = DiscoverTheme.colors(context);
    return GoogleFonts.playfairDisplay(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      height: 1.25,
      color: colors.headline,
    );
  }

  /// Card headline - For smaller article cards
  static TextStyle cardHeadline(BuildContext context) {
    final colors = DiscoverTheme.colors(context);
    return GoogleFonts.playfairDisplay(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.3,
      color: colors.headline,
    );
  }

  /// Body text - Elegant serif for readability
  static TextStyle bodyText(BuildContext context) {
    final colors = DiscoverTheme.colors(context);
    return GoogleFonts.crimsonText(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      height: 1.6,
      color: colors.body,
    );
  }

  /// Lead paragraph - Larger body text for article intros
  static TextStyle leadParagraph(BuildContext context) {
    final colors = DiscoverTheme.colors(context);
    return GoogleFonts.crimsonText(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      height: 1.7,
      color: colors.body,
    );
  }

  /// Caption text - Small text for metadata
  static TextStyle caption(BuildContext context) {
    final colors = DiscoverTheme.colors(context);
    return GoogleFonts.sourceSans3(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.2,
      height: 1.4,
      color: colors.caption,
    );
  }

  /// Category label - Uppercase category indicators
  static TextStyle categoryLabel(BuildContext context) {
    final colors = DiscoverTheme.colors(context);
    return GoogleFonts.sourceSans3(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 2.0,
      height: 1.0,
      color: colors.accent,
    );
  }

  /// Navigation item - For topic selectors
  static TextStyle navItem(BuildContext context, {bool isActive = false}) {
    final colors = DiscoverTheme.colors(context);
    return GoogleFonts.sourceSans3(
      fontSize: 13,
      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
      letterSpacing: 1.5,
      height: 1.0,
      color: isActive ? colors.accent : colors.caption,
    );
  }

  /// Quote text - For pull quotes
  static TextStyle quoteText(BuildContext context) {
    final colors = DiscoverTheme.colors(context);
    return GoogleFonts.playfairDisplay(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      letterSpacing: 0.2,
      height: 1.5,
      color: colors.subheadline,
    );
  }

  /// Byline text - For author names
  static TextStyle byline(BuildContext context) {
    final colors = DiscoverTheme.colors(context);
    return GoogleFonts.sourceSans3(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      height: 1.4,
      color: colors.subheadline,
    );
  }

  /// Date text - For timestamps
  static TextStyle dateText(BuildContext context) {
    final colors = DiscoverTheme.colors(context);
    return GoogleFonts.sourceSans3(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.3,
      height: 1.4,
      color: colors.caption,
    );
  }

  /// Hero headline on dark overlay
  static TextStyle heroHeadlineLight(BuildContext context) {
    return GoogleFonts.playfairDisplay(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.2,
      color: Colors.white,
    );
  }

  /// Body text on dark overlay
  static TextStyle bodyTextLight(BuildContext context) {
    return GoogleFonts.crimsonText(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.2,
      height: 1.5,
      color: Colors.white.withOpacity(0.9),
    );
  }

  /// Category label on dark overlay
  static TextStyle categoryLabelLight(BuildContext context) {
    return GoogleFonts.sourceSans3(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 2.0,
      height: 1.0,
      color: const Color(0xFFDAA520),
    );
  }
}

/// Color palette for Discover feature
class DiscoverColors {
  final Color headline;
  final Color subheadline;
  final Color body;
  final Color caption;
  final Color accent;
  final Color divider;
  final Color cardBackground;
  final Color overlay;

  const DiscoverColors({
    required this.headline,
    required this.subheadline,
    required this.body,
    required this.caption,
    required this.accent,
    required this.divider,
    required this.cardBackground,
    required this.overlay,
  });
}
