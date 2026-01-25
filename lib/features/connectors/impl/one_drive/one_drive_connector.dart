import 'package:searvo/features/connectors/data/datasources/connector_integration.dart';
import 'package:searvo/features/connectors/domain/entities/connector.dart';
import 'package:searvo/features/connectors/domain/entities/connector_result.dart';

class OneDriveConnector extends ConnectorIntegration {
  @override
  String get id => 'one_drive';

  @override
  String get name => 'OneDrive';

  @override
  String get description => 'Search your Microsoft OneDrive files';

  @override
  // Placeholder icon path
  String get iconPath => 'assets/icons/one_drive.svg';

  @override
  bool get isSearchSupported => true;

  @override
  Future<void> connect() async {
    // TODO: Implement Microsoft Graph Auth
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> disconnect() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<ConnectorStatus> getStatus() async {
    // Stub: always disconnected for now
    return ConnectorStatus.disconnected;
  }

  @override
  Future<List<ConnectorResult>> search(String query, {int? limit}) async {
    return [];
  }
}
