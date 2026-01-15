import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/core/usecases/usecase.dart';
import 'package:searvo/features/settings/domain/entities/settings.dart';
import 'package:searvo/features/settings/domain/repositories/settings_repository.dart';

/// Use case to save settings
class SaveSettings extends UseCase<Unit, SaveSettingsParams> {
  final SettingsRepository repository;

  SaveSettings(this.repository);

  @override
  Future<Either<Failure, Unit>> call(SaveSettingsParams params) async {
    return await repository.saveSettings(params.settings);
  }
}

class SaveSettingsParams extends UseCaseParams {
  final Settings settings;

  const SaveSettingsParams({required this.settings});

  @override
  List<Object?> get props => [settings];
}
