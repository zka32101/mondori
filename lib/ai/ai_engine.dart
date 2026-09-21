import 'package:mondori/models/board.dart';
import 'package:mondori/models/move.dart';
import 'package:mondori/models/piece.dart';
import 'ai_evaluator.dart';

/// AI ゲーム難度設定
enum AIDifficulty {
  easy(2, 'Easy'),
  normal(4, 'Normal'),
  hard(6, 'Hard'),
  expert(8, 'Expert');

  final int searchDepth;
  final String label;

  const AIDifficulty(this.searchDepth, this.label);
}

/// AI エンジン - ミニマックス + アルファベータ枝刈り
class AIEngine {
  final AIEvaluator evaluator;
  final AIDifficulty difficulty;

  AIEngine({
    required this.difficulty,
  }) : evaluator = AIEvaluator();

  /// 最善の移動を探索
  Move? findBestMove(Board board, PlayerSide aiPlayer) {
    final possibleMoves = _generateMoves(board, aiPlayer);

    if (possibleMoves.isEmpty) {
      return null;
    }

    if (possibleMoves.length == 1) {
      return possibleMoves.first;
    }

    Move? bestMove;
    int bestScore = _minimax(
      board: board,
      depth: difficulty.searchDepth,
      isMaximizing: true,
      aiPlayer: aiPlayer,
      alpha: -999999,
      beta: 999999,
      onBestMove: (move) => bestMove = move,
    );

    return bestMove;
  }

  /// ミニマックス + アルファベータ枝刈り
  int _minimax({
    required Board board,
    required int depth,
    required bool isMaximizing,
    required PlayerSide aiPlayer,
    required int alpha,
    required int beta,
    Move Function(Move)? onBestMove,
  }) {
    // 終了条件：深さが0か、ゲームが終了状態
    if (depth == 0) {
      return evaluator.evaluate(board, aiPlayer);
    }

    final currentPlayer = isMaximizing ? aiPlayer : _getOpponent(aiPlayer);
    final moves = _generateMoves(board, currentPlayer);

    if (moves.isEmpty) {
      return evaluator.evaluate(board, aiPlayer);
    }

    int bestValue = isMaximizing ? -999999 : 999999;

    for (final move in moves) {
      final newBoard = _applyMove(board, move);
      final value = _minimax(
        board: newBoard,
        depth: depth - 1,
        isMaximizing: !isMaximizing,
        aiPlayer: aiPlayer,
        alpha: alpha,
        beta: beta,
      );

      if (isMaximizing) {
        if (value > bestValue) {
          bestValue = value;
          onBestMove?.call(move);
        }
        int newAlpha = alpha > value ? alpha : value;
        if (newAlpha >= beta) break; // ベータカット
      } else {
        if (value < bestValue) {
          bestValue = value;
        }
        int newBeta = beta < value ? beta : value;
        if (newBeta <= alpha) break; // アルファカット
      }
    }

    return bestValue;
  }

  /// ボード上で可能なすべての移動を生成（テスト用公開メソッド）
  List<Move> generateMovesPublic(Board board, PlayerSide side) {
    return _generateMoves(board, side);
  }

  /// ボード上で可能なすべての手（移動・奪取・教化）を生成
  ///
  /// 「移動」は刻印の移動パターン（[Piece.getMovablePositions]）に従うが、
  /// 「奪取」「教化」は移動を伴わないため、8方向の隣接マス
  /// （[Position.getAdjacentPositions]）を基準とする。この2つを混同すると、
  /// 例えば「進」駒が前方以外の隣接する敵駒を奪取できなくなってしまう。
  List<Move> _generateMoves(Board board, PlayerSide side) {
    final moves = <Move>[];
    final pieces = board.getPiecesBySide(side);

    for (final piece in pieces) {
      if (piece.seal == SealType.none) continue;

      // 移動：刻印パターン上の空マスへ
      for (final toPos in piece.getMovablePositions()) {
        if (board.getPieceAt(toPos) == null) {
          moves.add(Move(
            piece: piece,
            fromPosition: piece.position,
            toPosition: toPos,
            type: MoveType.move,
          ));
        }
      }

      // 奪取・教化：8方向の隣接マスへ（移動を伴わない）
      for (final toPos in piece.position.getAdjacentPositions()) {
        final targetPiece = board.getPieceAt(toPos);
        if (targetPiece == null) continue;

        if (targetPiece.side != side && targetPiece.seal != SealType.none) {
          // 敵の有効駒：奪取
          moves.add(Move(
            piece: piece,
            fromPosition: piece.position,
            toPosition: toPos,
            type: MoveType.capture,
          ));
        } else if (targetPiece.side == side && targetPiece.seal == SealType.none) {
          // 自陣の無印駒：教化
          moves.add(Move(
            piece: piece,
            fromPosition: piece.position,
            toPosition: toPos,
            type: MoveType.convert,
          ));
        }
      }
    }

    return moves;
  }

  /// 移動をボードに適用（テスト用公開メソッド）
  Board applyMovePublic(Board board, Move move) {
    return _applyMove(board, move);
  }

  /// Evaluator へのアクセス（テスト用）
  AIEvaluator get evaluatorPublic => evaluator;

  /// 手をボードに適用
  Board _applyMove(Board board, Move move) {
    switch (move.type) {
      case MoveType.move:
        return board.movePiece(move.piece, move.toPosition);
      case MoveType.capture:
        final targetPiece = board.getPieceAt(move.toPosition);
        if (targetPiece == null) return board;
        return board.capturePiece(move.piece, targetPiece);
      case MoveType.convert:
        final targetPiece = board.getPieceAt(move.toPosition);
        if (targetPiece == null) return board;
        return board.convertPiece(move.piece, targetPiece);
    }
  }

  /// 対戦相手を取得
  PlayerSide _getOpponent(PlayerSide side) {
    return side == PlayerSide.A ? PlayerSide.B : PlayerSide.A;
  }
}
