import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/ai/ai_engine.dart';
import 'package:mondori/models/game_statistics.dart';
import 'package:mondori/models/piece.dart';
import 'package:mondori/models/player_stats.dart';

void main() {
  GameStatistics aiGame({
    required PlayerSide winner,
    required PlayerSide humanSide,
    AIDifficulty difficulty = AIDifficulty.normal,
    int turnCount = 10,
    Duration duration = const Duration(minutes: 2),
  }) {
    return GameStatistics(
      gameId: 'g-${winner.name}-${DateTime.now().microsecondsSinceEpoch}',
      mode: GameMode.ai,
      winner: winner,
      humanSide: humanSide,
      difficulty: difficulty,
      turnCount: turnCount,
      duration: duration,
      playedAt: DateTime(2026, 1, 1),
      moveHistory: const [],
    );
  }

  group('PlayerStats.empty', () {
    test('All zeros with 0.0 win rate', () {
      final stats = PlayerStats.empty();

      expect(stats.totalGames, 0);
      expect(stats.wins, 0);
      expect(stats.losses, 0);
      expect(stats.winRate, 0.0);
    });
  });

  group('PlayerStats.fromHistory', () {
    test('Empty history returns empty stats', () {
      final stats = PlayerStats.fromHistory([]);
      expect(stats.totalGames, 0);
    });

    test('Excludes hot-seat games (humanSide == null)', () {
      final hotSeat = GameStatistics(
        gameId: 'hs1',
        mode: GameMode.hotSeat,
        winner: PlayerSide.A,
        turnCount: 5,
        duration: const Duration(minutes: 1),
        playedAt: DateTime(2026, 1, 1),
        moveHistory: const [],
      );

      final stats = PlayerStats.fromHistory([hotSeat]);
      expect(stats.totalGames, 0);
    });

    test('Counts wins and losses correctly', () {
      final history = [
        aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A), // win
        aiGame(winner: PlayerSide.B, humanSide: PlayerSide.A), // loss
        aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A), // win
      ];

      final stats = PlayerStats.fromHistory(history);

      expect(stats.totalGames, 3);
      expect(stats.wins, 2);
      expect(stats.losses, 1);
      expect(stats.winRate, closeTo(2 / 3, 0.0001));
    });

    test('Counts draws when winner is null', () {
      final draw = GameStatistics(
        gameId: 'd1',
        mode: GameMode.online,
        humanSide: PlayerSide.A,
        turnCount: 20,
        duration: const Duration(minutes: 5),
        playedAt: DateTime(2026, 1, 1),
        moveHistory: const [],
      );

      final stats = PlayerStats.fromHistory([draw]);

      expect(stats.totalGames, 1);
      expect(stats.draws, 1);
      expect(stats.wins, 0);
      expect(stats.losses, 0);
    });

    test('Computes average turn count and duration', () {
      final history = [
        aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A, turnCount: 10, duration: const Duration(minutes: 2)),
        aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A, turnCount: 20, duration: const Duration(minutes: 4)),
      ];

      final stats = PlayerStats.fromHistory(history);

      expect(stats.averageTurnCount, 15.0);
      expect(stats.averageDuration, const Duration(minutes: 3));
    });

    test('Breaks down wins and games by difficulty', () {
      final history = [
        aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A, difficulty: AIDifficulty.easy),
        aiGame(winner: PlayerSide.B, humanSide: PlayerSide.A, difficulty: AIDifficulty.easy),
        aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A, difficulty: AIDifficulty.hard),
      ];

      final stats = PlayerStats.fromHistory(history);

      expect(stats.gamesByDifficulty[AIDifficulty.easy], 2);
      expect(stats.winsByDifficulty[AIDifficulty.easy], 1);
      expect(stats.gamesByDifficulty[AIDifficulty.hard], 1);
      expect(stats.winRateForDifficulty(AIDifficulty.easy), 0.5);
      expect(stats.winRateForDifficulty(AIDifficulty.hard), 1.0);
      expect(stats.winRateForDifficulty(AIDifficulty.expert), 0.0);
    });

    test('Online games without difficulty are excluded from breakdown', () {
      final onlineGame = GameStatistics(
        gameId: 'o1',
        mode: GameMode.online,
        winner: PlayerSide.A,
        humanSide: PlayerSide.A,
        turnCount: 12,
        duration: const Duration(minutes: 3),
        playedAt: DateTime(2026, 1, 1),
        moveHistory: const [],
      );

      final stats = PlayerStats.fromHistory([onlineGame]);

      expect(stats.totalGames, 1);
      expect(stats.wins, 1);
      expect(stats.gamesByDifficulty, isEmpty);
    });
  });
}
