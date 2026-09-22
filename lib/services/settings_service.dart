import 'package:shared_preferences/shared_preferences.dart';

/// テーマモード設定
enum AppThemeMode { system, light, dark }

/// アプリ設定の永続化サービス（端末ローカル保存）
class SettingsService {
  static const _themeModeKey = 'mondori_theme_mode';
  static const _localeKey = 'mondori_locale';
  static const _soundEnabledKey = 'mondori_sound_enabled';
  static const _musicEnabledKey = 'mondori_music_enabled';
  static const _volumeKey = 'mondori_volume';
  static const _tutorialCompletedKey = 'mondori_tutorial_completed';

  Future<AppThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey);
    return AppThemeMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => AppThemeMode.system,
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  /// 言語コード（'ja', 'en', 'zh', 'ko'）。未設定時は null（端末の言語に従う）
  Future<String?> getLocaleCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey);
  }

  Future<void> setLocaleCode(String? code) async {
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, code);
    }
  }

  Future<bool> getSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEnabledKey) ?? true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
  }

  Future<bool> getMusicEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_musicEnabledKey) ?? true;
  }

  Future<void> setMusicEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicEnabledKey, enabled);
  }

  /// 0.0 - 1.0
  Future<double> getVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_volumeKey) ?? 0.8;
  }

  Future<void> setVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, volume.clamp(0.0, 1.0));
  }

  Future<bool> getTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialCompletedKey) ?? false;
  }

  Future<void> setTutorialCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompletedKey, completed);
  }
}
