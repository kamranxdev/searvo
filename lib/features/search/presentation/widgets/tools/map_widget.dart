import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:searvo/features/search/theme/search_theme.dart';

class MapWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const MapWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final searchColors = SearchTheme.colors(context);
    final route = data['route'] as Map<String, dynamic>? ?? {};
    final to = data['destination'] ?? 'Destination';
    final mapUrl = data['static_map_url'] as String? ?? '';
    final previewImage = data['preview_image'] as String? ?? '';
    // Use preview image if map url fails or is placeholder
    final displayImage = mapUrl.contains('YOUR_API_KEY')
        ? previewImage
        : mapUrl;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: searchColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: searchColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons
                      .directions_car_filled_rounded, // Default to car, could be dynamic
                  color: searchColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Directions to $to',
                    style: GoogleFonts.outfit(
                      color: searchColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Map Preview
          if (displayImage.isNotEmpty)
            GestureDetector(
              onTap: () => _launchMaps(to),
              child: Container(
                height: 180,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: searchColors.surfaceContainerHighest,
                  image: DecorationImage(
                    image: NetworkImage(displayImage),
                    fit: BoxFit.cover,
                    // Darken image slightly for text readability if we overlay
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.2),
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: Center(
                  // Play/Open icon overlay
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.map_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

          // Route Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route['duration'] ?? '-- min',
                      style: GoogleFonts.outfit(
                        color: searchColors.text,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      route['distance'] ?? '-- km',
                      style: GoogleFonts.outfit(
                        color: searchColors.subtitle,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _launchMaps(to),
                  icon: const Icon(Icons.navigation_rounded, size: 18),
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: searchColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (route['summary'] != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                route['summary'],
                style: GoogleFonts.outfit(
                  color: searchColors.subtitle,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _launchMaps(String destination) async {
    // Try generic geo intent first, fallback to Google Maps web
    final Uri geoUri = Uri.parse(
      'geo:0,0?q=${Uri.encodeComponent(destination)}',
    );
    final Uri webUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(destination)}',
    );

    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }
}
