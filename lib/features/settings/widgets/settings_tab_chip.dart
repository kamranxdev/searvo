import 'package:flutter/material.dart';

class SettingsTabChip extends StatelessWidget {
  final String id;
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const SettingsTabChip({
    Key? key,
    required this.id,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}