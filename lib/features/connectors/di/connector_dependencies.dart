import 'package:get_it/get_it.dart';
import 'package:searvo/features/connectors/data/datasources/connector_registry.dart';
import 'package:searvo/features/connectors/data/repositories/connector_repository_impl.dart';
import 'package:searvo/features/connectors/domain/repositories/connector_repository.dart';
import 'package:searvo/features/connectors/impl/google_drive/google_drive_connector.dart';
import 'package:searvo/features/connectors/impl/one_drive/one_drive_connector.dart';
import 'package:searvo/features/connectors/presentation/bloc/connector_bloc.dart';

final sl = GetIt.instance;

Future<void> initConnectorDependencies() async {
  // Registry
  final registry = ConnectorRegistry();

  // Register Integrations
  registry.register(GoogleDriveConnector());
  registry.register(OneDriveConnector());

  sl.registerSingleton<ConnectorRegistry>(registry);

  // Repository
  sl.registerLazySingleton<ConnectorRepository>(
    () => ConnectorRepositoryImpl(sl()),
  );

  // Bloc
  sl.registerFactory(() => ConnectorBloc(sl()));
}
