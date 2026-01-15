import 'package:dartz/dartz.dart';
import 'package:searvo/core/error/exceptions.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:searvo/features/settings/data/models/settings_model.dart';
import 'package:searvo/features/settings/domain/entities/settings.dart';
import 'package:searvo/features/settings/domain/repositories/settings_repository.dart';

/// Implementation of SettingsRepository
/// Handles error mapping from data layer exceptions to domain failures
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, Settings>> getSettings() async {
    try {
      final settingsModel = await localDataSource.getSettings();
      return Right(settingsModel.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> setTheme(String theme) async {
    try {
      await localDataSource.setTheme(theme);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> setNotifications(bool enabled) async {
    try {
      await localDataSource.setNotifications(enabled);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> setAutoSave(bool enabled) async {
    try {
      await localDataSource.setAutoSave(enabled);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> setLanguage(String language) async {
    try {
      await localDataSource.setLanguage(language);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> setSearxngEndpoint(String endpoint) async {
    try {
      await localDataSource.setSearxngEndpoint(endpoint);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> setSearchTimeout(int timeout) async {
    try {
      await localDataSource.setSearchTimeout(timeout);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveSettings(Settings settings) async {
    try {
      final settingsModel = SettingsModel.fromEntity(settings);
      await localDataSource.saveSettings(settingsModel);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
