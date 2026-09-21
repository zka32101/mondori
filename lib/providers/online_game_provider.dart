import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mondori/models/game_session.dart';
import 'package:mondori/models/piece.dart';
import 'package:mondori/services/online_game_service.dart';

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
  return OnlineGameNotifier(ref.read(onlineGameServiceProvider));
});

class OnlineGameNotifier extends StateNotifier<OnlineGameState> {
  final OnlineGameService _service;
  StreamSubscription<GameSession>? _sessionSubscription;

  OnlineGameNotifier(this._service) : super(OnlineGameState.initial());

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

  void _subscribeToSession(String sessionId) {
    _sessionSubscription?.cancel();
    _sessionSubscription = _service.watchSession(sessionId).listen(
      (session) {
        state = state.copyWith(
          connectionStatus: OnlineConnectionStatus.connected,
          session: session,
        );
      },
      onError: (e) {
        state = state.copyWith(
          connectionStatus: OnlineConnectionStatus.error,
          errorMessage: e.toString(),
        );
      },
    );
  }

  /// 移動を実行し、サーバーに反映
  Future<void> makeMove(Piece piece, Position toPosition) async {
    final session = state.session;
    if (session == null || !state.isMyTurn) return;

    final targetPiece = session.board.getPieceAt(toPosition);
    final newBoard = targetPiece == null
        ? session.board.movePiece(piece, toPosition)
        : session.board.capturePiece(piece, targetPiece);

    final nextPlayer =
        session.currentPlayer == PlayerSide.A ? PlayerSide.B : PlayerSide.A;

    await _service.submitMove(
      sessionId: session.id,
      newBoard: newBoard,
      nextPlayer: nextPlayer,
      moveCount: session.moveCount + 1,
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
