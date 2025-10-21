import 'package:flutter/material.dart';
import 'package:searvo/core/theme/theme.dart';

class ToggleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final Color? inactiveThumbColor;
  final Color? activeTrackColor;
  final Color? inactiveTrackColor;
  final Color? cardColor;
  final Color? iconColor;
  final Color? titleColor;
  final Color? descriptionColor;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final bool enabled;

  const ToggleCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveThumbColor,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.cardColor,
    this.iconColor,
    this.titleColor,
    this.descriptionColor,
    this.elevation = 0,
    this.padding,
    this.margin,
    this.borderRadius,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    
    return Card(
      elevation: elevation,
      color: cardColor ?? colorScheme.surfaceContainerHighest.withOpacity(0.5),
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (iconColor ?? colorScheme.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              
              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: descriptionColor ?? colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Toggle Switch
              Switch(
                value: value,
                onChanged: enabled ? onChanged : null,
                activeColor: activeColor ?? colorScheme.primary,
                inactiveThumbColor: inactiveThumbColor,
                activeTrackColor: activeTrackColor,
                inactiveTrackColor: inactiveTrackColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}