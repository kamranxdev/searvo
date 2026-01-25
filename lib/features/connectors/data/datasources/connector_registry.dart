import 'connector_integration.dart';

class ConnectorRegistry {
  final Map<String, ConnectorIntegration> _integrations = {};

  void register(ConnectorIntegration integration) {
    _integrations[integration.id] = integration;
  }

  ConnectorIntegration? get(String id) => _integrations[id];

  List<ConnectorIntegration> getAll() => _integrations.values.toList();

  List<ConnectorIntegration> getConnected() {
    // This is synchronous and might not reflect async status checks.
    // Ideally, consumers should check status async.
    // For the registry, we just return all registered instances.
    return _integrations.values.toList();
  }
}
