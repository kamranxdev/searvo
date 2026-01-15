import 'package:equatable/equatable.dart';

/// Domain entity for app settings
/// This is pure Dart with no Flutter dependencies
class Settings extends Equatable {
  final String theme;
  final bool notificationsEnabled;
  final bool autoSaveEnabled;
  final String language;
  final String searxngEndpoint;
  final int searchTimeout;

  const Settings({
    required this.theme,
    required this.notificationsEnabled,
    required this.autoSaveEnabled,
    required this.language,
    required this.searxngEndpoint,
    required this.searchTimeout,
  });

  bool get isDarkMode => theme == 'dark';

  Settings copyWith({
    String? theme,
    bool? notificationsEnabled,
    bool? autoSaveEnabled,
    String? language,
    String? searxngEndpoint,
    int? searchTimeout,
  }) {
    return Settings(
      theme: theme ?? this.theme,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
      language: language ?? this.language,
      searxngEndpoint: searxngEndpoint ?? this.searxngEndpoint,
      searchTimeout: searchTimeout ?? this.searchTimeout,
    );
  }

  @override
  List<Object?> get props => [
        theme,
        notificationsEnabled,
        autoSaveEnabled,
        language,
        searxngEndpoint,
        searchTimeout,
      ];

  /// Default settings
  factory Settings.defaultSettings() {
    return const Settings(
      theme: 'dark',
      notificationsEnabled: true,
      autoSaveEnabled: false,
      language: 'en',
      searxngEndpoint: 'http://localhost:4000',
      searchTimeout: 30,
    );
  }
}
