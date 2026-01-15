import 'package:searvo/features/settings/domain/entities/settings.dart';

/// Data Transfer Object for Settings
/// Extends the domain entity and adds serialization capabilities
class SettingsModel extends Settings {
  const SettingsModel({
    required super.theme,
    required super.notificationsEnabled,
    required super.autoSaveEnabled,
    required super.language,
    required super.searxngEndpoint,
    required super.searchTimeout,
  });

  /// Convert domain entity to model
  factory SettingsModel.fromEntity(Settings settings) {
    return SettingsModel(
      theme: settings.theme,
      notificationsEnabled: settings.notificationsEnabled,
      autoSaveEnabled: settings.autoSaveEnabled,
      language: settings.language,
      searxngEndpoint: settings.searxngEndpoint,
      searchTimeout: settings.searchTimeout,
    );
  }

  /// Convert model to domain entity
  Settings toEntity() {
    return Settings(
      theme: theme,
      notificationsEnabled: notificationsEnabled,
      autoSaveEnabled: autoSaveEnabled,
      language: language,
      searxngEndpoint: searxngEndpoint,
      searchTimeout: searchTimeout,
    );
  }

  /// Create from JSON
  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      theme: json['theme'] as String,
      notificationsEnabled: json['notificationsEnabled'] as bool,
      autoSaveEnabled: json['autoSaveEnabled'] as bool,
      language: json['language'] as String,
      searxngEndpoint: json['searxngEndpoint'] as String,
      searchTimeout: json['searchTimeout'] as int,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'notificationsEnabled': notificationsEnabled,
      'autoSaveEnabled': autoSaveEnabled,
      'language': language,
      'searxngEndpoint': searxngEndpoint,
      'searchTimeout': searchTimeout,
    };
  }

  @override
  SettingsModel copyWith({
    String? theme,
    bool? notificationsEnabled,
    bool? autoSaveEnabled,
    String? language,
    String? searxngEndpoint,
    int? searchTimeout,
  }) {
    return SettingsModel(
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
      language: language ?? this.language,
      searxngEndpoint: searxngEndpoint ?? this.searxngEndpoint,
      searchTimeout: searchTimeout ?? this.searchTimeout,
    );
  }
}
