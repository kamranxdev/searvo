/// Core theme system exports
/// 
/// This file provides a single import point for all theme-related functionality.
/// 
/// Usage:
/// ```dart
/// import 'package:searvo/core/theme/theme.dart';
/// 
/// // Access theme config
/// AppThemeConfig.primaryColor
/// 
/// // Use theme manager
/// ThemeManager().setDarkMode()
/// 
/// // Use extensions
/// context.isDark
/// context.textTheme
/// ```

library;

export 'app_theme_config.dart';
export 'theme_extensions.dart';
export 'theme_manager.dart';
