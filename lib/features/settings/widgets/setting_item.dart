import 'package:flutter/material.dart';

class SettingItem extends StatelessWidget {
  final bool isDark;
  final String label;
  final String? description;
  final Widget child;

  const SettingItem({
    Key? key,
    required this.isDark,
    required this.label,
    this.description,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white.withOpacity(0.8) : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        child,
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white.withOpacity(0.5) : Colors.black54,
            ),
          ),
        ],
      ],
    );
  }
}