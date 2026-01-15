import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:searvo/core/usecases/usecase.dart';
import 'package:searvo/features/settings/domain/entities/settings.dart';
import 'package:searvo/features/settings/domain/usecases/get_settings.dart';
import 'package:searvo/features/settings/domain/usecases/save_settings.dart';
import 'package:searvo/features/settings/domain/usecases/update_theme.dart';
import 'package:searvo/features/settings/presentation/cubit/settings_state.dart';

/// Cubit for managing settings state
/// Uses use cases from domain layer
class SettingsCubit extends Cubit<SettingsState> {
  final GetSettings getSettings;
  final UpdateTheme updateTheme;
  final SaveSettings saveSettings;

  SettingsCubit({
    required this.getSettings,
    required this.updateTheme,
    required this.saveSettings,
  }) : super(const SettingsState.initial());

  /// Load settings from repository
  Future<void> loadSettings() async {
    emit(const SettingsState.loading());
    final result = await getSettings();
    result.fold(
      (failure) => emit(SettingsState.error(failure)),
      (settings) => emit(SettingsState.loaded(settings)),
    );
  }

  /// Update theme setting
  Future<void> changeTheme(String theme) async {
    await state.maybeWhen(
      loaded: (settings) async {
        emit(const SettingsState.loading());
        final result = await updateTheme(UpdateThemeParams(theme: theme));
        result.fold(
          (failure) => emit(SettingsState.error(failure)),
          (_) {
            final updatedSettings = settings.copyWith(theme: theme);
            emit(SettingsState.loaded(updatedSettings));
          },
        );
      },
      orElse: () async {},
    );
  }

  /// Update notifications setting
  Future<void> changeNotifications(bool enabled) async {
    await state.maybeWhen(
      loaded: (settings) async {
        final updatedSettings = settings.copyWith(
          notificationsEnabled: enabled,
        );
        emit(const SettingsState.loading());
        final result = await saveSettings(
          SaveSettingsParams(settings: updatedSettings),
        );
        result.fold(
          (failure) => emit(SettingsState.error(failure)),
          (_) => emit(SettingsState.loaded(updatedSettings)),
        );
      },
      orElse: () async {},
    );
  }

  /// Update auto-save setting
  Future<void> changeAutoSave(bool enabled) async {
    await state.maybeWhen(
      loaded: (settings) async {
        final updatedSettings = settings.copyWith(
          autoSaveEnabled: enabled,
        );
        emit(const SettingsState.loading());
        final result = await saveSettings(
          SaveSettingsParams(settings: updatedSettings),
        );
        result.fold(
          (failure) => emit(SettingsState.error(failure)),
          (_) => emit(SettingsState.loaded(updatedSettings)),
        );
      },
      orElse: () async {},
    );
  }

  /// Update language setting
  Future<void> changeLanguage(String language) async {
    await state.maybeWhen(
      loaded: (settings) async {
        final updatedSettings = settings.copyWith(
          language: language,
        );
        emit(const SettingsState.loading());
        final result = await saveSettings(
          SaveSettingsParams(settings: updatedSettings),
        );
        result.fold(
          (failure) => emit(SettingsState.error(failure)),
          (_) => emit(SettingsState.loaded(updatedSettings)),
        );
      },
      orElse: () async {},
    );
  }

  /// Update SearXNG endpoint setting
  Future<void> changeSearxngEndpoint(String endpoint) async {
    await state.maybeWhen(
      loaded: (settings) async {
        final updatedSettings = settings.copyWith(
          searxngEndpoint: endpoint,
        );
        emit(const SettingsState.loading());
        final result = await saveSettings(
          SaveSettingsParams(settings: updatedSettings),
        );
        result.fold(
          (failure) => emit(SettingsState.error(failure)),
          (_) => emit(SettingsState.loaded(updatedSettings)),
        );
      },
      orElse: () async {},
    );
  }

  /// Update search timeout setting
  Future<void> changeSearchTimeout(int timeout) async {
    await state.maybeWhen(
      loaded: (settings) async {
        final updatedSettings = settings.copyWith(
          searchTimeout: timeout,
        );
        emit(const SettingsState.loading());
        final result = await saveSettings(
          SaveSettingsParams(settings: updatedSettings),
        );
        result.fold(
          (failure) => emit(SettingsState.error(failure)),
          (_) => emit(SettingsState.loaded(updatedSettings)),
        );
      },
      orElse: () async {},
    );
  }

  /// Save all settings at once
  Future<void> updateSettings(Settings settings) async {
    emit(const SettingsState.loading());
    final result = await saveSettings(
      SaveSettingsParams(settings: settings),
    );
    result.fold(
      (failure) => emit(SettingsState.error(failure)),
      (_) => emit(SettingsState.loaded(settings)),
    );
  }
}
