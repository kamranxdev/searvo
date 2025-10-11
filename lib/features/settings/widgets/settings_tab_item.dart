import 'package:flutter/material.dart';
import 'package:searvo/core/theme/theme.dart';

class SettingsTabItem extends StatelessWidget {
  final String id;
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const SettingsTabItem({
    Key? key,
    required this.id,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isActive
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}