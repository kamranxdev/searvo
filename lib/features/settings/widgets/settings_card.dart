import 'package:flutter/material.dart';
import 'package:searvo/core/theme/theme.dart';

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
    Key? key,
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final effectiveIconColor = iconColor ?? colorScheme.primary;
    
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
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
                  child: Icon(
                    icon,
                    color: effectiveIconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Title and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
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
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
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
    Key? key,
    required this.title,
    this.subtitle,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    
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
                    color: colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
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
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.iconColor,
    this.enabled = true,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final effectiveIconColor = iconColor ?? colorScheme.primary;
    
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
          activeColor: colorScheme.primary,
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
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onPressed,
    this.buttonColor,
    this.isDestructive = false,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final effectiveColor = buttonColor ?? 
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
