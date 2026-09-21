import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/ai/ai_engine.dart';
import 'package:mondori/models/game_statistics.dart';
import 'package:mondori/models/move.dart';
import 'package:mondori/models/piece.dart';

void main() {
  Move sampleMove() => Move(
        piece: Piece(
          id: 'A-1',
          side: PlayerSide.A,
          seal: SealType.advance,
          position: Position(column: 'a', row: 1),
        ),
        fromPosition: Position(column: 'a', row: 1),
        toPosition: Position(column: 'a', row: 2),
      );

  group('GameStatistics - didHumanWin', () {
    test('True when humanSide matches winner', () {
      final stats = GameStatistics(
        gameId: 'g1',
        mode: GameMode.ai,
        winner: PlayerSide.A,
        humanSide: PlayerSide.A,
        difficulty: AIDifficulty.normal,
        turnCount: 10,
        duration: const Duration(minutes: 2),
        playedAt: DateTime(2026, 1, 1),
        moveHistory: [sampleMove()],
      );

      expect(stats.didHumanWin, true);
    });

    test('False when humanSide differs from winner', () {
      final stats = GameStatistics(
        gameId: 'g2',
        mode: GameMode.ai,
        winner: PlayerSide.B,
        humanSide: PlayerSide.A,
        turnCount: 8,
        duration: const Duration(minutes: 1),
        playedAt: DateTime(2026, 1, 1),
        moveHistory: const [],
      );

      expect(stats.didHumanWin, false);
    });

    test('False when humanSide is null (hot-seat game)', () {
      final stats = GameStatistics(
        gameId: 'g3',
        mode: GameMode.hotSeat,
        winner: PlayerSide.A,
        turnCount: 5,
        duration: const Duration(minutes: 1),
        playedAt: DateTime(2026, 1, 1),
        moveHistory: const [],
      );

      expect(stats.didHumanWin, false);
    });
  });

  group('GameStatistics - hasReplay', () {
    test('True when moveHistory is non-empty', () {
      final stats = GameStatistics(
        gameId: 'g4',
        mode: GameMode.ai,
        turnCount: 1,
        duration: Duration.zero,
        playedAt: DateTime(2026, 1, 1),
        moveHistory: [sampleMove()],
      );

      expect(stats.hasReplay, true);
    });

    test('False when moveHistory is empty', () {
      final stats = GameStatistics(
        gameId: 'g5',
        mode: GameMode.online,
        turnCount: 1,
        duration: Duration.zero,
        playedAt: DateTime(2026, 1, 1),
        moveHistory: const [],
      );

      expect(stats.hasReplay, false);
    });
  });

  group('GameStatistics - Serialization', () {
    test('Round-trip JSON preserves all fields including move history', () {
      final stats = GameStatistics(
        gameId: 'g6',
        mode: GameMode.ai,
        winner: PlayerSide.B,
        humanSide: PlayerSide.A,
        difficulty: AIDifficulty.hard,
        turnCount: 15,
        duration: const Duration(minutes: 3, seconds: 30),
        playedAt: DateTime(2026, 9, 21, 10, 30),
        moveHistory: [sampleMove(), sampleMove()],
      );

      final restored = GameStatistics.fromJson(stats.toJson());

      expect(restored, stats);
      expect(restored.moveHistory.length, 2);
    });

    test('Null fields survive serialization (draw / hot-seat)', () {
      final stats = GameStatistics(
        gameId: 'g7',
        mode: GameMode.hotSeat,
        turnCount: 0,
        duration: Duration.zero,
        playedAt: DateTime(2026, 1, 1),
        moveHistory: const [],
      );

      final restored = GameStatistics.fromJson(stats.toJson());

      expect(restored.winner, isNull);
      expect(restored.humanSide, isNull);
      expect(restored.difficulty, isNull);
    });

    test('Duration truncates to whole seconds (JSON stores seconds)', () {
      final stats = GameStatistics(
        gameId: 'g8',
        mode: GameMode.ai,
        turnCount: 1,
        duration: const Duration(seconds: 45),
        playedAt: DateTime(2026, 1, 1),
        moveHistory: const [],
      );

      final json = stats.toJson();
      expect(json['durationSeconds'], 45);

      final restored = GameStatistics.fromJson(json);
      expect(restored.duration, const Duration(seconds: 45));
    });
  });
}
