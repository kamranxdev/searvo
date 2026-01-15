import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/core/usecases/usecase.dart';
import 'package:searvo/features/settings/domain/repositories/settings_repository.dart';

/// Use case to update theme setting
class UpdateTheme extends UseCase<Unit, UpdateThemeParams> {
  final SettingsRepository repository;

  UpdateTheme(this.repository);

  @override
  Future<Either<Failure, Unit>> call(UpdateThemeParams params) async {
    return await repository.setTheme(params.theme);
  }
}

class UpdateThemeParams extends UseCaseParams {
  final String theme;

  const UpdateThemeParams({required this.theme});

  @override
  List<Object?> get props => [theme];
}
