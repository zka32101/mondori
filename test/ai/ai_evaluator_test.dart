import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/ai/ai_evaluator.dart';
import 'package:mondori/models/board.dart';
import 'package:mondori/models/piece.dart';

void main() {
  group('AIEvaluator - Position Evaluation', () {
    test('Evaluate initial board position', () {
      final board = Board.initialPlacement1();
      final evaluator = AIEvaluator();

      final scoreA = evaluator.evaluate(board, PlayerSide.A);
      final scoreB = evaluator.evaluate(board, PlayerSide.B);

      // 初期配置では A が有利（B より駒が多い）
      expect(scoreA, greaterThan(scoreB));
    });

    test('Prefer position with more pieces', () {
      // A が多くの駒を持つボード
      final board = Board(pieces: {
        Position(column: 'a', row: 1): Piece(
          id: 'A-1',
          side: PlayerSide.A,
          seal: SealType.advance,
          position: Position(column: 'a', row: 1),
        ),
        Position(column: 'b', row: 1): Piece(
          id: 'A-2',
          side: PlayerSide.A,
          seal: SealType.swift,
          position: Position(column: 'b', row: 1),
        ),
        Position(column: 'c', row: 1): Piece(
          id: 'A-3',
          side: PlayerSide.A,
          seal: SealType.counter,
          position: Position(column: 'c', row: 1),
        ),
        Position(column: 'd', row: 2): Piece(
          id: 'A-king',
          side: PlayerSide.A,
          seal: SealType.king,
          position: Position(column: 'd', row: 2),
        ),
        // B は駒が少ない
        Position(column: 'd', row: 6): Piece(
          id: 'B-king',
          side: PlayerSide.B,
          seal: SealType.king,
          position: Position(column: 'd', row: 6),
        ),
      });

      final evaluator = AIEvaluator();
      final score = evaluator.evaluate(board, PlayerSide.A);

      // A が優位なため、スコアは正になるはず
      expect(score, greaterThan(0));
    });

    test('Heavily penalize king capture', () {
      // A のキングが無印化されている（奪取済み）
      final board = Board(pieces: {
        Position(column: 'd', row: 2): Piece(
          id: 'A-king',
          side: PlayerSide.A,
          seal: SealType.none,
          position: Position(column: 'd', row: 2),
        ),
        Position(column: 'd', row: 6): Piece(
          id: 'B-king',
          side: PlayerSide.B,
          seal: SealType.king,
          position: Position(column: 'd', row: 6),
        ),
      });

      final evaluator = AIEvaluator();
      final score = evaluator.evaluate(board, PlayerSide.A);

      // キングが奪取されているため、大きなペナルティ
      expect(score, lessThan(-50000));
    });

    test('Reward winning position', () {
      // B のキングが無印化されている
      final board = Board(pieces: {
        Position(column: 'd', row: 2): Piece(
          id: 'A-king',
          side: PlayerSide.A,
          seal: SealType.king,
          position: Position(column: 'd', row: 2),
        ),
        Position(column: 'd', row: 6): Piece(
          id: 'B-king',
          side: PlayerSide.B,
          seal: SealType.none,
          position: Position(column: 'd', row: 6),
        ),
      });

      final evaluator = AIEvaluator();
      final score = evaluator.evaluate(board, PlayerSide.A);

      // A が勝利しているため、大きなボーナス
      expect(score, greaterThan(50000));
    });
  });

  group('AIEvaluator - Material Score', () {
    test('Advance piece has correct value', () {
      // Advance 駒のみのボード
      final board = Board(pieces: {
        Position(column: 'a', row: 1): Piece(
          id: 'A-advance',
          side: PlayerSide.A,
          seal: SealType.advance,
          position: Position(column: 'a', row: 1),
        ),
        Position(column: 'd', row: 6): Piece(
          id: 'B-king',
          side: PlayerSide.B,
          seal: SealType.king,
          position: Position(column: 'd', row: 6),
        ),
      });

      final evaluator = AIEvaluator();
      final score = evaluator.evaluate(board, PlayerSide.A);

      // Advance の価値は king より低いはず
      expect(score, lessThan(1000));
    });

    test('King piece has highest value', () {
      final evaluator = AIEvaluator();

      // King のみのボード vs Advance のみのボード
      final kingBoard = Board(pieces: {
        Position(column: 'd', row: 2): Piece(
          id: 'A-king',
          side: PlayerSide.A,
          seal: SealType.king,
          position: Position(column: 'd', row: 2),
        ),
        Position(column: 'd', row: 6): Piece(
          id: 'B-king',
          side: PlayerSide.B,
          seal: SealType.king,
          position: Position(column: 'd', row: 6),
        ),
      });

      final advanceBoard = Board(pieces: {
        Position(column: 'a', row: 1): Piece(
          id: 'A-advance',
          side: PlayerSide.A,
          seal: SealType.advance,
          position: Position(column: 'a', row: 1),
        ),
        Position(column: 'd', row: 6): Piece(
          id: 'B-king',
          side: PlayerSide.B,
          seal: SealType.king,
          position: Position(column: 'd', row: 6),
        ),
      });

      final kingScore = evaluator.evaluate(kingBoard, PlayerSide.A);
      final advanceScore = evaluator.evaluate(advanceBoard, PlayerSide.A);

      // King の方が Advance より価値が高い
      expect(kingScore, greaterThan(advanceScore));
    });
  });

  group('AIEvaluator - Control Score', () {
    test('Evaluate control with movable positions', () {
      final board = Board(pieces: {
        // Swift は最大多くのマスに移動可能
        Position(column: 'c', row: 3): Piece(
          id: 'A-swift',
          side: PlayerSide.A,
          seal: SealType.swift,
          position: Position(column: 'c', row: 3),
        ),
        // Advance は1マスのみ
        Position(column: 'a', row: 1): Piece(
          id: 'A-advance',
          side: PlayerSide.A,
          seal: SealType.advance,
          position: Position(column: 'a', row: 1),
        ),
        Position(column: 'd', row: 6): Piece(
          id: 'B-king',
          side: PlayerSide.B,
          seal: SealType.king,
          position: Position(column: 'd', row: 6),
        ),
      });

      final evaluator = AIEvaluator();
      final score = evaluator.evaluate(board, PlayerSide.A);

      // Swift の可動性が高いため、スコアは正になるはず
      expect(score, greaterThan(0));
    });
  });

  group('AIEvaluator - Defense Score', () {
    test('Reward protected pieces', () {
      final board = Board(pieces: {
        // A の駒 2 つ（互いに守られている）
        Position(column: 'b', row: 2): Piece(
          id: 'A-piece1',
          side: PlayerSide.A,
          seal: SealType.advance,
          position: Position(column: 'b', row: 2),
        ),
        Position(column: 'c', row: 2): Piece(
          id: 'A-piece2',
          side: PlayerSide.A,
          seal: SealType.advance,
          position: Position(column: 'c', row: 2),
        ),
        Position(column: 'd', row: 2): Piece(
          id: 'A-king',
          side: PlayerSide.A,
          seal: SealType.king,
          position: Position(column: 'd', row: 2),
        ),
        Position(column: 'd', row: 6): Piece(
          id: 'B-king',
          side: PlayerSide.B,
          seal: SealType.king,
          position: Position(column: 'd', row: 6),
        ),
      });

      final evaluator = AIEvaluator();
      final score = evaluator.evaluate(board, PlayerSide.A);

      // 守られている駒があるため、スコアは正になるはず
      expect(score, greaterThan(0));
    });

    test('Penalize unprotected pieces', () {
      final board = Board(pieces: {
        // 孤立した A の駒
        Position(column: 'a', row: 1): Piece(
          id: 'A-isolated',
          side: PlayerSide.A,
          seal: SealType.advance,
          position: Position(column: 'a', row: 1),
        ),
        Position(column: 'd', row: 2): Piece(
          id: 'A-king',
          side: PlayerSide.A,
          seal: SealType.king,
          position: Position(column: 'd', row: 2),
        ),
        // B の攻撃力の高い駒
        Position(column: 'a', row: 2): Piece(
          id: 'B-threat',
          side: PlayerSide.B,
          seal: SealType.swift,
          position: Position(column: 'a', row: 2),
        ),
        Position(column: 'd', row: 6): Piece(
          id: 'B-king',
          side: PlayerSide.B,
          seal: SealType.king,
          position: Position(column: 'd', row: 6),
        ),
      });

      final evaluator = AIEvaluator();
      final score = evaluator.evaluate(board, PlayerSide.A);

      // 孤立した駒があり、脅威を受けているため、スコアは低いはず
      expect(score, lessThan(500));
    });
  });

  group('AIEvaluator - Consistency', () {
    test('Symmetric evaluation for both players', () {
      final board = Board.initialPlacement1();
      final evaluator = AIEvaluator();

      final scoreA = evaluator.evaluate(board, PlayerSide.A);
      final scoreB = evaluator.evaluate(board, PlayerSide.B);

      // A と B で見たスコアはほぼ逆数であるはず
      expect(scoreA, greaterThan(0));
      expect(scoreB, lessThan(0));
    });

    test('Consistent evaluation results for same position', () {
      final board = Board.initialPlacement1();
      final evaluator = AIEvaluator();

      final score1 = evaluator.evaluate(board, PlayerSide.A);
      final score2 = evaluator.evaluate(board, PlayerSide.A);

      expect(score1, equals(score2));
    });
  });
}
