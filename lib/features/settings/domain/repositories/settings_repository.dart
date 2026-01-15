import 'package:dartz/dartz.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/features/settings/domain/entities/settings.dart';

/// Abstract repository interface for settings
/// Implementation is in the data layer
abstract class SettingsRepository {
  /// Get current settings
  Future<Either<Failure, Settings>> getSettings();

  /// Update theme
  Future<Either<Failure, Unit>> setTheme(String theme);

  /// Update notifications setting
  Future<Either<Failure, Unit>> setNotifications(bool enabled);

  /// Update auto-save setting
  Future<Either<Failure, Unit>> setAutoSave(bool enabled);

  /// Update language
  Future<Either<Failure, Unit>> setLanguage(String language);

  /// Update SearXNG endpoint
  Future<Either<Failure, Unit>> setSearxngEndpoint(String endpoint);

  /// Update search timeout
  Future<Either<Failure, Unit>> setSearchTimeout(int timeout);

  /// Save all settings
  Future<Either<Failure, Unit>> saveSettings(Settings settings);
}
