import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/features/settings/domain/entities/settings.dart';
import 'package:searvo/features/settings/domain/repositories/settings_repository.dart';
import 'package:searvo/features/settings/domain/usecases/get_settings.dart';
import 'package:searvo/features/settings/domain/usecases/save_settings.dart';
import 'package:searvo/features/settings/domain/usecases/update_theme.dart';

/// Mock implementation of SettingsRepository for testing
class MockSettingsRepository implements SettingsRepository {
  Settings _currentSettings = Settings.defaultSettings();
  bool shouldFail = false;
  Failure failureToReturn = const CacheFailure('Mock error');

  void setSettings(Settings settings) {
    _currentSettings = settings;
  }

  @override
  Future<Either<Failure, Settings>> getSettings() async {
    if (shouldFail) {
      return Left(failureToReturn);
    }
    return Right(_currentSettings);
  }

  @override
  Future<Either<Failure, Unit>> setTheme(String theme) async {
    if (shouldFail) {
      return Left(failureToReturn);
    }
    _currentSettings = _currentSettings.copyWith(theme: theme);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> setNotifications(bool enabled) async {
    if (shouldFail) {
      return Left(failureToReturn);
    }
    _currentSettings = _currentSettings.copyWith(notificationsEnabled: enabled);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> setAutoSave(bool enabled) async {
    if (shouldFail) {
      return Left(failureToReturn);
    }
    _currentSettings = _currentSettings.copyWith(autoSaveEnabled: enabled);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> setLanguage(String language) async {
    if (shouldFail) {
      return Left(failureToReturn);
    }
    _currentSettings = _currentSettings.copyWith(language: language);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> setSearxngEndpoint(String endpoint) async {
    if (shouldFail) {
      return Left(failureToReturn);
    }
    _currentSettings = _currentSettings.copyWith(searxngEndpoint: endpoint);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> setSearchTimeout(int timeout) async {
    if (shouldFail) {
      return Left(failureToReturn);
    }
    _currentSettings = _currentSettings.copyWith(searchTimeout: timeout);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> saveSettings(Settings settings) async {
    if (shouldFail) {
      return Left(failureToReturn);
    }
    _currentSettings = settings;
    return const Right(unit);
  }
}

void main() {
  late MockSettingsRepository mockRepository;

  setUp(() {
    mockRepository = MockSettingsRepository();
  });

  group('GetSettings Use Case', () {
    late GetSettings useCase;

    setUp(() {
      useCase = GetSettings(mockRepository);
    });

    test('should get current settings from repository', () async {
      // Arrange
      final testSettings = Settings.defaultSettings();
      mockRepository.setSettings(testSettings);

      // Act
      final result = await useCase();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success, got failure'),
        (settings) {
          expect(settings.theme, 'dark');
          expect(settings.notificationsEnabled, true);
          expect(settings.autoSaveEnabled, false);
          expect(settings.language, 'en');
          expect(settings.searxngEndpoint, 'http://localhost:4000');
          expect(settings.searchTimeout, 30);
        },
      );
    });

    test('should return customized settings when set', () async {
      // Arrange
      const customSettings = Settings(
        theme: 'light',
        notificationsEnabled: false,
        autoSaveEnabled: true,
        language: 'es',
        searxngEndpoint: 'http://custom.example.com',
        searchTimeout: 60,
      );
      mockRepository.setSettings(customSettings);

      // Act
      final result = await useCase();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success, got failure'),
        (settings) {
          expect(settings.theme, 'light');
          expect(settings.notificationsEnabled, false);
          expect(settings.autoSaveEnabled, true);
          expect(settings.language, 'es');
          expect(settings.searxngEndpoint, 'http://custom.example.com');
          expect(settings.searchTimeout, 60);
        },
      );
    });

    test('should return CacheFailure when repository fails', () async {
      // Arrange
      mockRepository.shouldFail = true;
      mockRepository.failureToReturn = const CacheFailure('Failed to load settings');

      // Act
      final result = await useCase();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.message, 'Failed to load settings');
        },
        (settings) => fail('Expected failure, got success'),
      );
    });
  });

  group('SaveSettings Use Case', () {
    late SaveSettings useCase;

    setUp(() {
      useCase = SaveSettings(mockRepository);
    });

    test('should save settings to repository', () async {
      // Arrange
      const newSettings = Settings(
        theme: 'light',
        notificationsEnabled: false,
        autoSaveEnabled: true,
        language: 'fr',
        searxngEndpoint: 'http://new.endpoint.com',
        searchTimeout: 45,
      );
      final params = SaveSettingsParams(settings: newSettings);

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isRight(), true);
      
      // Verify settings were saved
      final getResult = await mockRepository.getSettings();
      getResult.fold(
        (failure) => fail('Expected success'),
        (settings) {
          expect(settings.theme, 'light');
          expect(settings.notificationsEnabled, false);
          expect(settings.autoSaveEnabled, true);
          expect(settings.language, 'fr');
          expect(settings.searxngEndpoint, 'http://new.endpoint.com');
          expect(settings.searchTimeout, 45);
        },
      );
    });

    test('should return failure when repository fails', () async {
      // Arrange
      mockRepository.shouldFail = true;
      mockRepository.failureToReturn = const CacheFailure('Failed to save');
      const settings = Settings(
        theme: 'dark',
        notificationsEnabled: true,
        autoSaveEnabled: false,
        language: 'en',
        searxngEndpoint: 'http://localhost:4000',
        searchTimeout: 30,
      );
      final params = SaveSettingsParams(settings: settings);

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to save'),
        (_) => fail('Expected failure'),
      );
    });
  });

  group('SaveSettingsParams', () {
    test('should be equal when settings are the same', () {
      final settings = Settings.defaultSettings();
      final params1 = SaveSettingsParams(settings: settings);
      final params2 = SaveSettingsParams(settings: settings);
      expect(params1, equals(params2));
    });

    test('should not be equal when settings are different', () {
      final settings1 = Settings.defaultSettings();
      final settings2 = settings1.copyWith(theme: 'light');
      final params1 = SaveSettingsParams(settings: settings1);
      final params2 = SaveSettingsParams(settings: settings2);
      expect(params1, isNot(equals(params2)));
    });

    test('should have correct props', () {
      final settings = Settings.defaultSettings();
      final params = SaveSettingsParams(settings: settings);
      expect(params.props, [settings]);
    });
  });

  group('UpdateTheme Use Case', () {
    late UpdateTheme useCase;

    setUp(() {
      useCase = UpdateTheme(mockRepository);
    });

    test('should update theme to light', () async {
      // Arrange
      const params = UpdateThemeParams(theme: 'light');

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isRight(), true);
      
      // Verify theme was updated
      final getResult = await mockRepository.getSettings();
      getResult.fold(
        (failure) => fail('Expected success'),
        (settings) => expect(settings.theme, 'light'),
      );
    });

    test('should update theme to dark', () async {
      // Arrange
      mockRepository.setSettings(
        Settings.defaultSettings().copyWith(theme: 'light'),
      );
      const params = UpdateThemeParams(theme: 'dark');

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isRight(), true);
      
      final getResult = await mockRepository.getSettings();
      getResult.fold(
        (failure) => fail('Expected success'),
        (settings) => expect(settings.theme, 'dark'),
      );
    });

    test('should update theme to system', () async {
      // Arrange
      const params = UpdateThemeParams(theme: 'system');

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isRight(), true);
      
      final getResult = await mockRepository.getSettings();
      getResult.fold(
        (failure) => fail('Expected success'),
        (settings) => expect(settings.theme, 'system'),
      );
    });

    test('should return failure when repository fails', () async {
      // Arrange
      mockRepository.shouldFail = true;
      mockRepository.failureToReturn = const CacheFailure('Theme update failed');
      const params = UpdateThemeParams(theme: 'light');

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Theme update failed'),
        (_) => fail('Expected failure'),
      );
    });
  });

  group('UpdateThemeParams', () {
    test('should be equal when theme is the same', () {
      const params1 = UpdateThemeParams(theme: 'dark');
      const params2 = UpdateThemeParams(theme: 'dark');
      expect(params1, equals(params2));
    });

    test('should not be equal when theme is different', () {
      const params1 = UpdateThemeParams(theme: 'dark');
      const params2 = UpdateThemeParams(theme: 'light');
      expect(params1, isNot(equals(params2)));
    });

    test('should have correct props', () {
      const params = UpdateThemeParams(theme: 'dark');
      expect(params.props, ['dark']);
    });
  });

  group('Repository Additional Methods', () {
    test('should update notifications setting', () async {
      // Act
      await mockRepository.setNotifications(false);

      // Assert
      final result = await mockRepository.getSettings();
      result.fold(
        (failure) => fail('Expected success'),
        (settings) => expect(settings.notificationsEnabled, false),
      );
    });

    test('should update autoSave setting', () async {
      // Act
      await mockRepository.setAutoSave(true);

      // Assert
      final result = await mockRepository.getSettings();
      result.fold(
        (failure) => fail('Expected success'),
        (settings) => expect(settings.autoSaveEnabled, true),
      );
    });

    test('should update language setting', () async {
      // Act
      await mockRepository.setLanguage('es');

      // Assert
      final result = await mockRepository.getSettings();
      result.fold(
        (failure) => fail('Expected success'),
        (settings) => expect(settings.language, 'es'),
      );
    });

    test('should update searxng endpoint', () async {
      // Act
      await mockRepository.setSearxngEndpoint('http://new.example.com');

      // Assert
      final result = await mockRepository.getSettings();
      result.fold(
        (failure) => fail('Expected success'),
        (settings) => expect(
          settings.searxngEndpoint,
          'http://new.example.com',
        ),
      );
    });

    test('should update search timeout', () async {
      // Act
      await mockRepository.setSearchTimeout(120);

      // Assert
      final result = await mockRepository.getSettings();
      result.fold(
        (failure) => fail('Expected success'),
        (settings) => expect(settings.searchTimeout, 120),
      );
    });

    test('should fail all operations when shouldFail is true', () async {
      // Arrange
      mockRepository.shouldFail = true;
      mockRepository.failureToReturn = const ServerFailure('Server error');

      // Act & Assert
      final notifResult = await mockRepository.setNotifications(true);
      expect(notifResult.isLeft(), true);

      final autoSaveResult = await mockRepository.setAutoSave(true);
      expect(autoSaveResult.isLeft(), true);

      final languageResult = await mockRepository.setLanguage('fr');
      expect(languageResult.isLeft(), true);

      final endpointResult = await mockRepository.setSearxngEndpoint('http://test.com');
      expect(endpointResult.isLeft(), true);

      final timeoutResult = await mockRepository.setSearchTimeout(60);
      expect(timeoutResult.isLeft(), true);
    });
  });

  group('Integration-like tests', () {
    test('should persist changes through multiple operations', () async {
      // Arrange
      final getSettings = GetSettings(mockRepository);
      final saveSettings = SaveSettings(mockRepository);
      final updateTheme = UpdateTheme(mockRepository);

      // Act - Make multiple changes
      await updateTheme(const UpdateThemeParams(theme: 'light'));
      await mockRepository.setLanguage('de');
      await mockRepository.setSearchTimeout(90);

      // Assert - Verify all changes persisted
      final result = await getSettings();
      result.fold(
        (failure) => fail('Expected success'),
        (settings) {
          expect(settings.theme, 'light');
          expect(settings.language, 'de');
          expect(settings.searchTimeout, 90);
          // Original defaults should remain for unchanged properties
          expect(settings.notificationsEnabled, true);
          expect(settings.autoSaveEnabled, false);
        },
      );
    });

    test('should be able to save complete settings object', () async {
      // Arrange
      final saveSettings = SaveSettings(mockRepository);
      final getSettings = GetSettings(mockRepository);
      
      const newSettings = Settings(
        theme: 'system',
        notificationsEnabled: false,
        autoSaveEnabled: true,
        language: 'ja',
        searxngEndpoint: 'http://japanese.searxng.com',
        searchTimeout: 15,
      );

      // Act
      await saveSettings(SaveSettingsParams(settings: newSettings));

      // Assert
      final result = await getSettings();
      result.fold(
        (failure) => fail('Expected success'),
        (settings) {
          expect(settings, equals(newSettings));
        },
      );
    });
  });
}
