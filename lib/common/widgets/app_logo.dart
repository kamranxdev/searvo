import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/theme.dart';

/// Color Mapper for App Logo SVG
/// Transforms black colors based on theme brightness
/// - Light theme (white background): Uses black logo
/// - Dark theme: Uses white logo
class LogoColorMapper extends ColorMapper {
  final BuildContext context;

  const LogoColorMapper(this.context);

  @override
  Color substitute(String? id, String elementName, String attributeName, Color color) {
    if (color == const Color(0xFF000000)) {
      final brightness = Theme.of(context).brightness;
      return brightness == Brightness.light ? Colors.black : Colors.white;
    }
    return color;
  }
}

/// Reusable App Logo Widget
/// Displays the app's SVG logo with automatic color mapping to match the theme
/// 
/// Example usage:
/// ```dart
/// AppLogo(size: 40)
/// AppLogo.small()
/// AppLogo.medium()
/// AppLogo.large()
/// ```
class AppLogo extends StatelessWidget {
  /// Size of the logo (width and height)
  final double size;

  /// Custom color mapper (optional, defaults to LogoColorMapper)
  final ColorMapper? colorMapper;

  /// Whether to show the logo in a circular container with background
  final bool withBackground;

  /// Background opacity when withBackground is true
  final double backgroundOpacity;

  const AppLogo({
    super.key,
    required this.size,
    this.colorMapper,
    this.withBackground = false,
    this.backgroundOpacity = 0.15,
  });

  /// Small logo (32x32)
  const AppLogo.small({
    super.key,
    this.colorMapper,
    this.withBackground = false,
    this.backgroundOpacity = 0.15,
  }) : size = 32;

  /// Medium logo (48x48)
  const AppLogo.medium({
    super.key,
    this.colorMapper,
    this.withBackground = false,
    this.backgroundOpacity = 0.15,
  }) : size = 48;

  /// Large logo (64x64)
  const AppLogo.large({
    super.key,
    this.colorMapper,
    this.withBackground = false,
    this.backgroundOpacity = 0.15,
  }) : size = 64;

  /// Extra large logo (80x80)
  const AppLogo.extraLarge({
    super.key,
    this.colorMapper,
    this.withBackground = false,
    this.backgroundOpacity = 0.15,
  }) : size = 80;

  @override
  Widget build(BuildContext context) {
    final logo = SvgPicture.asset(
      'assets/logo.svg',
      colorMapper: colorMapper ?? LogoColorMapper(context),
      width: size,
      height: size,
    );

    if (!withBackground) {
      return logo;
    }

    final theme = Theme.of(context);
    return Container(
      width: size * 1.6, // Container is 1.6x the logo size
      height: size * 1.6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.primaryColor.withOpacity(backgroundOpacity),
      ),
      child: Center(child: logo),
    );
  }
}

/// App Logo with Brand Name
/// Displays the logo alongside the app name with optional expansion animation
/// 
/// Example usage:
/// ```dart
/// AppLogoWithName()
/// AppLogoWithName(showName: false)
/// AppLogoWithName(logoSize: 32, fontSize: 18)
/// ```
class AppLogoWithName extends StatelessWidget {
  /// Size of the logo
  final double logoSize;

  /// Size of the brand name text
  final double fontSize;

  /// Whether to show the brand name
  final bool showName;

  /// Brand name text
  final String brandName;

  /// Spacing between logo and name
  final double spacing;

  /// Custom color mapper for logo
  final ColorMapper? colorMapper;

  /// Whether to show logo with background
  final bool withBackground;

  const AppLogoWithName({
    super.key,
    this.logoSize = 40,
    this.fontSize = 18,
    this.showName = true,
    this.brandName = 'Searvo',
    this.spacing = 12,
    this.colorMapper,
    this.withBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(
          size: logoSize,
          colorMapper: colorMapper,
          withBackground: withBackground,
        ),
        if (showName) ...[
          SizedBox(width: spacing),
          Text(
            brandName,
            style: TextStyle(
              color: context.colorScheme.onSurface,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              fontFamily: 'Goldman',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

/// Animated App Logo with Brand Name
/// Provides smooth animation for showing/hiding the brand name
/// Perfect for collapsible sidebars or navigation
/// 
/// Example usage:
/// ```dart
/// AnimatedAppLogoWithName(showName: isExpanded)
/// ```
class AnimatedAppLogoWithName extends StatelessWidget {
  /// Size of the logo
  final double logoSize;

  /// Size of the brand name text
  final double fontSize;

  /// Whether to show the brand name (animated)
  final bool showName;

  /// Brand name text
  final String brandName;

  /// Spacing between logo and name
  final double spacing;

  /// Animation duration
  final Duration duration;

  /// Custom color mapper for logo
  final ColorMapper? colorMapper;

  /// Whether to show logo with background
  final bool withBackground;

  const AnimatedAppLogoWithName({
    super.key,
    this.logoSize = 40,
    this.fontSize = 18,
    required this.showName,
    this.brandName = 'Searvo',
    this.spacing = 12,
    this.duration = const Duration(milliseconds: 250),
    this.colorMapper,
    this.withBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(
          size: logoSize,
          colorMapper: colorMapper,
          withBackground: withBackground,
        ),
        if (showName) SizedBox(width: spacing),
        AnimatedOpacity(
          opacity: showName ? 1.0 : 0.0,
          duration: duration,
          child: AnimatedContainer(
            duration: duration,
            width: showName ? null : 0,
            child: showName
                ? Text(
                    brandName,
                    style: TextStyle(
                      color: context.colorScheme.onSurface,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Goldman',
                      letterSpacing: 0.5,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
