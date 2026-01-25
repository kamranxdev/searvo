import 'package:equatable/equatable.dart';

enum ConnectorStatus { connected, disconnected, error, connecting }

class Connector extends Equatable {
  final String id;
  final String name;
  final String description;
  final String iconPath; // Asset path or IconData identifier
  final ConnectorStatus status;
  final String? errorMessage;
  final DateTime? lastSyncedAt;

  const Connector({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    this.status = ConnectorStatus.disconnected,
    this.errorMessage,
    this.lastSyncedAt,
  });

  Connector copyWith({
    String? id,
    String? name,
    String? description,
    String? iconPath,
    ConnectorStatus? status,
    String? errorMessage,
    DateTime? lastSyncedAt,
  }) {
    return Connector(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    iconPath,
    status,
    errorMessage,
    lastSyncedAt,
  ];
}
