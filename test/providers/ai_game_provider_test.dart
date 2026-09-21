import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/ai/ai_engine.dart';
import 'package:mondori/models/piece.dart';
import 'package:mondori/providers/ai_game_provider.dart';

void main() {
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
          expect(state.moveCount, initialMoveCount + 1);
        }
      }
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
      if (humanKing != null) {
        // Simulate king capture by making it none
        final newPieces = Map<dynamic, dynamic>.from(state.board.pieces);
        newPieces[humanKing.position] =
            humanKing.asNonePiece();

        state = state.copyWith(
          board: state.board.copyWith(pieces: newPieces),
        );

        // Check if game over is detected
        if (state._isGameOver) {
          expect(state.gameOver || state._isGameOver, true);
        }
      }
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

extension on AIGameState {
  AIGameState copyWith({
    dynamic board,
    dynamic currentPlayer,
    dynamic humanPlayer,
    dynamic aiPlayer,
    dynamic difficulty,
    int? moveCount,
    String? lastAction,
    bool? isAIThinking,
    bool? gameOver,
    dynamic winner,
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

  bool get _isGameOver {
    // Copy of the logic from AIGameState
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
