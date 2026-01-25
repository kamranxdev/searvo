import '../../domain/entities/connector.dart';
import '../../domain/entities/connector_result.dart';

/// Interface that must be implemented by specific providers (Google Drive, OneDrive, etc.)
abstract class ConnectorIntegration {
  String get id;
  String get name;
  String get description;
  String get iconPath;

  /// Whether this connector allows searching files
  bool get isSearchSupported => true;

  /// Check current connection status (e.g. check for valid token)
  Future<ConnectorStatus> getStatus();

  /// Perform authentication/login
  Future<void> connect();

  /// Perform logout/disconnect
  Future<void> disconnect();

  /// Execute a search
  Future<List<ConnectorResult>> search(String query, {int? limit});

  /// Convert to Entity for UI
  Future<Connector> toEntity() async {
    return Connector(
      id: id,
      name: name,
      description: description,
      iconPath: iconPath,
      status: await getStatus(),
    );
  }
}
