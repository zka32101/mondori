import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// ゲーム内で再生する効果音の種類
enum SoundEffect {
  pieceTap('piece_tap.wav'),
  pieceMove('piece_move.wav'),
  capture('capture.wav'),
  convert('convert.wav'),
  turnSwitch('turn_switch.wav'),
  gameWon('game_won.wav'),
  gameOver('game_over.wav'),
  pieRule('pie_rule.wav');

  final String assetFileName;
  const SoundEffect(this.assetFileName);

  String get assetPath => 'sounds/$assetFileName';
}

/// 音声再生サービス（効果音・BGM）
///
/// 効果音は毎回新しい [AudioPlayer] で再生し、複数の効果音が重なって
/// 鳴っても互いに割り込まないようにする。BGM は専用のプレイヤーで
/// ループ再生する。
class AudioService {
  final AudioPlayer _bgmPlayer = AudioPlayer();
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _volume = 0.8;

  void updateSettings({
    required bool soundEnabled,
    required bool musicEnabled,
    required double volume,
  }) {
    _soundEnabled = soundEnabled;
    _musicEnabled = musicEnabled;
    _volume = volume;

    _guard(() => _bgmPlayer.setVolume(volume));
    if (!musicEnabled) {
      _guard(() => _bgmPlayer.pause());
    }
  }

  /// 効果音・BGM の再生はプラットフォームのオーディオバックエンドに依存するため、
  /// テスト環境やオーディオ出力のない端末で例外が出てもアプリを落とさない。
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // 再生失敗はゲームプレイに影響させない（無音で継続）
    }
  }

  Future<void> playSound(SoundEffect effect) async {
    if (!_soundEnabled) return;

    await _guard(() async {
      final player = AudioPlayer();
      await player.setVolume(_volume);
      await player.play(AssetSource(effect.assetPath));
      // 再生完了後にプレイヤーを破棄してリソースリークを防ぐ
      unawaited(player.onPlayerComplete.first.then((_) => player.dispose()));
    });
  }

  Future<void> playBGM(String assetPath) async {
    if (!_musicEnabled) return;

    await _guard(() async {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(_volume);
      await _bgmPlayer.play(AssetSource(assetPath));
    });
  }

  Future<void> stopBGM() async {
    await _guard(() => _bgmPlayer.stop());
  }

  Future<void> pauseBGM() async {
    await _guard(() => _bgmPlayer.pause());
  }

  Future<void> resumeBGM() async {
    if (!_musicEnabled) return;
    await _guard(() => _bgmPlayer.resume());
  }

  void dispose() {
    _bgmPlayer.dispose();
  }
}
