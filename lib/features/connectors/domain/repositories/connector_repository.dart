import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/connector.dart';
import '../entities/connector_result.dart';

abstract class ConnectorRepository {
  /// Get all available connectors with their current status
  Future<Either<Failure, List<Connector>>> getConnectors();

  /// Initiate connection flow for a specific connector
  Future<Either<Failure, void>> connect(String connectorId);

  /// Disconnect a specific connector
  Future<Either<Failure, void>> disconnect(String connectorId);

  /// Perform a search across all connected connectors or a specific one
  Future<Either<Failure, List<ConnectorResult>>> search({
    required String query,
    String? connectorId,
    int? limit,
  });
}
