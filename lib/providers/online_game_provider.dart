import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mondori/models/board.dart';
import 'package:mondori/models/game_session.dart';
import 'package:mondori/models/game_statistics.dart';
import 'package:mondori/models/move.dart';
import 'package:mondori/models/piece.dart';
import 'package:mondori/providers/audio_provider.dart';
import 'package:mondori/providers/statistics_provider.dart';
import 'package:mondori/services/audio_service.dart';
import 'package:mondori/services/online_game_service.dart';
import 'package:uuid/uuid.dart';

/// オンライン対戦画面の接続状態
enum OnlineConnectionStatus {
  idle,
  matchmaking,
  connected,
  error,
}

class OnlineGameState {
  final OnlineConnectionStatus connectionStatus;
  final GameSession? session;
  final String? myPlayerId;
  final String? errorMessage;

  const OnlineGameState({
    required this.connectionStatus,
    this.session,
    this.myPlayerId,
    this.errorMessage,
  });

  factory OnlineGameState.initial() =>
      const OnlineGameState(connectionStatus: OnlineConnectionStatus.idle);

  OnlineGameState copyWith({
    OnlineConnectionStatus? connectionStatus,
    GameSession? session,
    String? myPlayerId,
    String? errorMessage,
  }) {
    return OnlineGameState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      session: session ?? this.session,
      myPlayerId: myPlayerId ?? this.myPlayerId,
      errorMessage: errorMessage,
    );
  }

  /// 自分の陣営を取得
  PlayerSide? get mySide {
    if (session == null || myPlayerId == null) return null;
    return session!.sideForPlayer(myPlayerId!);
  }

  /// 自分のターンかどうか
  bool get isMyTurn {
    final side = mySide;
    if (side == null || session == null) return false;
    return session!.currentPlayer == side;
  }
}

final onlineGameServiceProvider = Provider<OnlineGameService>((ref) {
  return OnlineGameService();
});

final onlineGameStateProvider =
    StateNotifierProvider.autoDispose<OnlineGameNotifier, OnlineGameState>((ref) {
  return OnlineGameNotifier(ref, ref.read(onlineGameServiceProvider));
});

class OnlineGameNotifier extends StateNotifier<OnlineGameState> {
  final Ref _ref;
  final OnlineGameService _service;
  final _uuid = const Uuid();
  StreamSubscription<GameSession>? _sessionSubscription;
  bool _resultRecorded = false;

  OnlineGameNotifier(this._ref, this._service) : super(OnlineGameState.initial());

