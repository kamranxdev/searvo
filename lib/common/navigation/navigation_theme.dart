import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Editorial navigation theme that complements the Discover feature styling
/// Provides typography, colors, and constants for navigation components
class NavigationTheme {
  NavigationTheme._();

  // ═══════════════════════════════════════════════════════════════════════════
  // DIMENSIONS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Sidebar widths
  static const double sidebarExpandedWidth = 260;
  static const double sidebarCollapsedWidth = 72;
  
  /// Item dimensions
  static const double navItemHeight = 48;
  static const double iconSize = 22;
  static const double logoSize = 36;
  
  /// Spacing
  static const double horizontalPadding = 16;
  static const double itemSpacing = 4;
  static const double sectionSpacing = 24;
  
  /// Border radius
  static const double itemBorderRadius = 12;
  static const double mobilePillRadius = 28;
  
  /// Animation durations
  static const Duration expandDuration = Duration(milliseconds: 280);
  static const Duration hoverDuration = Duration(milliseconds: 200);
  static const Duration transitionDuration = Duration(milliseconds: 350);

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORS
  // ═══════════════════════════════════════════════════════════════════════════
  
  static NavigationColors colors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _darkColors : _lightColors;
  }

  static const NavigationColors _lightColors = NavigationColors(
    // Surface colors
    sidebarBackground: Color(0xFFFAFAFA),
    mobileNavBackground: Color(0xFFFFFFFE),
    
    // Active states
    activeBackground: Color(0xFFF0EBE3),
    activeText: Color(0xFF1A1A1A),
    activeIcon: Color(0xFF1A1A1A),
    activeIndicator: Color(0xFFB8860B), // Goldenrod accent
    
    // Inactive states
    inactiveText: Color(0xFF6B6B6B),
    inactiveIcon: Color(0xFF8A8A8A),
    
    // Hover states
    hoverBackground: Color(0xFFF5F5F5),
    hoverText: Color(0xFF3A3A3A),
    
    // Brand
    brandText: Color(0xFF1A1A1A),
    brandAccent: Color(0xFFB8860B),
    
    // Borders and dividers
    divider: Color(0xFFE8E8E8),
    border: Color(0xFFE0E0E0),
    
    // Shadows
    shadowPrimary: Color(0x0A000000),
    shadowSecondary: Color(0x05000000),
  );

  static const NavigationColors _darkColors = NavigationColors(
    // Surface colors
    sidebarBackground: Color(0xFF141414),
    mobileNavBackground: Color(0xFF1A1A1A),
    
    // Active states
    activeBackground: Color(0xFF2A2520),
    activeText: Color(0xFFF5F5F5),
    activeIcon: Color(0xFFF5F5F5),
    activeIndicator: Color(0xFFDAA520), // Goldenrod accent
    
    // Inactive states
    inactiveText: Color(0xFF8A8A8A),
    inactiveIcon: Color(0xFF6B6B6B),
    
    // Hover states
    hoverBackground: Color(0xFF1E1E1E),
    hoverText: Color(0xFFB0B0B0),
    
    // Brand
    brandText: Color(0xFFF5F5F5),
    brandAccent: Color(0xFFDAA520),
    
    // Borders and dividers
    divider: Color(0xFF2A2A2A),
    border: Color(0xFF333333),
    
    // Shadows
    shadowPrimary: Color(0x40000000),
    shadowSecondary: Color(0x20000000),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPOGRAPHY
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Brand logo text - Editorial masthead style
  static TextStyle brandText(BuildContext context, {bool isExpanded = true}) {
    final colors = NavigationTheme.colors(context);
    return GoogleFonts.playfairDisplay(
      fontSize: isExpanded ? 24 : 18,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: colors.brandText,
    );
  }

  /// Navigation item text - Clean sans-serif
  static TextStyle navItemText(BuildContext context, {bool isActive = false}) {
    final colors = NavigationTheme.colors(context);
    return GoogleFonts.sourceSans3(
      fontSize: 15,
      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
      letterSpacing: 0.2,
      color: isActive ? colors.activeText : colors.inactiveText,
    );
  }

  /// Section label text - All caps editorial style
  static TextStyle sectionLabel(BuildContext context) {
    final colors = NavigationTheme.colors(context);
    return GoogleFonts.sourceSans3(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.5,
      color: colors.inactiveText,
    );
  }

  /// Tooltip text
  static TextStyle tooltipText(BuildContext context) {
    final colors = NavigationTheme.colors(context);
    return GoogleFonts.sourceSans3(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
      color: colors.activeText,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DECORATIONS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Sidebar container decoration
  static BoxDecoration sidebarDecoration(BuildContext context) {
    final colors = NavigationTheme.colors(context);
    return BoxDecoration(
      color: colors.sidebarBackground,
      border: Border(
        right: BorderSide(
          color: colors.divider,
          width: 1,
        ),
      ),
    );
  }

  /// Mobile navigation pill decoration
  static BoxDecoration mobileNavDecoration(BuildContext context) {
    final colors = NavigationTheme.colors(context);
    return BoxDecoration(
      color: colors.mobileNavBackground,
      borderRadius: BorderRadius.circular(mobilePillRadius),
      border: Border.all(
        color: colors.border.withValues(alpha: 0.5),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: colors.shadowPrimary,
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: colors.shadowSecondary,
          blurRadius: 48,
          offset: const Offset(0, 16),
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Active nav item decoration
  static BoxDecoration activeItemDecoration(BuildContext context) {
    final colors = NavigationTheme.colors(context);
    return BoxDecoration(
      color: colors.activeBackground,
      borderRadius: BorderRadius.circular(itemBorderRadius),
    );
  }

  /// Hover nav item decoration
  static BoxDecoration hoverItemDecoration(BuildContext context) {
    final colors = NavigationTheme.colors(context);
    return BoxDecoration(
      color: colors.hoverBackground,
      borderRadius: BorderRadius.circular(itemBorderRadius),
    );
  }
}

/// Navigation color palette
class NavigationColors {
  final Color sidebarBackground;
  final Color mobileNavBackground;
  final Color activeBackground;
  final Color activeText;
  final Color activeIcon;
  final Color activeIndicator;
  final Color inactiveText;
  final Color inactiveIcon;
  final Color hoverBackground;
  final Color hoverText;
  final Color brandText;
  final Color brandAccent;
  final Color divider;
  final Color border;
  final Color shadowPrimary;
  final Color shadowSecondary;

  const NavigationColors({
    required this.sidebarBackground,
    required this.mobileNavBackground,
    required this.activeBackground,
    required this.activeText,
    required this.activeIcon,
    required this.activeIndicator,
    required this.inactiveText,
    required this.inactiveIcon,
    required this.hoverBackground,
    required this.hoverText,
    required this.brandText,
    required this.brandAccent,
    required this.divider,
    required this.border,
    required this.shadowPrimary,
    required this.shadowSecondary,
  });
}
