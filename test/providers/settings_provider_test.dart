import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/providers/settings_provider.dart';
import 'package:mondori/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsProvider - Initial state', () {
    test('Starts with sensible defaults before async load completes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(settingsProvider);
      expect(state.themeMode, AppThemeMode.system);
      expect(state.localeOverride, isNull);
      expect(state.soundEnabled, true);
      expect(state.musicEnabled, true);
    });

    test('flutterThemeMode maps correctly for each AppThemeMode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);

      notifier.setThemeMode(AppThemeMode.light);
      expect(container.read(settingsProvider).flutterThemeMode, ThemeMode.light);

      notifier.setThemeMode(AppThemeMode.dark);
      expect(container.read(settingsProvider).flutterThemeMode, ThemeMode.dark);

      notifier.setThemeMode(AppThemeMode.system);
      expect(container.read(settingsProvider).flutterThemeMode, ThemeMode.system);
    });
  });

  group('SettingsProvider - Theme persistence', () {
    test('setThemeMode updates state and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(settingsProvider.notifier).setThemeMode(AppThemeMode.dark);

      expect(container.read(settingsProvider).themeMode, AppThemeMode.dark);
      expect(await SettingsService().getThemeMode(), AppThemeMode.dark);
    });
  });

  group('SettingsProvider - Locale', () {
    test('setLocale updates the override', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(settingsProvider.notifier).setLocale(const Locale('ko'));

      expect(container.read(settingsProvider).localeOverride, const Locale('ko'));
    });

    test('setLocale(null) clears the override', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);
      await notifier.setLocale(const Locale('en'));
      await notifier.setLocale(null);

      expect(container.read(settingsProvider).localeOverride, isNull);
    });
  });

  group('SettingsProvider - Sound and volume', () {
    test('Toggles sound and music independently', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);
      await notifier.setSoundEnabled(false);

      final state = container.read(settingsProvider);
      expect(state.soundEnabled, false);
      expect(state.musicEnabled, true);
    });

    test('setVolume updates state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(settingsProvider.notifier).setVolume(0.3);
      expect(container.read(settingsProvider).volume, 0.3);
    });
  });

  group('supportedLocalesProvider', () {
    test('Exposes the 4 supported locales', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final locales = container.read(supportedLocalesProvider);
      expect(locales.map((l) => l.languageCode).toSet(), {'ja', 'en', 'zh', 'ko'});
    });
  });
}
