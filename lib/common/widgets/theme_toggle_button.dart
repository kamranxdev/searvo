import 'package:flutter/material.dart';
import 'package:searvo/core/theme/theme_extensions.dart';

/// A floating theme toggle button widget for easy theme switching
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      mini: true,
      backgroundColor: context.colorScheme.surface,
      foregroundColor: context.colorScheme.onSurface,
      onPressed: () => context.toggleTheme(),
      tooltip: 'Toggle Theme',
      child: Icon(
        context.isDark ? Icons.light_mode : Icons.dark_mode,
        size: 20,
      ),
    );
  }
}

/// A theme selection dropdown widget
class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final currentTheme = themeManager.currentThemeModeLabel.toLowerCase();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.palette,
            color: context.colorScheme.onSurfaceVariant,
            size: 16,
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: currentTheme,
            dropdownColor: context.colorScheme.surfaceContainerHighest,
            style: TextStyle(
              color: context.colorScheme.onSurface, 
              fontSize: 14,
            ),
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'light', child: Text('Light')),
              DropdownMenuItem(value: 'dark', child: Text('Dark')),
              DropdownMenuItem(value: 'system', child: Text('System')),
            ],
            onChanged: (value) async {
              if (value != null) {
                switch (value) {
                  case 'light':
                    await context.setLightTheme();
                    break;
                  case 'dark':
                    await context.setDarkTheme();
                    break;
                  case 'system':
                    await context.setSystemTheme();
                    break;
                }
              }
            },
          ),
        ],
      ),
    );
  }
}