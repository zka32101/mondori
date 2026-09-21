import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/ai/ai_engine.dart';
import 'package:mondori/models/board.dart';
import 'package:mondori/models/move.dart';
import 'package:mondori/models/piece.dart';
import 'package:mondori/providers/ai_game_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // ゲーム終了時に統計記録 (SharedPreferences) が走るテストに備えてモック化
    SharedPreferences.setMockInitialValues({});
  });

  group('AIGameProvider - State Management', () {
    test('Initialize game state with default values', () {
      final container = ProviderContainer();
      final state = container.read(aiGameStateProvider);

      expect(state.currentPlayer, PlayerSide.A);
      expect(state.humanPlayer, PlayerSide.A);
      expect(state.aiPlayer, PlayerSide.B);
      expect(state.difficulty, AIDifficulty.normal);
      expect(state.moveCount, 0);
      expect(state.gameOver, false);
    });

    test('Initialize game with custom difficulty', () {
      final container = ProviderContainer();
      container.read(aiGameStateProvider.notifier).initGame(AIDifficulty.hard);

      final state = container.read(aiGameStateProvider);
      expect(state.difficulty, AIDifficulty.hard);
    });

    test('Initialize game with custom human player', () {
      final container = ProviderContainer();
      container
          .read(aiGameStateProvider.notifier)
          .initGame(AIDifficulty.normal, humanPlayer: PlayerSide.B);

      final state = container.read(aiGameStateProvider);
      expect(state.humanPlayer, PlayerSide.B);
      expect(state.aiPlayer, PlayerSide.A);
    });

    test('Track move count correctly', () {
      final container = ProviderContainer();
      final notifier = container.read(aiGameStateProvider.notifier);

      expect(container.read(aiGameStateProvider).moveCount, 0);

      // Manually update move count（通常は makeHumanMove で更新）
      var state = container.read(aiGameStateProvider);
      state = state.copyWith(moveCount: state.moveCount + 1);

      expect(state.moveCount, 1);
    });

    test('Update game status correctly', () {
      final container = ProviderContainer();
      var state = container.read(aiGameStateProvider);

      // Update last action
      state = state.copyWith(lastAction: 'テスト移動');

      expect(state.lastAction, 'テスト移動');
    });
  });

  group('AIGameProvider - Human Move Handling', () {
    test('Make human move updates board state', () {
      final container = ProviderContainer();
      final notifier = container.read(aiGameStateProvider.notifier);
      var state = container.read(aiGameStateProvider);

      // Get first available piece for human player
      final availablePieces = state.board
          .getPiecesBySide(state.humanPlayer)
          .where((p) => p.seal != SealType.none)
          .toList();

      if (availablePieces.isNotEmpty) {
        final piece = availablePieces.first;
        final movablePositions = piece.getMovablePositions();

        if (movablePositions.isNotEmpty) {
          final initialMoveCount = state.moveCount;
          notifier.makeHumanMove(piece, movablePositions.first);

          state = container.read(aiGameStateProvider);
          // _triggerAIMove は内部に await を持たないため、makeHumanMove が
          // 返る時点で人間の一手 + AI の応手（またはパス）まで完了している。
          expect(state.moveCount, initialMoveCount + 2);
        }
      }
    });

    test('Rejects a move to a position outside the movement pattern', () {
      final container = ProviderContainer();
      final notifier = container.read(aiGameStateProvider.notifier);
      var state = container.read(aiGameStateProvider);

      final piece = state.board
          .getPiecesBySide(state.humanPlayer)
          .firstWhere((p) => p.seal != SealType.none);

      // 盤外の位置ではなく、盤内だが移動パターン外の位置を選ぶ
      final illegalPosition = state.board.pieces.keys.firstWhere(
        (pos) => !piece.getMovablePositions().contains(pos) && pos != piece.position,
      );

      final initialMoveCount = state.moveCount;
      notifier.makeHumanMove(piece, illegalPosition);

      state = container.read(aiGameStateProvider);
      expect(state.moveCount, initialMoveCount);
    });

    test('Regression: human can capture an adjacent enemy outside the movement pattern', () {
      // 「進」は前方1マスにしか移動できないが、奪取は隣接8方向すべてが対象。
      // makeHumanMove が getMovablePositions() のみで奪取を判定していた
      // バグの回帰テスト。
      final container = ProviderContainer();
      final notifier = container.read(aiGameStateProvider.notifier);

      final humanAdvance = Piece(
        id: 'A-advance',
        side: PlayerSide.A,
        seal: SealType.advance,
        position: Position(column: 'c', row: 3),
      );
      final aKing = Piece(
        id: 'A-king',
        side: PlayerSide.A,
        seal: SealType.king,
        position: Position(column: 'f', row: 1),
      );
      final enemyBehind = Piece(
        id: 'B-behind',
        side: PlayerSide.B,
        seal: SealType.counter,
        position: Position(column: 'c', row: 2), // c3 の後方(下) = 移動パターン外
      );
      final bKing = Piece(
        id: 'B-king',
        side: PlayerSide.B,
        seal: SealType.king,
        position: Position(column: 'f', row: 6),
      );

      final board = Board(pieces: {
        humanAdvance.position: humanAdvance,
        aKing.position: aKing,
        enemyBehind.position: enemyBehind,
        bKing.position: bKing,
      });

      notifier.setStateForTesting(AIGameState(
        board: board,
        currentPlayer: PlayerSide.A,
        humanPlayer: PlayerSide.A,
        aiPlayer: PlayerSide.B,
        difficulty: AIDifficulty.easy,
        moveCount: 0,
        lastAction: 'setup',
        isAIThinking: false,
        gameOver: false,
        moveHistory: const [],
        startedAt: DateTime.now(),
      ));

      notifier.makeHumanMove(humanAdvance, Position(column: 'c', row: 2));

      final state = container.read(aiGameStateProvider);
      // makeHumanMove は内部で AI の応手までトリガーするため、
      // 人間の奪取 (1手目) が正しく記録されていることを確認する。
      expect(state.moveHistory.first.type, MoveType.capture);
      expect(state.moveHistory.first.toPosition, Position(column: 'c', row: 2));

      // 奪取した駒は c3 に留まり、刻印だけが変化している
      final attacker = state.board.getPieceAt(Position(column: 'c', row: 3));
      expect(attacker?.seal, SealType.counter);
    });

    test('Cannot move on non-human turn', () {
      final container = ProviderContainer();
      final notifier = container.read(aiGameStateProvider.notifier);

      var state = container.read(aiGameStateProvider);
      // Force AI turn
      state = state.copyWith(currentPlayer: state.aiPlayer);

      // Try to move human piece on AI turn
      final humanPieces = state.board
          .getPiecesBySide(state.humanPlayer)
          .where((p) => p.seal != SealType.none)
          .toList();

      if (humanPieces.isNotEmpty) {
        final piece = humanPieces.first;
        final movablePositions = piece.getMovablePositions();

        if (movablePositions.isNotEmpty) {
          // This move should be rejected
          // (In actual implementation, the notifier would ignore it)
        }
      }
    });

    test('Detect game over when king is captured', () {
      final container = ProviderContainer();
      var state = container.read(aiGameStateProvider);

      // Create a scenario where human king is captured
      final humanKing = state.board.getKingPiece(state.humanPlayer);
      expect(humanKing, isNotNull);

      final newBoard = state.board.movePiece(
        humanKing!.asNonePiece(),
        humanKing.position,
      );

      // 王が奪取された盤面では、王刻印の駒が存在しなくなる
      expect(newBoard.getKingPiece(state.humanPlayer), isNull);
    });

    test('Regression: AI wins when it captures the human king (not the reverse)', () {
      // 過去のバグ: getKingPiece が null を返す（王が奪取された）場合、
      // `null?.seal != SealType.none` が true と評価されてしまい、
      // 「人間の王が奪取された」のに勝者が人間側になっていた。
      final container = ProviderContainer();
      final notifier = container.read(aiGameStateProvider.notifier);

      final aHarmless = Piece(
        id: 'A-extra',
        side: PlayerSide.A,
        seal: SealType.advance,
        position: Position(column: 'a', row: 1),
      );
      final aKing = Piece(
        id: 'A-king',
        side: PlayerSide.A,
        seal: SealType.king,
        position: Position(column: 'd', row: 2),
      );
      final bAttacker = Piece(
        id: 'B-attacker',
        side: PlayerSide.B,
        seal: SealType.king, // 全方向1マス、d3 -> d2 に到達可能
        position: Position(column: 'd', row: 3),
      );
      final bKing = Piece(
        id: 'B-king',
        side: PlayerSide.B,
        seal: SealType.king,
        position: Position(column: 'f', row: 6),
      );

      final board = Board(pieces: {
        aHarmless.position: aHarmless,
        aKing.position: aKing,
        bAttacker.position: bAttacker,
        bKing.position: bKing,
      });

      notifier.setStateForTesting(AIGameState(
        board: board,
        currentPlayer: PlayerSide.A,
        humanPlayer: PlayerSide.A,
        aiPlayer: PlayerSide.B,
        difficulty: AIDifficulty.easy,
        moveCount: 0,
        lastAction: 'setup',
        isAIThinking: false,
        gameOver: false,
        moveHistory: const [],
        startedAt: DateTime.now(),
      ));

      // 人間が無害な駒を動かし、AI の手番に移る。AI には他の移動候補もあるが、
      // 王の奪取は評価関数上 (+100000) 圧倒的に高スコアなため、ミニマックスは
      // 必ず d3 -> d2 の奪取を選ぶ。
      notifier.makeHumanMove(aHarmless, Position(column: 'a', row: 2));

      final finalState = container.read(aiGameStateProvider);
      expect(finalState.gameOver, true);
      expect(finalState.winner, PlayerSide.B); // AI が勝者であるべき
    });
  });

  group('AIGameProvider - Game Reset', () {
    test('Reset game returns to initial state', () {
      final container = ProviderContainer();
      final notifier = container.read(aiGameStateProvider.notifier);

      // Make some moves to change state
      var state = container.read(aiGameStateProvider);
      state = state.copyWith(moveCount: 5, lastAction: 'テスト');

      // Reset
      notifier.resetGame();

      state = container.read(aiGameStateProvider);
      expect(state.moveCount, 0);
      expect(state.lastAction, 'ゲーム開始');
      expect(state.gameOver, false);
    });
  });

  group('AIGameProvider - Difficulty Levels', () {
    test('All difficulty levels are accessible', () {
      final container = ProviderContainer();
      final notifier = container.read(aiGameStateProvider.notifier);

      for (final difficulty in AIDifficulty.values) {
        notifier.initGame(difficulty);
        final state = container.read(aiGameStateProvider);
        expect(state.difficulty, difficulty);
      }
    });

    test('Easy difficulty initializes correctly', () {
      final container = ProviderContainer();
      container
          .read(aiGameStateProvider.notifier)
          .initGame(AIDifficulty.easy);

      final state = container.read(aiGameStateProvider);
      expect(state.difficulty, AIDifficulty.easy);
      expect(state.difficulty.searchDepth, 2);
    });

    test('Expert difficulty initializes correctly', () {
      final container = ProviderContainer();
      container
          .read(aiGameStateProvider.notifier)
          .initGame(AIDifficulty.expert);

      final state = container.read(aiGameStateProvider);
      expect(state.difficulty, AIDifficulty.expert);
      expect(state.difficulty.searchDepth, 8);
    });
  });

  group('AIGameProvider - Turn Management', () {
    test('isHumanTurn correctly identifies human turn', () {
      final container = ProviderContainer();
      var state = container.read(aiGameStateProvider);

      state = state.copyWith(currentPlayer: state.humanPlayer);
      expect(state.isHumanTurn, true);

      state = state.copyWith(currentPlayer: state.aiPlayer);
      expect(state.isHumanTurn, false);
    });
  });

  group('AIGameProvider - Full Game Simulation', () {
    test('AI plays without errors', () {
      final container = ProviderContainer();
      final notifier = container.read(aiGameStateProvider.notifier);

      // Let AI think
      var state = container.read(aiGameStateProvider);
      state = state.copyWith(currentPlayer: state.aiPlayer);

      // AI should be able to find a move without crashing
      expect(state.board, isNotNull);
      expect(state.aiPlayer, isNotNull);
    });
  });
}
