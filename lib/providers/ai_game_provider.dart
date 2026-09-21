import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mondori/ai/ai_engine.dart';
import 'package:mondori/models/board.dart';
import 'package:mondori/models/move.dart';
import 'package:mondori/models/piece.dart';

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
  return AIGameNotifier();
});

/// AI ゲーム状態ノーティファイア
class AIGameNotifier extends StateNotifier<AIGameState> {
  AIEngine _aiEngine;

  AIGameNotifier() : super(AIGameState.initial(AIDifficulty.normal)) {
    _aiEngine = AIEngine(difficulty: state.difficulty);
  }

  /// ゲームを初期化
  void initGame(AIDifficulty difficulty, {PlayerSide humanPlayer = PlayerSide.A}) {
    _aiEngine = AIEngine(difficulty: difficulty);
    state = AIGameState.initial(difficulty, humanPlayer: humanPlayer);
  }

  /// 人間プレイヤーが移動
  void makeHumanMove(Piece piece, Position toPosition) {
    if (!state.isHumanTurn || state.isAIThinking) {
      return;
    }

    final targetPiece = state.board.getPieceAt(toPosition);

    Board newBoard;
    String actionText;

    if (targetPiece == null) {
      // 通常の移動
      newBoard = state.board.movePiece(piece, toPosition);
      actionText = '${piece.seal}を${piece.position}から$toPosition に移動';
    } else if (targetPiece.side != piece.side && targetPiece.seal != SealType.none) {
      // 敵駒への移動（刻印奪取）
      newBoard = state.board.capturePiece(piece, targetPiece);
      actionText = '${piece.seal}が$toPositionで${targetPiece.seal}を奪取';
    } else {
      return;
    }

    final nextPlayer = state.currentPlayer == PlayerSide.A ? PlayerSide.B : PlayerSide.A;

    // ゲーム終了状態をチェック
    final newState = state.copyWith(
      board: newBoard,
      currentPlayer: nextPlayer,
      moveCount: state.moveCount + 1,
      lastAction: actionText,
    );

    if (newState._isGameOver) {
      final winner = newState.board.getKingPiece(state.humanPlayer)?.seal != SealType.none
          ? state.humanPlayer
          : state.aiPlayer;
      state = newState.copyWith(
        gameOver: true,
        winner: winner,
      );
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

    // 移動を適用
    final targetPiece = state.board.getPieceAt(bestMove.toPosition);

    Board newBoard;
    String actionText;

    if (targetPiece == null) {
      newBoard = state.board.movePiece(bestMove.piece, bestMove.toPosition);
      actionText = 'AI: ${bestMove.piece.seal}を移動';
    } else if (targetPiece.side != bestMove.piece.side &&
        targetPiece.seal != SealType.none) {
      newBoard = state.board.capturePiece(bestMove.piece, targetPiece);
      actionText = 'AI: ${bestMove.piece.seal}が${bestMove.toPosition}で奪取';
    } else {
      state = state.copyWith(isAIThinking: false);
      return;
    }

    final nextPlayer = state.currentPlayer == PlayerSide.A ? PlayerSide.B : PlayerSide.A;

    final newState = state.copyWith(
      board: newBoard,
      currentPlayer: nextPlayer,
      moveCount: state.moveCount + 1,
      lastAction: actionText,
      isAIThinking: false,
    );

    if (newState._isGameOver) {
      final winner = newState.board.getKingPiece(state.humanPlayer)?.seal != SealType.none
          ? state.humanPlayer
          : state.aiPlayer;
      state = newState.copyWith(
        gameOver: true,
        winner: winner,
      );
    } else {
      state = newState;
    }
  }

  /// ゲームをリセット
  void resetGame() {
    initGame(state.difficulty, humanPlayer: state.humanPlayer);
  }
}
