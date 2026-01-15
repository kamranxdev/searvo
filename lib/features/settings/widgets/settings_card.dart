import 'package:flutter/material.dart';
import 'package:searvo/core/theme/theme.dart';
import 'package:searvo/features/settings/theme/settings_theme.dart';

class SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool showChevron;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const SettingsCard({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.showChevron = true,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final settingsColors = SettingsTheme.colors(context);
    final effectiveIconColor = iconColor ?? settingsColors.accent;

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? settingsColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: settingsColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: effectiveIconColor, size: 24),
                ),
                const SizedBox(width: 16),

                // Title and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: SettingsTheme.settingTitle(context)),
                      if (description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          description!,
                          style: SettingsTheme.settingDescription(context),
                        ),
                      ],
                    ],
                  ),
                ),

                // Trailing widget or chevron
                if (trailing != null)
                  trailing!
                else if (showChevron && onTap != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: settingsColors.icon,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modern section header for settings groups
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final EdgeInsetsGeometry? margin;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final settingsColors = SettingsTheme.colors(context);

    return Container(
      margin: margin ?? const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: settingsColors.header,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: settingsColors.subtitle,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern toggle card with improved design
class ToggleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? iconColor;
  final bool enabled;
  final EdgeInsetsGeometry? margin;

  const ToggleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.iconColor,
    this.enabled = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final settingsColors = SettingsTheme.colors(context);
    final effectiveIconColor = iconColor ?? settingsColors.accent;

    return SettingsCard(
      icon: icon,
      title: title,
      description: description,
      iconColor: effectiveIconColor,
      showChevron: false,
      margin: margin,
      onTap: enabled ? () => onChanged(!value) : null,
      trailing: Transform.scale(
        scale: 0.9,
        child: Switch.adaptive(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeColor: settingsColors.accent,
        ),
      ),
    );
  }
}

/// Modern action button card
class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onPressed;
  final Color? buttonColor;
  final bool isDestructive;
  final EdgeInsetsGeometry? margin;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onPressed,
    this.buttonColor,
    this.isDestructive = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final effectiveColor =
        buttonColor ??
        (isDestructive ? colorScheme.error : colorScheme.primary);

    return SettingsCard(
      icon: icon,
      title: title,
      description: description,
      iconColor: effectiveColor,
      showChevron: false,
      margin: margin,
      onTap: null,
      trailing: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: effectiveColor,
          foregroundColor: isDestructive
              ? colorScheme.onError
              : colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          buttonText,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
