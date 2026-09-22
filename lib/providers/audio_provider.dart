import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mondori/providers/settings_provider.dart';
import 'package:mondori/services/audio_service.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();

  // 設定変更のたびに AudioService に反映
  ref.listen<SettingsState>(settingsProvider, (previous, next) {
    service.updateSettings(
      soundEnabled: next.soundEnabled,
      musicEnabled: next.musicEnabled,
      volume: next.volume,
    );
  }, fireImmediately: true);

  ref.onDispose(service.dispose);

  return service;
});