  /// マッチメイキングを開始し、対戦相手が見つかり次第セッションを監視
  Future<void> startMatchmaking(String playerId) async {
    state = state.copyWith(
      connectionStatus: OnlineConnectionStatus.matchmaking,
      myPlayerId: playerId,
    );

    try {
      final sessionId = await _service.findOrCreateMatch(playerId);
      if (sessionId.isNotEmpty) {
        _subscribeToSession(sessionId);
      }
      // sessionId が空の場合はキュー待機中。呼び出し側でポーリングまたは
      // Cloud Functions からの通知（別途実装）で解決される想定。
    } catch (e) {
      state = state.copyWith(
        connectionStatus: OnlineConnectionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 招待コード（セッションID）を使って直接参加
  Future<void> joinByCode(String sessionId, String playerId) async {
    state = state.copyWith(
      connectionStatus: OnlineConnectionStatus.matchmaking,
      myPlayerId: playerId,
    );

    try {
      await _service.joinSession(sessionId, playerId);
      _subscribeToSession(sessionId);
    } catch (e) {
      state = state.copyWith(
        connectionStatus: OnlineConnectionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 招待コード対戦のホストとしてセッションを作成し、参加者を待つ
  ///
  /// 作成直後は playerIds が自分1人のみで status は waiting のまま。
  /// 相手が [joinByCode] で参加すると status が active に変わり、
  /// [_subscribeToSession] 経由で connectionStatus が connected になる
  /// （UI 側は matchmaking と同じ ref.listen パターンで検知できる）。
  Future<String?> hostGame(String playerId) async {
    state = state.copyWith(
      connectionStatus: OnlineConnectionStatus.matchmaking,
      myPlayerId: playerId,
    );

    try {
      final session = await _service.createSession(playerId);
      _subscribeToSession(session.id);
      return session.id;
    } catch (e) {
      state = state.copyWith(
        connectionStatus: OnlineConnectionStatus.error,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  void _subscribeToSession(String sessionId) {
    _sessionSubscription?.cancel();
    _resultRecorded = false;
    _sessionSubscription = _service.watchSession(sessionId).listen(
      (session) {
        state = state.copyWith(
          connectionStatus: OnlineConnectionStatus.connected,
          session: session,
        );

        if (session.status == GameSessionStatus.finished && !_resultRecorded) {
          _resultRecorded = true;
          final iWon = state.myPlayerId != null &&
              session.sideForPlayer(state.myPlayerId!) == session.winner;
          _ref
              .read(audioServiceProvider)
              .playSound(iWon ? SoundEffect.gameWon : SoundEffect.gameOver);
          _recordResult(session);
        }
      },
      onError: (e) {
        state = state.copyWith(
          connectionStatus: OnlineConnectionStatus.error,
          errorMessage: e.toString(),
        );
      },
    );
  }

  /// オンライン対戦の結果を統計に記録
  ///
  /// GameSession が保持する moveHistory をそのまま使うため、AI 対戦と同じ
  /// リプレイ画面でオンライン対戦も振り返れる。
  void _recordResult(GameSession session) {
    if (state.myPlayerId == null) return;

    final stats = GameStatistics(
      gameId: _uuid.v4(),
      mode: GameMode.online,
      winner: session.winner,
      humanSide: session.sideForPlayer(state.myPlayerId!),
      turnCount: session.moveCount,
      duration: Duration(
        milliseconds: session.updatedAt - session.createdAt,
      ),
      playedAt: DateTime.fromMillisecondsSinceEpoch(session.updatedAt),
      moveHistory: session.moveHistory,
    );

    _ref.read(gameHistoryProvider.notifier).recordGameResult(stats);
  }

  /// 移動・奪取・教化を実行し、サーバーに反映
  ///
  /// クライアント側の最低限のバリデーション（本番運用では submitMove Cloud
  /// Function 側でも同様の検証を追加すべき）。奪取・教化は移動を伴わないため
  /// 隣接判定を用いる点は AIGameNotifier.makeHumanMove と同じ。
  Future<void> makeMove(Piece piece, Position toPosition) async {
    final session = state.session;
    if (session == null || !state.isMyTurn) return;

    final targetPiece = session.board.getPieceAt(toPosition);
    Board newBoard;
    SoundEffect sound;
    MoveType type;

    if (targetPiece == null) {
      if (!piece.getMovablePositions().contains(toPosition)) return;
      newBoard = session.board.movePiece(piece, toPosition);
      sound = SoundEffect.pieceMove;
      type = MoveType.move;
    } else if (!piece.position.getAdjacentPositions().contains(toPosition)) {
      return;
    } else if (targetPiece.side != piece.side && targetPiece.seal != SealType.none) {
      newBoard = session.board.capturePiece(piece, targetPiece);
      sound = SoundEffect.capture;
      type = MoveType.capture;
    } else if (targetPiece.side == piece.side && targetPiece.seal == SealType.none) {
      newBoard = session.board.convertPiece(piece, targetPiece);
      sound = SoundEffect.convert;
      type = MoveType.convert;
    } else {
      return;
    }

    _ref.read(audioServiceProvider).playSound(sound);

    final nextPlayer =
        session.currentPlayer == PlayerSide.A ? PlayerSide.B : PlayerSide.A;
    final move = Move(
      piece: piece,
      fromPosition: piece.position,
      toPosition: toPosition,
      type: type,
    );

    await _service.submitMove(
      sessionId: session.id,
      newBoard: newBoard,
      nextPlayer: nextPlayer,
      moveCount: session.moveCount + 1,
      moveHistory: [...session.moveHistory, move],
    );

    // 王の奪取をチェックして結果を記録
    final aKing = newBoard.getKingPiece(PlayerSide.A);
    final bKing = newBoard.getKingPiece(PlayerSide.B);
    if (aKing == null || aKing.seal == SealType.none) {
      await _service.recordResult(sessionId: session.id, winner: PlayerSide.B);
    } else if (bKing == null || bKing.seal == SealType.none) {
      await _service.recordResult(sessionId: session.id, winner: PlayerSide.A);
    }
  }

  /// セッションから退出
  Future<void> leaveSession() async {
    final session = state.session;
    if (session != null) {
      await _service.abandonSession(session.id);
    }
    if (state.myPlayerId != null) {
      await _service.cancelMatchmaking(state.myPlayerId!);
    }
    _sessionSubscription?.cancel();
    state = OnlineGameState.initial();
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    super.dispose();
  }
}
