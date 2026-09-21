import 'package:mondori/ai/ai_engine.dart';
import 'package:mondori/models/game_statistics.dart';

/// プレイヤーの集計成績
///
/// 個人成績は `humanSide` が設定されているゲーム（AI 対戦・オンライン対戦）のみを
/// 対象とする。ホットシートは同一端末上で両陣営を操作するため対象外。
class PlayerStats {
  final int totalGames;
  final int wins;
  final int losses;
  final int draws;
  final double averageTurnCount;
  final Duration averageDuration;
  final Map<AIDifficulty, int> winsByDifficulty;
  final Map<AIDifficulty, int> gamesByDifficulty;

  const PlayerStats({
    required this.totalGames,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.averageTurnCount,
    required this.averageDuration,
    required this.winsByDifficulty,
    required this.gamesByDifficulty,
  });

  double get winRate => totalGames == 0 ? 0.0 : wins / totalGames;

  factory PlayerStats.empty() => const PlayerStats(
        totalGames: 0,
        wins: 0,
        losses: 0,
        draws: 0,
        averageTurnCount: 0,
        averageDuration: Duration.zero,
        winsByDifficulty: {},
        gamesByDifficulty: {},
      );

  /// ゲーム履歴から個人成績を集計する
  factory PlayerStats.fromHistory(List<GameStatistics> history) {
    final relevant = history.where((g) => g.humanSide != null).toList();

    if (relevant.isEmpty) {
      return PlayerStats.empty();
    }

    var wins = 0;
    var losses = 0;
    var draws = 0;
    var totalTurns = 0;
    var totalDurationSeconds = 0;
    final winsByDifficulty = <AIDifficulty, int>{};
    final gamesByDifficulty = <AIDifficulty, int>{};

    for (final game in relevant) {
      if (game.winner == null) {
        draws++;
      } else if (game.didHumanWin) {
        wins++;
      } else {
        losses++;
      }

      totalTurns += game.turnCount;
      totalDurationSeconds += game.duration.inSeconds;

      if (game.difficulty != null) {
        gamesByDifficulty[game.difficulty!] =
            (gamesByDifficulty[game.difficulty!] ?? 0) + 1;
        if (game.didHumanWin) {
          winsByDifficulty[game.difficulty!] =
              (winsByDifficulty[game.difficulty!] ?? 0) + 1;
        }
      }
    }

    return PlayerStats(
      totalGames: relevant.length,
      wins: wins,
      losses: losses,
      draws: draws,
      averageTurnCount: totalTurns / relevant.length,
      averageDuration:
          Duration(seconds: totalDurationSeconds ~/ relevant.length),
      winsByDifficulty: winsByDifficulty,
      gamesByDifficulty: gamesByDifficulty,
    );
  }

  /// 難度別の勝率（分母が0の場合は 0.0）
  double winRateForDifficulty(AIDifficulty difficulty) {
    final games = gamesByDifficulty[difficulty] ?? 0;
    if (games == 0) return 0.0;
    return (winsByDifficulty[difficulty] ?? 0) / games;
  }
}
