import 'package:flutter_test/flutter_test.dart';
import 'package:searvo/features/settings/domain/entities/settings.dart';

void main() {
  group('Settings Entity', () {
    const testSettings = Settings(
      theme: 'dark',
      notificationsEnabled: true,
      autoSaveEnabled: false,
      language: 'en',
      searxngEndpoint: 'http://localhost:4000',
      searchTimeout: 30,
    );

    test('should be a valid Settings instance', () {
      expect(testSettings, isA<Settings>());
    });

    test('should have correct properties', () {
      expect(testSettings.theme, 'dark');
      expect(testSettings.notificationsEnabled, true);
      expect(testSettings.autoSaveEnabled, false);
      expect(testSettings.language, 'en');
      expect(testSettings.searxngEndpoint, 'http://localhost:4000');
      expect(testSettings.searchTimeout, 30);
    });

    group('isDarkMode getter', () {
      test('should return true when theme is dark', () {
        const darkSettings = Settings(
          theme: 'dark',
          notificationsEnabled: true,
          autoSaveEnabled: false,
          language: 'en',
          searxngEndpoint: 'http://localhost:4000',
          searchTimeout: 30,
        );
        expect(darkSettings.isDarkMode, true);
      });

      test('should return false when theme is light', () {
        const lightSettings = Settings(
          theme: 'light',
          notificationsEnabled: true,
          autoSaveEnabled: false,
          language: 'en',
          searxngEndpoint: 'http://localhost:4000',
          searchTimeout: 30,
        );
        expect(lightSettings.isDarkMode, false);
      });

      test('should return false when theme is system', () {
        const systemSettings = Settings(
          theme: 'system',
          notificationsEnabled: true,
          autoSaveEnabled: false,
          language: 'en',
          searxngEndpoint: 'http://localhost:4000',
          searchTimeout: 30,
        );
        expect(systemSettings.isDarkMode, false);
      });
    });

    group('copyWith', () {
      test('should create copy with updated theme', () {
        final updated = testSettings.copyWith(theme: 'light');
        expect(updated.theme, 'light');
        expect(updated.notificationsEnabled, testSettings.notificationsEnabled);
        expect(updated.autoSaveEnabled, testSettings.autoSaveEnabled);
        expect(updated.language, testSettings.language);
        expect(updated.searxngEndpoint, testSettings.searxngEndpoint);
        expect(updated.searchTimeout, testSettings.searchTimeout);
      });

      test('should create copy with updated notificationsEnabled', () {
        final updated = testSettings.copyWith(notificationsEnabled: false);
        expect(updated.theme, testSettings.theme);
        expect(updated.notificationsEnabled, false);
        expect(updated.autoSaveEnabled, testSettings.autoSaveEnabled);
      });

      test('should create copy with updated autoSaveEnabled', () {
        final updated = testSettings.copyWith(autoSaveEnabled: true);
        expect(updated.autoSaveEnabled, true);
        expect(updated.notificationsEnabled, testSettings.notificationsEnabled);
      });

      test('should create copy with updated language', () {
        final updated = testSettings.copyWith(language: 'es');
        expect(updated.language, 'es');
        expect(updated.theme, testSettings.theme);
      });

      test('should create copy with updated searxngEndpoint', () {
        final updated = testSettings.copyWith(
          searxngEndpoint: 'http://example.com:8080',
        );
        expect(updated.searxngEndpoint, 'http://example.com:8080');
      });

      test('should create copy with updated searchTimeout', () {
        final updated = testSettings.copyWith(searchTimeout: 60);
        expect(updated.searchTimeout, 60);
        expect(updated.theme, testSettings.theme);
      });

      test('should create copy with multiple updated fields', () {
        final updated = testSettings.copyWith(
          theme: 'light',
          notificationsEnabled: false,
          language: 'fr',
          searchTimeout: 45,
        );
        expect(updated.theme, 'light');
        expect(updated.notificationsEnabled, false);
        expect(updated.language, 'fr');
        expect(updated.searchTimeout, 45);
        expect(updated.autoSaveEnabled, testSettings.autoSaveEnabled);
        expect(updated.searxngEndpoint, testSettings.searxngEndpoint);
      });

      test('should return equivalent object when called with no arguments', () {
        final updated = testSettings.copyWith();
        expect(updated, testSettings);
      });
    });

    group('defaultSettings factory', () {
      test('should create settings with default values', () {
        final defaults = Settings.defaultSettings();
        expect(defaults.theme, 'dark');
        expect(defaults.notificationsEnabled, true);
        expect(defaults.autoSaveEnabled, false);
        expect(defaults.language, 'en');
        expect(defaults.searxngEndpoint, 'http://localhost:4000');
        expect(defaults.searchTimeout, 30);
      });

      test('should have dark mode by default', () {
        final defaults = Settings.defaultSettings();
        expect(defaults.isDarkMode, true);
      });
    });

    group('Equatable', () {
      test('should be equal when all properties are the same', () {
        const settings1 = Settings(
          theme: 'dark',
          notificationsEnabled: true,
          autoSaveEnabled: false,
          language: 'en',
          searxngEndpoint: 'http://localhost:4000',
          searchTimeout: 30,
        );
        const settings2 = Settings(
          theme: 'dark',
          notificationsEnabled: true,
          autoSaveEnabled: false,
          language: 'en',
          searxngEndpoint: 'http://localhost:4000',
          searchTimeout: 30,
        );
        expect(settings1, equals(settings2));
      });

      test('should not be equal when theme is different', () {
        const settings1 = Settings(
          theme: 'dark',
          notificationsEnabled: true,
          autoSaveEnabled: false,
          language: 'en',
          searxngEndpoint: 'http://localhost:4000',
          searchTimeout: 30,
        );
        const settings2 = Settings(
          theme: 'light',
          notificationsEnabled: true,
          autoSaveEnabled: false,
          language: 'en',
          searxngEndpoint: 'http://localhost:4000',
          searchTimeout: 30,
        );
        expect(settings1, isNot(equals(settings2)));
      });

      test('should not be equal when notificationsEnabled is different', () {
        const settings1 = Settings(
          theme: 'dark',
          notificationsEnabled: true,
          autoSaveEnabled: false,
          language: 'en',
          searxngEndpoint: 'http://localhost:4000',
          searchTimeout: 30,
        );
        const settings2 = Settings(
          theme: 'dark',
          notificationsEnabled: false,
          autoSaveEnabled: false,
          language: 'en',
          searxngEndpoint: 'http://localhost:4000',
          searchTimeout: 30,
        );
        expect(settings1, isNot(equals(settings2)));
      });

      test('should not be equal when searchTimeout is different', () {
        const settings1 = Settings(
          theme: 'dark',
          notificationsEnabled: true,
          autoSaveEnabled: false,
          language: 'en',
          searxngEndpoint: 'http://localhost:4000',
          searchTimeout: 30,
        );
        const settings2 = Settings(
          theme: 'dark',
          notificationsEnabled: true,
          autoSaveEnabled: false,
          language: 'en',
          searxngEndpoint: 'http://localhost:4000',
          searchTimeout: 60,
        );
        expect(settings1, isNot(equals(settings2)));
      });

      test('should have correct props', () {
        expect(
          testSettings.props,
          [
            'dark',
            true,
            false,
            'en',
            'http://localhost:4000',
            30,
          ],
        );
      });
    });
  });
}
