import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsService - Theme mode', () {
    test('Defaults to system', () async {
      final service = SettingsService();
      expect(await service.getThemeMode(), AppThemeMode.system);
    });

    test('Persists and reloads theme mode', () async {
      final service = SettingsService();
      await service.setThemeMode(AppThemeMode.dark);
      expect(await service.getThemeMode(), AppThemeMode.dark);
    });
  });

  group('SettingsService - Locale', () {
    test('Defaults to null (follow system)', () async {
      final service = SettingsService();
      expect(await service.getLocaleCode(), isNull);
    });

    test('Persists and reloads locale code', () async {
      final service = SettingsService();
      await service.setLocaleCode('ko');
      expect(await service.getLocaleCode(), 'ko');
    });

    test('Setting null clears the override', () async {
      final service = SettingsService();
      await service.setLocaleCode('en');
      await service.setLocaleCode(null);
      expect(await service.getLocaleCode(), isNull);
    });
  });

  group('SettingsService - Sound and music', () {
    test('Both default to enabled', () async {
      final service = SettingsService();
      expect(await service.getSoundEnabled(), true);
      expect(await service.getMusicEnabled(), true);
    });

    test('Persists sound toggle independently of music', () async {
      final service = SettingsService();
      await service.setSoundEnabled(false);

      expect(await service.getSoundEnabled(), false);
      expect(await service.getMusicEnabled(), true);
    });
  });

  group('SettingsService - Volume', () {
    test('Defaults to 0.8', () async {
      final service = SettingsService();
      expect(await service.getVolume(), 0.8);
    });

    test('Persists and clamps volume to [0, 1]', () async {
      final service = SettingsService();

      await service.setVolume(1.5);
      expect(await service.getVolume(), 1.0);

      await service.setVolume(-0.5);
      expect(await service.getVolume(), 0.0);

      await service.setVolume(0.42);
      expect(await service.getVolume(), 0.42);
    });
  });
}
