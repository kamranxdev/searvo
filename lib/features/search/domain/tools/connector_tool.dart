import 'package:searvo/features/search/domain/entities/agent/agent_tool.dart';
import 'package:searvo/features/connectors/data/datasources/connector_registry.dart';
import 'package:searvo/features/connectors/domain/entities/connector.dart';

class ConnectorTool extends AgentTool {
  final ConnectorRegistry _registry;

  ConnectorTool(this._registry)
    : super(
        id: 'cloud_search',
        name: 'Cloud Storage Search',
        description:
            'Search for files in connected cloud storage accounts (Google Drive, OneDrive, etc.). Use this when the user asks about their own files, documents, or personal data.',
      );

  @override
  Future<bool> get isAvailable async {
    // Check if any connector is connected
    final integrations = _registry.getAll();
    for (final i in integrations) {
      if (await i.getStatus() == ConnectorStatus.connected) {
        return true;
      }
    }
    return false;
  }

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'query': {
        'type': 'string',
        'description': 'The query to search for in files',
      },
    },
    'required': ['query'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final query = input['query'] as String;
    final results = <Map<String, dynamic>>[];

    final integrations = _registry.getAll();
    for (final i in integrations) {
      if (await i.getStatus() == ConnectorStatus.connected) {
        try {
          final connectorResults = await i.search(query);
          results.addAll(
            connectorResults.map(
              (r) => {
                'title': r.title,
                'url': r.url,
                'snippet': r.description ?? '',
                'source': i.name, // e.g. "Google Drive"
                'mimeType': r.mimeType,
                'thumbnail': r.thumbnail,
              },
            ),
          );
        } catch (e) {
          // Ignore errors from individual connectors, or return partial results
          print('Error searching ${i.name}: $e');
        }
      }
    }

    return {'success': true, 'documents': results};
  }
}
