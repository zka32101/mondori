import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mondori/ai/ai_engine.dart';
import 'package:mondori/models/board.dart';
import 'package:mondori/models/game_statistics.dart';
import 'package:mondori/models/move.dart';
import 'package:mondori/models/piece.dart';
import 'package:mondori/providers/statistics_provider.dart';
import 'package:uuid/uuid.dart';

/// AI ゲーム状態
class AIGameState {
  final Board board;
  final PlayerSide currentPlayer;
  final PlayerSide humanPlayer;
  final PlayerSide aiPlayer;
  final AIDifficulty difficulty;
  final int moveCount;
  final String lastAction;
  final bool isAIThinking;
  final bool gameOver;
  final PlayerSide? winner;
  final List<Move> moveHistory;
  final DateTime startedAt;

  const AIGameState({
    required this.board,
    required this.currentPlayer,
    required this.humanPlayer,
    required this.aiPlayer,
    required this.difficulty,
    required this.moveCount,
    required this.lastAction,
    required this.isAIThinking,
    required this.gameOver,
    required this.moveHistory,
    required this.startedAt,
    this.winner,
  });

  factory AIGameState.initial(AIDifficulty difficulty, {PlayerSide humanPlayer = PlayerSide.A}) {
    return AIGameState(
      board: Board.initialPlacement1(),
      currentPlayer: PlayerSide.A,
      humanPlayer: humanPlayer,
      aiPlayer: humanPlayer == PlayerSide.A ? PlayerSide.B : PlayerSide.A,
      difficulty: difficulty,
      moveCount: 0,
      lastAction: 'ゲーム開始',
      isAIThinking: false,
      gameOver: false,
      moveHistory: const [],
      startedAt: DateTime.now(),
    );
  }

