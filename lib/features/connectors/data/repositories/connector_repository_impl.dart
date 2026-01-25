import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/connector.dart';
import '../../domain/entities/connector_result.dart';
import '../../domain/repositories/connector_repository.dart';
import '../datasources/connector_registry.dart';

class ConnectorRepositoryImpl implements ConnectorRepository {
  final ConnectorRegistry _registry;

  ConnectorRepositoryImpl(this._registry);

  @override
  Future<Either<Failure, List<Connector>>> getConnectors() async {
    try {
      final integrations = _registry.getAll();
      final connectors = await Future.wait(
        integrations.map((i) => i.toEntity()),
      );
      return Right(connectors);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> connect(String connectorId) async {
    try {
      final integration = _registry.get(connectorId);
      if (integration == null) {
        return Left(ServerFailure('Connector not found'));
      }
      await integration.connect();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> disconnect(String connectorId) async {
    try {
      final integration = _registry.get(connectorId);
      if (integration == null) {
        return Left(ServerFailure('Connector not found'));
      }
      await integration.disconnect();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ConnectorResult>>> search({
    required String query,
    String? connectorId,
    int? limit,
  }) async {
    try {
      final List<ConnectorResult> allResults = [];
      final integrations = connectorId != null
          ? [
              _registry.get(connectorId),
            ].whereType<dynamic>().where((i) => i != null).toList()
          : _registry.getAll();

      // Filter for connected integrations only?
      // For now, let's assume search() inside integration handles auth checks or returns empty.
      // But efficiently, we should check status first.

      for (final integration in integrations) {
        // Optimization: Check status first to avoid unnecessary calls if we know it's disconnected
        final status = await integration.getStatus();
        if (status == ConnectorStatus.connected) {
          try {
            final results = await integration.search(query, limit: limit);
            allResults.addAll(results);
          } catch (e) {
            // Log error but continue with other connectors
            print('Error searching connector ${integration.id}: $e');
          }
        }
      }

      return Right(allResults);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
