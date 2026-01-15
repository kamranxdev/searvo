import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/features/settings/domain/entities/settings.dart';

part 'settings_state.freezed.dart';

/// Settings state with Freezed union types
@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState.initial() = _Initial;
  const factory SettingsState.loading() = _Loading;
  const factory SettingsState.loaded(Settings settings) = _Loaded;
  const factory SettingsState.error(Failure failure) = _Error;
}