  AIGameState copyWith({
    Board? board,
    PlayerSide? currentPlayer,
    PlayerSide? humanPlayer,
    PlayerSide? aiPlayer,
    AIDifficulty? difficulty,
    int? moveCount,
    String? lastAction,
    bool? isAIThinking,
    bool? gameOver,
    PlayerSide? winner,
    List<Move>? moveHistory,
    DateTime? startedAt,
  }) {
    return AIGameState(
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      humanPlayer: humanPlayer ?? this.humanPlayer,
      aiPlayer: aiPlayer ?? this.aiPlayer,
      difficulty: difficulty ?? this.difficulty,
      moveCount: moveCount ?? this.moveCount,
      lastAction: lastAction ?? this.lastAction,
      isAIThinking: isAIThinking ?? this.isAIThinking,
      gameOver: gameOver ?? this.gameOver,
      winner: winner ?? this.winner,
      moveHistory: moveHistory ?? this.moveHistory,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  /// 現在のプレイヤーが人間か AI かを確認
  bool get isHumanTurn => currentPlayer == humanPlayer;

  /// ゲーム終了状態を確認
  bool get _isGameOver {
    final humanKing = board.getKingPiece(humanPlayer);
    final aiKing = board.getKingPiece(aiPlayer);

    if (humanKing == null || humanKing.seal == SealType.none) {
      return true;
    }
    if (aiKing == null || aiKing.seal == SealType.none) {
      return true;
    }

    return false;
  }
}

/// AI ゲーム状態プロバイダ
final aiGameStateProvider =
    StateNotifierProvider.autoDispose<AIGameNotifier, AIGameState>((ref) {
  return AIGameNotifier(ref);
});

/// AI ゲーム状態ノーティファイア
class AIGameNotifier extends StateNotifier<AIGameState> {
  final Ref _ref;
  AIEngine _aiEngine;
  final _uuid = const Uuid();

  AIGameNotifier(this._ref) : super(AIGameState.initial(AIDifficulty.normal)) {
    _aiEngine = AIEngine(difficulty: state.difficulty);
  }

  /// ゲームを初期化
  void initGame(AIDifficulty difficulty, {PlayerSide humanPlayer = PlayerSide.A}) {
    _aiEngine = AIEngine(difficulty: difficulty);
    state = AIGameState.initial(difficulty, humanPlayer: humanPlayer);
  }

  /// 人間プレイヤーが移動・奪取・教化のいずれかを実行
  ///
  /// 「移動」は刻印の移動パターンに従い空マスへ、「奪取」「教化」は
  /// 移動を伴わず8方向の隣接マスが対象（[AIEngine._generateMoves] と同じ基準）。
  void makeHumanMove(Piece piece, Position toPosition) {
    if (!state.isHumanTurn || state.isAIThinking) {
      return;
    }

    final targetPiece = state.board.getPieceAt(toPosition);

    Board newBoard;
    String actionText;
    MoveType type;

    if (targetPiece == null) {
      // 移動：刻印パターン上の空マスのみ
      if (!piece.getMovablePositions().contains(toPosition)) return;
      newBoard = state.board.movePiece(piece, toPosition);
      actionText = '${piece.seal}を${piece.position}から$toPosition に移動';
      type = MoveType.move;
    } else if (!piece.position.getAdjacentPositions().contains(toPosition)) {
      // 奪取・教化は隣接マスのみ対象
      return;
    } else if (targetPiece.side != piece.side && targetPiece.seal != SealType.none) {
      // 奪取：隣接する敵の有効駒
      newBoard = state.board.capturePiece(piece, targetPiece);
      actionText = '${piece.seal}が$toPositionで${targetPiece.seal}を奪取';
      type = MoveType.capture;
    } else if (targetPiece.side == piece.side && targetPiece.seal == SealType.none) {
      // 教化：隣接する自陣の無印駒
      newBoard = state.board.convertPiece(piece, targetPiece);
      actionText = '${piece.seal}が$toPositionを教化';
      type = MoveType.convert;
    } else {
      return;
    }

    final nextPlayer = state.currentPlayer == PlayerSide.A ? PlayerSide.B : PlayerSide.A;
    final move = Move(
      piece: piece,
      fromPosition: piece.position,
      toPosition: toPosition,
      type: type,
    );

    // ゲーム終了状態をチェック
    final newState = state.copyWith(
      board: newBoard,
      currentPlayer: nextPlayer,
      moveCount: state.moveCount + 1,
      lastAction: actionText,
      moveHistory: [...state.moveHistory, move],
    );

    if (newState._isGameOver) {
      _finishGame(newState);
    } else {
      state = newState;
      // AI のターンを待つ
      _triggerAIMove();
    }
  }

  /// AI が移動
  void _triggerAIMove() async {
    if (state.currentPlayer != state.aiPlayer || state.isAIThinking) {
      return;
    }

    state = state.copyWith(isAIThinking: true);

    // AI の最善手を探索
    final bestMove = _aiEngine.findBestMove(state.board, state.aiPlayer);

    if (bestMove == null) {
      // パス（移動不可）
      final nextPlayer = state.currentPlayer == PlayerSide.A ? PlayerSide.B : PlayerSide.A;
      state = state.copyWith(
        currentPlayer: nextPlayer,
        moveCount: state.moveCount + 1,
        lastAction: 'AI がパス',
        isAIThinking: false,
      );
      return;
    }

    // 手を適用（種別は AIEngine が合法手生成時に確定させたものをそのまま使う）
    Board newBoard;
    String actionText;

    switch (bestMove.type) {
      case MoveType.move:
        newBoard = state.board.movePiece(bestMove.piece, bestMove.toPosition);
        actionText = 'AI: ${bestMove.piece.seal}を移動';
        break;
      case MoveType.capture:
        final targetPiece = state.board.getPieceAt(bestMove.toPosition);
        if (targetPiece == null) {
          state = state.copyWith(isAIThinking: false);
          return;
        }
        newBoard = state.board.capturePiece(bestMove.piece, targetPiece);
        actionText = 'AI: ${bestMove.piece.seal}が${bestMove.toPosition}で奪取';
        break;
      case MoveType.convert:
        final targetPiece = state.board.getPieceAt(bestMove.toPosition);
        if (targetPiece == null) {
          state = state.copyWith(isAIThinking: false);
          return;
        }
        newBoard = state.board.convertPiece(bestMove.piece, targetPiece);
        actionText = 'AI: ${bestMove.piece.seal}が${bestMove.toPosition}を教化';
        break;
    }

    final nextPlayer = state.currentPlayer == PlayerSide.A ? PlayerSide.B : PlayerSide.A;

    final newState = state.copyWith(
      board: newBoard,
      currentPlayer: nextPlayer,
      moveCount: state.moveCount + 1,
      lastAction: actionText,
      isAIThinking: false,
      moveHistory: [...state.moveHistory, bestMove],
    );

    if (newState._isGameOver) {
      _finishGame(newState);
    } else {
      state = newState;
    }
  }

  /// ゲーム終了処理：状態更新 + 統計記録
  void _finishGame(AIGameState finishedState) {
    // 王が奪取される（=無印化される）と該当駒は SealType.king にマッチしなくなり
    // getKingPiece は null を返す。「王駒が null または無印」を「王が奪取された」と
    // 判定し、その陣営の敗北とする（human の生死のみを見て判定してはいけない）。
    final humanKing = finishedState.board.getKingPiece(finishedState.humanPlayer);
    final humanKingCaptured = humanKing == null || humanKing.seal == SealType.none;
    final winner = humanKingCaptured ? finishedState.aiPlayer : finishedState.humanPlayer;

    state = finishedState.copyWith(gameOver: true, winner: winner);

    final stats = GameStatistics(
      gameId: _uuid.v4(),
      mode: GameMode.ai,
      winner: winner,
      humanSide: state.humanPlayer,
      difficulty: state.difficulty,
      turnCount: state.moveCount,
      duration: DateTime.now().difference(state.startedAt),
      playedAt: DateTime.now(),
      moveHistory: state.moveHistory,
    );

    _ref.read(gameHistoryProvider.notifier).recordGameResult(stats);
  }

  /// ゲームをリセット
  void resetGame() {
    initGame(state.difficulty, humanPlayer: state.humanPlayer);
  }

  /// テスト専用：任意の盤面状態を直接注入する
  @visibleForTesting
  void setStateForTesting(AIGameState newState) {
    state = newState;
  }
}
