import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/services/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SoundEffect - Asset mapping', () {
    test('Each effect maps to a distinct asset path under sounds/', () {
      final paths = SoundEffect.values.map((e) => e.assetPath).toSet();
      expect(paths.length, SoundEffect.values.length);
      for (final path in paths) {
        expect(path, startsWith('sounds/'));
        expect(path, endsWith('.wav'));
      }
    });
  });

  group('AudioService - Defensive playback', () {
    test('playSound does not throw when disabled', () async {
      final service = AudioService();
      service.updateSettings(soundEnabled: false, musicEnabled: true, volume: 0.5);

      await expectLater(service.playSound(SoundEffect.pieceTap), completes);
    });

    test('playSound does not throw even without a real audio backend', () async {
      // テスト環境にはオーディオのプラットフォームチャンネル実装が無いため、
      // 内部の _guard により例外が飲み込まれ、正常に完了するはず。
      final service = AudioService();
      service.updateSettings(soundEnabled: true, musicEnabled: true, volume: 0.5);

      await expectLater(service.playSound(SoundEffect.capture), completes);
    });

    test('playBGM does not throw when music is disabled', () async {
      final service = AudioService();
      service.updateSettings(soundEnabled: true, musicEnabled: false, volume: 0.5);

      await expectLater(service.playBGM('sounds/bgm.mp3'), completes);
    });

    test('updateSettings does not throw', () {
      final service = AudioService();
      expect(
        () => service.updateSettings(soundEnabled: true, musicEnabled: true, volume: 1.0),
        returnsNormally,
      );
    });
  });
}
