import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/ai/ai_engine.dart';
import 'package:mondori/models/achievement.dart';
import 'package:mondori/models/game_statistics.dart';
import 'package:mondori/models/move.dart';
import 'package:mondori/models/piece.dart';
import 'package:mondori/models/player_stats.dart';

void main() {
  Move sampleMove(MoveType type) => Move(
        piece: Piece(
          id: 'A-1',
          side: PlayerSide.A,
          seal: SealType.advance,
          position: Position(column: 'a', row: 1),
        ),
        fromPosition: Position(column: 'a', row: 1),
        toPosition: Position(column: 'a', row: 2),
        type: type,
      );

  GameStatistics aiGame({
    required PlayerSide winner,
    required PlayerSide humanSide,
    AIDifficulty difficulty = AIDifficulty.normal,
    DateTime? playedAt,
    List<Move> moveHistory = const [],
    GameMode mode = GameMode.ai,
  }) {
    return GameStatistics(
      gameId: 'g-${DateTime.now().microsecondsSinceEpoch}-${winner.name}',
      mode: mode,
      winner: winner,
      humanSide: humanSide,
      difficulty: mode == GameMode.ai ? difficulty : null,
      turnCount: 10,
      duration: const Duration(minutes: 2),
      playedAt: playedAt ?? DateTime(2026, 1, 1),
      moveHistory: moveHistory,
    );
  }

  group('evaluateAchievements - basics', () {
    test('Returns every defined achievement, none unlocked for empty history', () {
      final result = evaluateAchievements(
        historyNewestFirst: [],
        stats: PlayerStats.empty(),
        tutorialCompleted: false,
      );

      expect(result.length, allAchievements.length);
      expect(result.every((a) => !a.unlocked), true);
    });

    test('tutorialComplete unlocks purely from the flag, independent of history', () {
      final result = evaluateAchievements(
        historyNewestFirst: [],
        stats: PlayerStats.empty(),
        tutorialCompleted: true,
      );

      final tutorial = result.firstWhere(
        (a) => a.achievement.id == AchievementId.tutorialComplete,
      );
      expect(tutorial.unlocked, true);
    });
  });

  group('evaluateAchievements - win-based achievements', () {
    test('firstWin unlocks after a single AI win', () {
      final history = [aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A)];
      final stats = PlayerStats.fromHistory(history);

      final result = evaluateAchievements(
        historyNewestFirst: history,
        stats: stats,
        tutorialCompleted: false,
      );

      expect(
        result.firstWhere((a) => a.achievement.id == AchievementId.firstWin).unlocked,
        true,
      );
    });

    test('beatEasyAI/beatHardAI/beatExpertAI require a win at that specific difficulty', () {
      final history = [
        aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A, difficulty: AIDifficulty.easy),
      ];
      final stats = PlayerStats.fromHistory(history);
      final result = evaluateAchievements(
        historyNewestFirst: history,
        stats: stats,
        tutorialCompleted: false,
      );

      bool unlocked(AchievementId id) =>
          result.firstWhere((a) => a.achievement.id == id).unlocked;

      expect(unlocked(AchievementId.beatEasyAI), true);
      expect(unlocked(AchievementId.beatHardAI), false);
      expect(unlocked(AchievementId.beatExpertAI), false);
    });

    test('allDifficultiesConquered requires a win at all 4 difficulties', () {
      final history = [
        for (final d in AIDifficulty.values)
          aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A, difficulty: d),
      ];
      final stats = PlayerStats.fromHistory(history);
      final result = evaluateAchievements(
        historyNewestFirst: history,
        stats: stats,
        tutorialCompleted: false,
      );

      expect(
        result
            .firstWhere((a) => a.achievement.id == AchievementId.allDifficultiesConquered)
            .unlocked,
        true,
      );
    });

    test('allDifficultiesConquered stays locked with only 3 of 4 difficulties won', () {
      final history = [
        aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A, difficulty: AIDifficulty.easy),
        aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A, difficulty: AIDifficulty.normal),
        aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A, difficulty: AIDifficulty.hard),
      ];
      final stats = PlayerStats.fromHistory(history);
      final result = evaluateAchievements(
        historyNewestFirst: history,
        stats: stats,
        tutorialCompleted: false,
      );

      final achievement =
          result.firstWhere((a) => a.achievement.id == AchievementId.allDifficultiesConquered);
      expect(achievement.unlocked, false);
      expect(achievement.progress, 0.75);
    });

    test('firstOnlineWin requires a won game specifically in online mode', () {
      final aiOnly = [aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A)];
      final withOnlineWin = [
        ...aiOnly,
        aiGame(
          winner: PlayerSide.A,
          humanSide: PlayerSide.A,
          mode: GameMode.online,
        ),
      ];

      final aiOnlyResult = evaluateAchievements(
        historyNewestFirst: aiOnly,
        stats: PlayerStats.fromHistory(aiOnly),
        tutorialCompleted: false,
      );
      final withOnlineResult = evaluateAchievements(
        historyNewestFirst: withOnlineWin,
        stats: PlayerStats.fromHistory(withOnlineWin),
        tutorialCompleted: false,
      );

      expect(
        aiOnlyResult.firstWhere((a) => a.achievement.id == AchievementId.firstOnlineWin).unlocked,
        false,
      );
      expect(
        withOnlineResult
            .firstWhere((a) => a.achievement.id == AchievementId.firstOnlineWin)
            .unlocked,
        true,
      );
    });
  });

  group('evaluateAchievements - volume achievements', () {
    test('played10Games and played50Games track total game count with progress', () {
      final history = List.generate(
        10,
        (i) => aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A),
      );
      final stats = PlayerStats.fromHistory(history);
      final result = evaluateAchievements(
        historyNewestFirst: history,
        stats: stats,
        tutorialCompleted: false,
      );

      expect(
        result.firstWhere((a) => a.achievement.id == AchievementId.played10Games).unlocked,
        true,
      );
      final played50 =
          result.firstWhere((a) => a.achievement.id == AchievementId.played50Games);
      expect(played50.unlocked, false);
      expect(played50.progress, 0.2);
    });
  });

  group('evaluateAchievements - win streak', () {
    test('winStreak5 requires 5 consecutive human wins in chronological order', () {
      // historyNewestFirst は新しい順で渡される想定。5連勝を古い順に並べたものを反転。
      final oldestFirst = List.generate(
        5,
        (i) => aiGame(
          winner: PlayerSide.A,
          humanSide: PlayerSide.A,
          playedAt: DateTime(2026, 1, i + 1),
        ),
      );
      final newestFirst = oldestFirst.reversed.toList();

      final result = evaluateAchievements(
        historyNewestFirst: newestFirst,
        stats: PlayerStats.fromHistory(newestFirst),
        tutorialCompleted: false,
      );

      expect(
        result.firstWhere((a) => a.achievement.id == AchievementId.winStreak5).unlocked,
        true,
      );
    });

    test('A loss in between resets the streak count', () {
      final oldestFirst = [
        aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A, playedAt: DateTime(2026, 1, 1)),
        aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A, playedAt: DateTime(2026, 1, 2)),
        aiGame(winner: PlayerSide.B, humanSide: PlayerSide.A, playedAt: DateTime(2026, 1, 3)),
        aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A, playedAt: DateTime(2026, 1, 4)),
        aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A, playedAt: DateTime(2026, 1, 5)),
      ];
      final newestFirst = oldestFirst.reversed.toList();

      final result = evaluateAchievements(
        historyNewestFirst: newestFirst,
        stats: PlayerStats.fromHistory(newestFirst),
        tutorialCompleted: false,
      );

      final streak =
          result.firstWhere((a) => a.achievement.id == AchievementId.winStreak5);
      expect(streak.unlocked, false);
      expect(streak.progress, closeTo(2 / 5, 0.0001));
    });

    test('Hot-seat games (humanSide null) are excluded from the streak', () {
      final hotSeat = GameStatistics(
        gameId: 'hs1',
        mode: GameMode.hotSeat,
        winner: PlayerSide.A,
        turnCount: 5,
        duration: const Duration(minutes: 1),
        playedAt: DateTime(2026, 1, 1),
        moveHistory: const [],
      );
      final oldestFirst = [hotSeat];
      final result = evaluateAchievements(
        historyNewestFirst: oldestFirst.reversed.toList(),
        stats: PlayerStats.fromHistory(oldestFirst),
        tutorialCompleted: false,
      );

      final streak =
          result.firstWhere((a) => a.achievement.id == AchievementId.winStreak5);
      expect(streak.unlocked, false);
      expect(streak.progress, 0.0);
    });
  });

  group('evaluateAchievements - convertMaster', () {
    test('Counts MoveType.convert entries across all recorded games', () {
      final converts = List.generate(3, (_) => sampleMove(MoveType.convert));
      final history = [
        aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A, moveHistory: converts),
        aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A, moveHistory: converts),
        aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A, moveHistory: converts),
        aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A, moveHistory: converts),
      ]; // 4 games * 3 converts = 12 >= 10

      final result = evaluateAchievements(
        historyNewestFirst: history,
        stats: PlayerStats.fromHistory(history),
        tutorialCompleted: false,
      );

      expect(
        result.firstWhere((a) => a.achievement.id == AchievementId.convertMaster).unlocked,
        true,
      );
    });

    test('Move and capture entries do not count toward convertMaster', () {
      final nonConverts = [sampleMove(MoveType.move), sampleMove(MoveType.capture)];
      final history = [
        aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A, moveHistory: nonConverts),
      ];

      final result = evaluateAchievements(
        historyNewestFirst: history,
        stats: PlayerStats.fromHistory(history),
        tutorialCompleted: false,
      );

      expect(
        result.firstWhere((a) => a.achievement.id == AchievementId.convertMaster).unlocked,
        false,
      );
    });
  });

  group('evaluateAchievements - highWinRate', () {
    test('Requires at least 10 games AND a 70%+ win rate', () {
      // 7勝3敗 = 70%、ちょうど10戦
      final history = [
        for (var i = 0; i < 7; i++) aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A),
        for (var i = 0; i < 3; i++) aiGame(winner: PlayerSide.B, humanSide: PlayerSide.A),
      ];
      final stats = PlayerStats.fromHistory(history);

      final result = evaluateAchievements(
        historyNewestFirst: history,
        stats: stats,
        tutorialCompleted: false,
      );

      expect(
        result.firstWhere((a) => a.achievement.id == AchievementId.highWinRate).unlocked,
        true,
      );
    });

    test('High win rate with fewer than 10 games does not unlock', () {
      final history = [
        for (var i = 0; i < 4; i++) aiGame(winner: PlayerSide.A, humanSide: PlayerSide.A),
      ];
      final stats = PlayerStats.fromHistory(history);

      final result = evaluateAchievements(
        historyNewestFirst: history,
        stats: stats,
        tutorialCompleted: false,
      );

      expect(
        result.firstWhere((a) => a.achievement.id == AchievementId.highWinRate).unlocked,
        false,
      );
    });
  });
}
