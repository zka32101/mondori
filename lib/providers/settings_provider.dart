import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mondori/l10n/app_strings.dart';
import 'package:mondori/services/settings_service.dart';

class SettingsState {
  final AppThemeMode themeMode;
  final Locale? localeOverride; // null = 端末の言語に従う
  final bool soundEnabled;
  final bool musicEnabled;
  final double volume;
  final bool isLoaded;

  const SettingsState({
    required this.themeMode,
    required this.localeOverride,
    required this.soundEnabled,
    required this.musicEnabled,
    required this.volume,
    required this.isLoaded,
  });

  factory SettingsState.initial() => const SettingsState(
        themeMode: AppThemeMode.system,
        localeOverride: null,
        soundEnabled: true,
        musicEnabled: true,
        volume: 0.8,
        isLoaded: false,
      );

  SettingsState copyWith({
    AppThemeMode? themeMode,
    Locale? localeOverride,
    bool clearLocaleOverride = false,
    bool? soundEnabled,
    bool? musicEnabled,
    double? volume,
    bool? isLoaded,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      localeOverride:
          clearLocaleOverride ? null : (localeOverride ?? this.localeOverride),
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      volume: volume ?? this.volume,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  ThemeMode get flutterThemeMode {
    switch (themeMode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }
}

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref.read(settingsServiceProvider));
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsService _service;

  SettingsNotifier(this._service) : super(SettingsState.initial()) {
    _load();
  }

  Future<void> _load() async {
    final themeMode = await _service.getThemeMode();
    final localeCode = await _service.getLocaleCode();
    final soundEnabled = await _service.getSoundEnabled();
    final musicEnabled = await _service.getMusicEnabled();
    final volume = await _service.getVolume();

    state = state.copyWith(
      themeMode: themeMode,
      localeOverride: localeCode != null ? Locale(localeCode) : null,
      soundEnabled: soundEnabled,
      musicEnabled: musicEnabled,
      volume: volume,
      isLoaded: true,
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _service.setThemeMode(mode);
  }

  /// null を渡すと「端末の言語に従う」に戻る
  Future<void> setLocale(Locale? locale) async {
    if (locale == null) {
      state = state.copyWith(clearLocaleOverride: true);
    } else {
      state = state.copyWith(localeOverride: locale);
    }
    await _service.setLocaleCode(locale?.languageCode);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    state = state.copyWith(soundEnabled: enabled);
    await _service.setSoundEnabled(enabled);
  }

  Future<void> setMusicEnabled(bool enabled) async {
    state = state.copyWith(musicEnabled: enabled);
    await _service.setMusicEnabled(enabled);
  }

  Future<void> setVolume(double volume) async {
    state = state.copyWith(volume: volume);
    await _service.setVolume(volume);
  }
}

/// サポート対象言語のリスト（設定画面の選択肢に使用）
final supportedLocalesProvider = Provider<List<Locale>>((ref) {
  return AppStrings.supportedLocales;
});
