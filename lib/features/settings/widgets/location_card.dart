import 'package:flutter/material.dart';
import 'package:searvo/core/theme/theme.dart';

class LocationCard extends StatelessWidget {
  final bool locationEnabled;
  final Function(bool) onChanged;
  final String userLocation;

  const LocationCard({
    Key? key,
    required this.locationEnabled,
    required this.onChanged,
    required this.userLocation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_on,
                  size: 18,
                  color: context.isDark
                      ? Colors.white.withOpacity(0.7)
                      : Colors.black.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location Access',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.isDark
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Enter a location or enable precise location to get more accurate weather and sports',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.isDark
                            ? Colors.white.withOpacity(0.6)
                            : Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: locationEnabled,
                onChanged: onChanged,
                activeColor: const Color(0xFF24A0ED),
              ),
            ],
          ),
          if (locationEnabled) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You are sharing your location via your device',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.isDark
                          ? Colors.white.withOpacity(0.6)
                          : Colors.black.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    'Device location: ${userLocation.isNotEmpty ? userLocation : 'Detecting...'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.isDark
                          ? Colors.white.withOpacity(0.6)
                          : Colors.black.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}