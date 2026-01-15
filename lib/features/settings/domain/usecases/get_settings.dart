import 'package:dartz/dartz.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/core/usecases/usecase.dart';
import 'package:searvo/features/settings/domain/entities/settings.dart';
import 'package:searvo/features/settings/domain/repositories/settings_repository.dart';

/// Use case to get current settings
class GetSettings extends NoParamsUseCase<Settings> {
  final SettingsRepository repository;

  GetSettings(this.repository);

  @override
  Future<Either<Failure, Settings>> call() async {
    return await repository.getSettings();
  }
}
