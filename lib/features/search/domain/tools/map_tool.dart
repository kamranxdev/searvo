import 'package:searvo/features/search/domain/entities/agent/agent_tool.dart';

class MapTool extends AgentTool {
  MapTool()
    : super(
        id: 'map',
        name: 'Map & Navigation',
        description:
            "REQUIRED for requests involving 'directions', 'route', 'distance to', 'navigate', or 'map of'. Use this to show a visual map and route details.",
      );

  @override
  Future<bool> get isAvailable async => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'to': {'type': 'string', 'description': 'Destination location/address.'},
      'from': {
        'type': 'string',
        'description': 'Starting location/address (optional).',
      },
      'mode': {
        'type': 'string',
        'enum': ['driving', 'walking', 'transit', 'cycling'],
        'description': 'Mode of transport.',
      },
    },
    'required': ['to'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final to = input['to'] as String;
    final from = input['from'] as String? ?? 'Current Location';
    final mode = input['mode'] as String? ?? 'driving';

    // Mocking route calculation for Generative UI demo
    // In a real app, this would call OSRM, Google Routes, or Mapbox Directions API

    // Generate deterministic-ish mock data based on string length to seem dynamic
    final distanceVal = (to.length * 0.8 + 1.5).toStringAsFixed(1);
    final durationVal = (to.length * 1.5 + 10).round();

    return {
      'destination': to,
      'origin': from,
      'mode': mode,
      'route': {
        'duration': '$durationVal min',
        'distance': '$distanceVal km',
        'summary': 'Fastest route via Main St',
        'traffic': 'Light traffic',
      },
      // Using a static map generator placeholder (e.g. Mapbox style or similar)
      // Here we use a generic placeholder that looks like a map
      'static_map_url':
          'https://maps.googleapis.com/maps/api/staticmap?center=$to&zoom=13&size=600x300&maptype=roadmap&markers=color:red%7C$to&key=YOUR_API_KEY_HERE', // In real app, hide key or use open source alternative
      // For demo purposes, we can use a reliable open placeholder if needed,
      // but let's stick to a structure the UI can handle.
      // If we don't have a real key, the UI might need to handle the broken image or use a different provider.
      // Let's use a blurred generic map style image for the "Generative UI" feel if real map fails.
      'preview_image':
          'https://api.mapbox.com/styles/v1/mapbox/dark-v10/static/0,0,1,0/400x300?access_token=mock',
    };
  }
}
