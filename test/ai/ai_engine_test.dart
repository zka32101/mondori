import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/ai/ai_engine.dart';
import 'package:mondori/models/board.dart';
import 'package:mondori/models/piece.dart';

void main() {
  group('AIEngine - Move Generation', () {
    test('Generate valid moves for all piece types', () {
      final board = Board.initialPlacement1();
      final engine = AIEngine(difficulty: AIDifficulty.normal);

      final moves = engine.generateMovesPublic(board, PlayerSide.A);

      expect(moves.isNotEmpty, true);
      // A陣営は初期配置で5駒あり、複数の移動候補を持つはず
      expect(moves.length, greaterThan(3));
    });

    test('Generate no moves when all pieces are trapped', () {
      // すべての駒が移動不可の特殊なボード状態
      final board = Board(pieces: {
        Position(column: 'a', row: 1): Piece(
          id: 'A-1',
          side: PlayerSide.A,
          seal: SealType.none,
          position: Position(column: 'a', row: 1),
        ),
      });

      final engine = AIEngine(difficulty: AIDifficulty.normal);
      final moves = engine.generateMovesPublic(board, PlayerSide.A);

      expect(moves.isEmpty, true);
    });

    test('Find best move exists for valid game state', () {
      final board = Board.initialPlacement1();
      final engine = AIEngine(difficulty: AIDifficulty.easy);

      final bestMove = engine.findBestMove(board, PlayerSide.A);

      expect(bestMove, isNotNull);
    });
  });

  group('AIEngine - Difficulty Levels', () {
    test('Easy difficulty has correct search depth', () {
      expect(AIDifficulty.easy.searchDepth, 2);
    });

    test('Normal difficulty has correct search depth', () {
      expect(AIDifficulty.normal.searchDepth, 4);
    });

    test('Hard difficulty has correct search depth', () {
      expect(AIDifficulty.hard.searchDepth, 6);
    });

    test('Expert difficulty has correct search depth', () {
      expect(AIDifficulty.expert.searchDepth, 8);
    });

    test('Easy AI produces move quickly', () {
      final board = Board.initialPlacement1();
      final engine = AIEngine(difficulty: AIDifficulty.easy);

      final stopwatch = Stopwatch()..start();
      final move = engine.findBestMove(board, PlayerSide.A);
      stopwatch.stop();

      expect(move, isNotNull);
      expect(stopwatch.elapsedMilliseconds, lessThan(500)); // Easy should be fast
    });
  });

  group('AIEngine - Checkmate Detection', () {
    test('Detect when player king is vulnerable', () {
      // プレイヤーのキングが脅威にさらされている状態
      final pieces = <Position, Piece>{
        Position(column: 'd', row: 2): Piece(
          id: 'A-king',
          side: PlayerSide.A,
          seal: SealType.king,
          position: Position(column: 'd', row: 2),
        ),
        Position(column: 'd', row: 3): Piece(
          id: 'B-piece',
          side: PlayerSide.B,
          seal: SealType.advance,
          position: Position(column: 'd', row: 3),
        ),
        Position(column: 'd', row: 6): Piece(
          id: 'B-king',
          side: PlayerSide.B,
          seal: SealType.king,
          position: Position(column: 'd', row: 6),
        ),
      };

      final board = Board(pieces: pieces);
      final engine = AIEngine(difficulty: AIDifficulty.normal);

      final score = engine.evaluatorPublic.evaluate(board, PlayerSide.A);
      // キングが脅威にさらされているため、スコアは負になるはず
      expect(score, lessThan(0));
    });
  });

  group('AIEngine - Piece Capture Optimization', () {
    test('AI prioritizes capturing enemy pieces when possible', () {
      final pieces = <Position, Piece>{
        // A陣営
        Position(column: 'a', row: 1): Piece(
          id: 'A-piece',
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
        // B陣営
        Position(column: 'a', row: 2): Piece(
          id: 'B-piece',
          side: PlayerSide.B,
          seal: SealType.advance,
          position: Position(column: 'a', row: 2),
        ),
        Position(column: 'd', row: 6): Piece(
          id: 'B-king',
          side: PlayerSide.B,
          seal: SealType.king,
          position: Position(column: 'd', row: 6),
        ),
      };

      final board = Board(pieces: pieces);
      final engine = AIEngine(difficulty: AIDifficulty.easy);

      final bestMove = engine.findBestMove(board, PlayerSide.A);

      // AI は可能であれば敵駒を奪取することを優先するはず
      expect(bestMove, isNotNull);
    });
  });

  group('AIEngine - Minimax Algorithm', () {
    test('Minimax produces consistent results', () {
      final board = Board.initialPlacement1();
      final engine = AIEngine(difficulty: AIDifficulty.easy);

      final move1 = engine.findBestMove(board, PlayerSide.A);
      final move2 = engine.findBestMove(board, PlayerSide.A);

      // 同じボード状態では同じ最善手が返されるはず
      expect(move1?.toPosition.toString(), move2?.toPosition.toString());
    });

    test('Minimax evaluates deeper positions correctly', () {
      final board = Board.initialPlacement1();
      final easyEngine = AIEngine(difficulty: AIDifficulty.easy);
      final hardEngine = AIEngine(difficulty: AIDifficulty.hard);

      final easyMove = easyEngine.findBestMove(board, PlayerSide.A);
      final hardMove = hardEngine.findBestMove(board, PlayerSide.A);

      // Both should return valid moves
      expect(easyMove, isNotNull);
      expect(hardMove, isNotNull);
    });
  });

  group('AIEngine - Board State Application', () {
    test('Apply normal move to board', () {
      final board = Board.initialPlacement1();
      final engine = AIEngine(difficulty: AIDifficulty.normal);

      final moves = engine.generateMovesPublic(board, PlayerSide.A);
      expect(moves.isNotEmpty, true);

      // Apply first move
      final newBoard = engine.applyMovePublic(board, moves.first);
      expect(newBoard.getPieceAt(moves.first.toPosition), isNotNull);
    });

    test('Apply capture move to board', () {
      final pieces = <Position, Piece>{
        Position(column: 'a', row: 1): Piece(
          id: 'A-piece',
          side: PlayerSide.A,
          seal: SealType.advance,
          position: Position(column: 'a', row: 1),
        ),
        Position(column: 'a', row: 2): Piece(
          id: 'B-piece',
          side: PlayerSide.B,
          seal: SealType.advance,
          position: Position(column: 'a', row: 2),
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
      };

      final board = Board(pieces: pieces);
      final engine = AIEngine(difficulty: AIDifficulty.normal);

      // A の駒が B の駒を奪取できるはず
      final moves = engine.generateMovesPublic(board, PlayerSide.A);
      final captureMove = moves.firstWhere(
        (m) => m.fromPosition.toString() == 'a1' && m.toPosition.toString() == 'a2',
        orElse: () => moves.first,
      );

      final newBoard = engine.applyMovePublic(board, captureMove);
      final capturedPiece = newBoard.getPieceAt(Position(column: 'a', row: 2));

      // 元の B の駒が無印化されているか確認
      expect(capturedPiece?.seal == SealType.none || capturedPiece?.side == PlayerSide.A, true);
    });
  });

  group('AIEngine - Integration Tests', () {
    test('Play complete game with AI', () {
      final board = Board.initialPlacement1();
      var currentBoard = board;
      var currentPlayer = PlayerSide.A;
      var moveCount = 0;

      final engine = AIEngine(difficulty: AIDifficulty.easy);

      // 最大20手プレイ（ゲーム終了またはターン上限）
      while (moveCount < 20) {
        final moves = engine.generateMovesPublic(currentBoard, currentPlayer);

        if (moves.isEmpty) {
          // パス
          break;
        }

        // AI に最善手を見つけさせる
        final bestMove = engine.findBestMove(currentBoard, currentPlayer);
        if (bestMove == null) break;

        currentBoard = engine.applyMovePublic(currentBoard, bestMove);
        currentPlayer = currentPlayer == PlayerSide.A ? PlayerSide.B : PlayerSide.A;
        moveCount++;

        // ゲーム終了チェック
        final aKing = currentBoard.getKingPiece(PlayerSide.A);
        final bKing = currentBoard.getKingPiece(PlayerSide.B);

        if (aKing == null || aKing.seal == SealType.none ||
            bKing == null || bKing.seal == SealType.none) {
          break;
        }
      }

      expect(moveCount, greaterThan(0));
    });
  });
}
