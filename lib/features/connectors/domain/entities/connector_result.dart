import 'package:equatable/equatable.dart';

/// Represents a standardized result item from a connector search
class ConnectorResult extends Equatable {
  final String id;
  final String connectorId; // e.g. 'google_drive'
  final String title;
  final String? description; // snippet or summary
  final String url; // web link
  final String? downloadUrl; // api link
  final String mimeType;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final String? thumbnail;
  final Map<String, dynamic> metadata;

  const ConnectorResult({
    required this.id,
    required this.connectorId,
    required this.title,
    this.description,
    required this.url,
    this.downloadUrl,
    required this.mimeType,
    this.createdAt,
    this.modifiedAt,
    this.thumbnail,
    this.metadata = const {},
  });

  @override
  List<Object?> get props => [
    id,
    connectorId,
    title,
    description,
    url,
    downloadUrl,
    mimeType,
    createdAt,
    modifiedAt,
    thumbnail,
    metadata,
  ];
}
