import 'package:flutter/material.dart';
import 'package:mondori/ai/ai_engine.dart';
import 'package:mondori/models/game_statistics.dart';
import 'package:mondori/models/move.dart';
import 'package:mondori/models/player_stats.dart';

/// 実績の識別子
enum AchievementId {
  firstWin,
  beatEasyAI,
  beatHardAI,
  beatExpertAI,
  allDifficultiesConquered,
  winStreak5,
  played10Games,
  played50Games,
  convertMaster,
  firstOnlineWin,
  highWinRate,
  tutorialComplete,
}

/// 実績の定義（達成条件は含まない。判定ロジックは [evaluateAchievements] 側）
class Achievement {
  final AchievementId id;
  final String title;
  final String description;
  final IconData icon;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// 判定済みの実績（達成しているかどうか、進捗の目安を含む）
class AchievementProgress {
  final Achievement achievement;
  final bool unlocked;

  /// 0.0〜1.0 の達成度。達成済みなら常に 1.0。未達成の場合の目安表示に使う
  /// （例: 3連勝中なら 5連勝実績の progress は 0.6）。
  final double progress;

  const AchievementProgress({
    required this.achievement,
    required this.unlocked,
    required this.progress,
  });
}

const List<Achievement> allAchievements = [
  Achievement(
    id: AchievementId.firstWin,
    title: '初勝利',
    description: 'AI対戦またはオンライン対戦で1勝する',
    icon: Icons.star,
  ),
  Achievement(
    id: AchievementId.beatEasyAI,
    title: '初心者卒業',
    description: 'Easy 難度の AI に勝利する',
    icon: Icons.sentiment_satisfied,
  ),
  Achievement(
    id: AchievementId.beatHardAI,
    title: '熟練の証',
    description: 'Hard 難度の AI に勝利する',
    icon: Icons.local_fire_department,
  ),
  Achievement(
    id: AchievementId.beatExpertAI,
    title: 'エキスパート撃破',
    description: 'Expert 難度の AI に勝利する',
    icon: Icons.military_tech,
  ),
  Achievement(
    id: AchievementId.allDifficultiesConquered,
    title: '全難度制覇',
    description: '4つすべての AI 難度で勝利する',
    icon: Icons.emoji_events,
  ),
  Achievement(
    id: AchievementId.winStreak5,
    title: '5連勝',
    description: 'AI・オンライン対戦を通算5連勝する',
    icon: Icons.trending_up,
  ),
  Achievement(
    id: AchievementId.played10Games,
    title: '対戦経験者',
    description: 'AI・オンライン対戦を合計10回プレイする',
    icon: Icons.videogame_asset,
  ),
  Achievement(
    id: AchievementId.played50Games,
    title: '紋取りの猛者',
    description: 'AI・オンライン対戦を合計50回プレイする',
    icon: Icons.workspace_premium,
  ),
  Achievement(
    id: AchievementId.convertMaster,
    title: '教化マスター',
    description: '記録された対戦の中で「教化」を合計10回行う',
    icon: Icons.auto_fix_high,
  ),
  Achievement(
    id: AchievementId.firstOnlineWin,
    title: 'オンライン初勝利',
    description: 'オンライン対戦で1勝する',
    icon: Icons.public,
  ),
  Achievement(
    id: AchievementId.highWinRate,
    title: '高勝率プレイヤー',
    description: '10戦以上プレイして勝率70%以上を達成する',
    icon: Icons.insights,
  ),
  Achievement(
    id: AchievementId.tutorialComplete,
    title: '基礎を学んだ証',
    description: 'チュートリアルを完了する',
    icon: Icons.school,
  ),
];

/// 通算の指し手履歴から連勝数の最大値を計算する（AI・オンライン対戦のみ対象）
int _longestWinStreak(List<GameStatistics> historyOldestFirst) {
  var longest = 0;
  var current = 0;

  for (final game in historyOldestFirst) {
    if (game.humanSide == null) continue; // ホットシートは対象外

    if (game.didHumanWin) {
      current++;
      longest = current > longest ? current : longest;
    } else {
      current = 0;
    }
  }

  return longest;
}

int _totalConverts(List<GameStatistics> history) {
  var total = 0;
  for (final game in history) {
    total += game.moveHistory.where((m) => m.type == MoveType.convert).length;
  }
  return total;
}

/// ゲーム履歴・成績・チュートリアル完了状況から実績の達成状況を判定する。
///
/// [historyNewestFirst] は StatisticsService/GameHistoryProvider が返す
/// 「新しい順」のリストをそのまま渡してよい（内部で古い順に並べ替える）。
List<AchievementProgress> evaluateAchievements({
  required List<GameStatistics> historyNewestFirst,
  required PlayerStats stats,
  required bool tutorialCompleted,
}) {
  final historyOldestFirst = historyNewestFirst.reversed.toList();
  final longestStreak = _longestWinStreak(historyOldestFirst);
  final totalConverts = _totalConverts(historyNewestFirst);
  final hasOnlineWin = historyNewestFirst
      .any((g) => g.mode == GameMode.online && g.didHumanWin);
  final allDifficultiesWon = AIDifficulty.values
      .every((d) => (stats.winsByDifficulty[d] ?? 0) > 0);

  bool unlocked(AchievementId id) {
    switch (id) {
      case AchievementId.firstWin:
        return stats.wins >= 1;
      case AchievementId.beatEasyAI:
        return (stats.winsByDifficulty[AIDifficulty.easy] ?? 0) >= 1;
      case AchievementId.beatHardAI:
        return (stats.winsByDifficulty[AIDifficulty.hard] ?? 0) >= 1;
      case AchievementId.beatExpertAI:
        return (stats.winsByDifficulty[AIDifficulty.expert] ?? 0) >= 1;
      case AchievementId.allDifficultiesConquered:
        return allDifficultiesWon;
      case AchievementId.winStreak5:
        return longestStreak >= 5;
      case AchievementId.played10Games:
        return stats.totalGames >= 10;
      case AchievementId.played50Games:
        return stats.totalGames >= 50;
      case AchievementId.convertMaster:
        return totalConverts >= 10;
      case AchievementId.firstOnlineWin:
        return hasOnlineWin;
      case AchievementId.highWinRate:
        return stats.totalGames >= 10 && stats.winRate >= 0.7;
      case AchievementId.tutorialComplete:
        return tutorialCompleted;
    }
  }

  double progressFor(AchievementId id, bool isUnlocked) {
    if (isUnlocked) return 1.0;

    switch (id) {
      case AchievementId.winStreak5:
        return (longestStreak / 5).clamp(0.0, 1.0);
      case AchievementId.played10Games:
        return (stats.totalGames / 10).clamp(0.0, 1.0);
      case AchievementId.played50Games:
        return (stats.totalGames / 50).clamp(0.0, 1.0);
      case AchievementId.convertMaster:
        return (totalConverts / 10).clamp(0.0, 1.0);
      case AchievementId.allDifficultiesConquered:
        final wonCount =
            AIDifficulty.values.where((d) => (stats.winsByDifficulty[d] ?? 0) > 0).length;
        return (wonCount / AIDifficulty.values.length).clamp(0.0, 1.0);
      default:
        return 0.0;
    }
  }

  return allAchievements.map((achievement) {
    final isUnlocked = unlocked(achievement.id);
    return AchievementProgress(
      achievement: achievement,
      unlocked: isUnlocked,
      progress: progressFor(achievement.id, isUnlocked),
    );
  }).toList();
}
