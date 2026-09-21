import 'package:equatable/equatable.dart';
import 'package:mondori/models/board.dart';
import 'package:mondori/models/piece.dart';

/// オンライン対戦セッションの状態
enum GameSessionStatus {
  waiting, // 対戦相手待ち
  active, // 対戦中
  finished, // 終了
  abandoned, // 中断（相手切断など）
}

/// オンライン対戦セッション
class GameSession extends Equatable {
  final String id;
  final List<String> playerIds; // [playerA の uid, playerB の uid]
  final Board board;
  final PlayerSide currentPlayer;
  final GameSessionStatus status;
  final PlayerSide? winner;
  final int moveCount;
  final int createdAt; // epoch millis
  final int updatedAt; // epoch millis

  const GameSession({
    required this.id,
    required this.playerIds,
    required this.board,
    required this.currentPlayer,
    required this.status,
    required this.moveCount,
    required this.createdAt,
    required this.updatedAt,
    this.winner,
  });

  /// 新規セッションを生成（作成者のみが参加した待機状態）
  factory GameSession.newSession({
    required String id,
    required String hostPlayerId,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return GameSession(
      id: id,
      playerIds: [hostPlayerId],
      board: Board.initialPlacement1(),
      currentPlayer: PlayerSide.A,
      status: GameSessionStatus.waiting,
      moveCount: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  GameSession copyWith({
    List<String>? playerIds,
    Board? board,
    PlayerSide? currentPlayer,
    GameSessionStatus? status,
    PlayerSide? winner,
    int? moveCount,
    int? updatedAt,
  }) {
    return GameSession(
      id: id,
      playerIds: playerIds ?? this.playerIds,
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      status: status ?? this.status,
      winner: winner ?? this.winner,
      moveCount: moveCount ?? this.moveCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// このセッションの陣営を uid から解決（先着が A、後着が B）
  PlayerSide? sideForPlayer(String uid) {
    final index = playerIds.indexOf(uid);
    if (index == -1) return null;
    return index == 0 ? PlayerSide.A : PlayerSide.B;
  }

  bool get isFull => playerIds.length >= 2;

  Map<String, dynamic> toJson() => {
        'id': id,
        'playerIds': playerIds,
        'board': board.toJson(),
        'currentPlayer': currentPlayer.name,
        'status': status.name,
        'winner': winner?.name,
        'moveCount': moveCount,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'] as String,
      playerIds: List<String>.from(json['playerIds'] as List),
      board: Board.fromJson(Map<String, dynamic>.from(json['board'] as Map)),
      currentPlayer: PlayerSide.values.byName(json['currentPlayer'] as String),
      status: GameSessionStatus.values.byName(json['status'] as String),
      winner: json['winner'] != null
          ? PlayerSide.values.byName(json['winner'] as String)
          : null,
      moveCount: json['moveCount'] as int,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }

  @override
  List<Object?> get props => [
        id,
        playerIds,
        board,
        currentPlayer,
        status,
        winner,
        moveCount,
        createdAt,
        updatedAt,
      ];
}
