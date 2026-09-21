import 'package:mondori/models/board.dart';
import 'package:mondori/models/piece.dart';

/// ボード位置の評価器
class AIEvaluator {
  // スコア定数
  static const int kingCaptureScore = 100000;
  static const int kingThreatenedScore = -50000;
  static const int materialScoreAdvance = 300;
  static const int materialScoreSwift = 400;
  static const int materialScoreCounter = 350;
  static const int materialScoreKing = 1000;
  static const int controlScore = 10;
  static const int threatScore = 50;
  static const int defenseScore = 30;

  /// ボード位置を評価（AI プレイヤーの視点）
  int evaluate(Board board, PlayerSide aiPlayer) {
    // 王の状態をチェック
    final aiKing = board.getKingPiece(aiPlayer);
    final opponentKing = board.getKingPiece(_getOpponent(aiPlayer));

    // AI の王が奪取された場合
    if (aiKing == null || aiKing.seal == SealType.none) {
      return -kingCaptureScore;
    }

    // 対戦相手の王が奪取された場合
    if (opponentKing == null || opponentKing.seal == SealType.none) {
      return kingCaptureScore;
    }

    int score = 0;

    // 1. 素材スコア（駒の価値）
    score += _calculateMaterialScore(board, aiPlayer);
    score -= _calculateMaterialScore(board, _getOpponent(aiPlayer));

    // 2. コントロールスコア（盤面支配度）
    score += _calculateControlScore(board, aiPlayer);
    score -= _calculateControlScore(board, _getOpponent(aiPlayer));

    // 3. 脅威スコア（敵駒への脅威）
    score += _calculateThreatScore(board, aiPlayer);
    score -= _calculateThreatScore(board, _getOpponent(aiPlayer));

    // 4. 防御スコア（自駒の保護）
    score += _calculateDefenseScore(board, aiPlayer);

    // 5. 王の安全性
    score += _evaluateKingSafety(board, aiPlayer, aiKing);
    score -= _evaluateKingSafety(board, _getOpponent(aiPlayer), opponentKing);

    return score;
  }

  /// 素材スコアを計算（駒の価値の合計）
  int _calculateMaterialScore(Board board, PlayerSide side) {
    int score = 0;
    final pieces = board.getPiecesBySide(side);

    for (final piece in pieces) {
      switch (piece.seal) {
        case SealType.advance:
          score += materialScoreAdvance;
          break;
        case SealType.swift:
          score += materialScoreSwift;
          break;
        case SealType.counter:
          score += materialScoreCounter;
          break;
        case SealType.king:
          score += materialScoreKing;
          break;
        case SealType.none:
          // 無印駒は価値がない
          break;
      }
    }

    return score;
  }

  /// コントロールスコアを計算（可能な移動の数）
  int _calculateControlScore(Board board, PlayerSide side) {
    int totalMoves = 0;
    final pieces = board.getPiecesBySide(side);

    for (final piece in pieces) {
      if (piece.seal != SealType.none) {
        totalMoves += piece.getMovablePositions().length;
      }
    }

    return totalMoves * controlScore;
  }

  /// 脅威スコアを計算（敵駒への直接的な脅威）
  ///
  /// 奪取は刻印の移動パターンではなく8方向の隣接マスが対象のため、
  /// [Position.getAdjacentPositions] を基準に判定する。
  int _calculateThreatScore(Board board, PlayerSide side) {
    int threatCount = 0;
    final pieces = board.getPiecesBySide(side);
    final opponent = _getOpponent(side);

    for (final piece in pieces) {
      if (piece.seal == SealType.none) continue;

      for (final pos in piece.position.getAdjacentPositions()) {
        final targetPiece = board.getPieceAt(pos);
        if (targetPiece != null && targetPiece.side == opponent &&
            targetPiece.seal != SealType.none) {
          threatCount++;
        }
      }
    }

    return threatCount * threatScore;
  }

  /// 防御スコアを計算（守られている＝隣接する味方がいる駒の数）
  ///
  /// 奪取された駒はその場で無印化されるため、隣接する味方はすぐに教化で
  /// 取り返せる。この「取り返せる」関係も隣接判定で表す。
  int _calculateDefenseScore(Board board, PlayerSide side) {
    int defendedCount = 0;
    final pieces = board.getPiecesBySide(side);

    for (final piece in pieces) {
      if (piece.seal == SealType.none) continue;

      // この駒を守っているかどうかをチェック
      for (final otherPiece in pieces) {
        if (otherPiece.id == piece.id || otherPiece.seal == SealType.none) {
          continue;
        }

        if (otherPiece.position.getAdjacentPositions().contains(piece.position)) {
          defendedCount++;
          break;
        }
      }
    }

    return defendedCount * defenseScore;
  }

  /// 王の安全性を評価（隣接する敵駒＝次の一手で奪取され得る数）
  int _evaluateKingSafety(Board board, PlayerSide side, Piece? king) {
    if (king == null || king.seal == SealType.none) {
      return -kingThreatenedScore;
    }

    int safetyScore = 0;
    final opponent = _getOpponent(side);
    final opponentPieces = board.getPiecesBySide(opponent);

    // 王に隣接する敵駒の数をチェック（奪取は隣接判定のため）
    int threatCount = 0;
    for (final piece in opponentPieces) {
      if (piece.seal == SealType.none) continue;

      if (piece.position.getAdjacentPositions().contains(king.position)) {
        threatCount++;
      }
    }

    safetyScore = -threatCount * 20;

    return safetyScore;
  }

  /// 対戦相手を取得
  PlayerSide _getOpponent(PlayerSide side) {
    return side == PlayerSide.A ? PlayerSide.B : PlayerSide.A;
  }
}
