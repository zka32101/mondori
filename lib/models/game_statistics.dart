import 'package:equatable/equatable.dart';
import 'package:mondori/ai/ai_engine.dart';
import 'package:mondori/models/move.dart';
import 'package:mondori/models/piece.dart';

/// プレイしたゲームの種類
enum GameMode {
  hotSeat, // 1台のデバイスで2人プレイ
  ai, // AI 対戦
  online, // オンライン対戦
}

/// 1 ゲーム分の記録
class GameStatistics extends Equatable {
  final String gameId;
  final GameMode mode;

  /// 勝者（引き分け・中断時は null）
  final PlayerSide? winner;

  /// この記録を作成した端末側のプレイヤーの陣営
  /// - AI 対戦: 人間プレイヤーの陣営
  /// - オンライン対戦: この端末のプレイヤーの陣営
  /// - ホットシート: 両者ともこの端末なので null（個人成績の対象外）
  final PlayerSide? humanSide;

  /// AI 対戦の場合の難度
  final AIDifficulty? difficulty;

  final int turnCount;
  final Duration duration;
  final DateTime playedAt;

  /// リプレイ用の指し手履歴（オンライン対戦など未対応の場合は空リスト）
  final List<Move> moveHistory;

  const GameStatistics({
    required this.gameId,
    required this.mode,
    required this.turnCount,
    required this.duration,
    required this.playedAt,
    required this.moveHistory,
    this.winner,
    this.humanSide,
    this.difficulty,
  });

  /// この端末のプレイヤーが勝利したか（humanSide 未設定の場合は判定不可 = false）
  bool get didHumanWin => humanSide != null && winner == humanSide;

  /// リプレイ可能か
  bool get hasReplay => moveHistory.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'mode': mode.name,
        'winner': winner?.name,
        'humanSide': humanSide?.name,
        'difficulty': difficulty?.name,
        'turnCount': turnCount,
        'durationSeconds': duration.inSeconds,
        'playedAt': playedAt.toIso8601String(),
        'moveHistory': moveHistory.map((m) => m.toJson()).toList(),
      };

  factory GameStatistics.fromJson(Map<String, dynamic> json) {
    return GameStatistics(
      gameId: json['gameId'] as String,
      mode: GameMode.values.byName(json['mode'] as String),
      winner: json['winner'] != null
          ? PlayerSide.values.byName(json['winner'] as String)
          : null,
      humanSide: json['humanSide'] != null
          ? PlayerSide.values.byName(json['humanSide'] as String)
          : null,
      difficulty: json['difficulty'] != null
          ? AIDifficulty.values.byName(json['difficulty'] as String)
          : null,
      turnCount: json['turnCount'] as int,
      duration: Duration(seconds: json['durationSeconds'] as int),
      playedAt: DateTime.parse(json['playedAt'] as String),
      moveHistory: (json['moveHistory'] as List<dynamic>)
          .map((m) => Move.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        gameId,
        mode,
        winner,
        humanSide,
        difficulty,
        turnCount,
        duration,
        playedAt,
        moveHistory,
      ];
}
