import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/connector.dart';
import '../../domain/repositories/connector_repository.dart';

// Events
abstract class ConnectorEvent extends Equatable {
  const ConnectorEvent();
  @override
  List<Object> get props => [];
}

class LoadConnectors extends ConnectorEvent {}

class ToggleConnector extends ConnectorEvent {
  final String connectorId;
  final bool connect; // true to connect, false to disconnect

  const ToggleConnector({required this.connectorId, required this.connect});

  @override
  List<Object> get props => [connectorId, connect];
}

// States
abstract class ConnectorState extends Equatable {
  const ConnectorState();
  @override
  List<Object> get props => [];
}

class ConnectorInitial extends ConnectorState {}

class ConnectorLoading extends ConnectorState {}

class ConnectorLoaded extends ConnectorState {
  final List<Connector> connectors;

  const ConnectorLoaded(this.connectors);

  @override
  List<Object> get props => [connectors];
}

class ConnectorError extends ConnectorState {
  final String message;

  const ConnectorError(this.message);

  @override
  List<Object> get props => [message];
}

class ConnectorBloc extends Bloc<ConnectorEvent, ConnectorState> {
  final ConnectorRepository _repository;

  ConnectorBloc(this._repository) : super(ConnectorInitial()) {
    on<LoadConnectors>(_onLoadConnectors);
    on<ToggleConnector>(_onToggleConnector);
  }

  Future<void> _onLoadConnectors(
    LoadConnectors event,
    Emitter<ConnectorState> emit,
  ) async {
    emit(ConnectorLoading());
    final result = await _repository.getConnectors();
    result.fold(
      (failure) => emit(ConnectorError(failure.message)),
      (connectors) => emit(ConnectorLoaded(connectors)),
    );
  }

  Future<void> _onToggleConnector(
    ToggleConnector event,
    Emitter<ConnectorState> emit,
  ) async {
    // Optimistic update could be done here, but let's stick to safe async flow
    // We emit loading or keep current state?
    // Ideally we want to show loading indicator on the specific card without reloading everything.
    // For simplicity, we reload everything after action.

    // emit(ConnectorLoading()); // Optional: might be too aggressive

    final result = event.connect
        ? await _repository.connect(event.connectorId)
        : await _repository.disconnect(event.connectorId);

    result.fold(
      (failure) => emit(ConnectorError(failure.message)),
      (_) => add(LoadConnectors()), // Reload list to get updated status
    );
  }
}
