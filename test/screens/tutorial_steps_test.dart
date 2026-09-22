import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/models/move.dart';
import 'package:mondori/models/piece.dart';
import 'package:mondori/screens/tutorial_screen.dart';

void main() {
  group('buildTutorialSteps - Structural invariants', () {
    final steps = buildTutorialSteps();

    test('Has exactly 4 steps (move, capture, convert, win condition)', () {
      expect(steps.length, 4);
      expect(steps.map((s) => s.actionType).toList(), [
        MoveType.move,
        MoveType.capture,
        MoveType.convert,
        MoveType.capture,
      ]);
    });

    test('Each step\'s board actually contains the referenced piece', () {
      for (final step in steps) {
        final board = step.buildBoard();
        final piece = board.pieces.values.firstWhere(
          (p) => p.id == step.pieceId,
          orElse: () => throw StateError(
            'Step "${step.title}" references pieceId "${step.pieceId}" '
            'which is not present on its own board',
          ),
        );
        expect(piece.seal, isNot(SealType.none),
            reason: 'The piece the player must act with should not be a none piece');
      }
    });

    test('Move steps target an empty square reachable by the piece\'s movement pattern', () {
      final moveStep = steps.firstWhere((s) => s.actionType == MoveType.move);
      final board = moveStep.buildBoard();
      final piece = board.pieces.values.firstWhere((p) => p.id == moveStep.pieceId);

      expect(board.getPieceAt(moveStep.targetPosition), isNull);
      expect(piece.getMovablePositions(), contains(moveStep.targetPosition));
    });

    test('Capture steps target an adjacent enemy piece', () {
      final captureSteps = steps.where((s) => s.actionType == MoveType.capture);
      expect(captureSteps, isNotEmpty);

      for (final step in captureSteps) {
        final board = step.buildBoard();
        final piece = board.pieces.values.firstWhere((p) => p.id == step.pieceId);
        final target = board.getPieceAt(step.targetPosition);

        expect(target, isNotNull);
        expect(target!.side, isNot(piece.side));
        expect(target.seal, isNot(SealType.none));
        expect(piece.position.getAdjacentPositions(), contains(step.targetPosition));
      }
    });

    test('The final step targets an enemy king (win-condition capture)', () {
      final finalStep = steps.last;
      final board = finalStep.buildBoard();
      final target = board.getPieceAt(finalStep.targetPosition);

      expect(finalStep.actionType, MoveType.capture);
      expect(target?.seal, SealType.king);
    });

    test('Convert steps target an adjacent friendly none piece', () {
      final convertStep = steps.firstWhere((s) => s.actionType == MoveType.convert);
      final board = convertStep.buildBoard();
      final piece = board.pieces.values.firstWhere((p) => p.id == convertStep.pieceId);
      final target = board.getPieceAt(convertStep.targetPosition);

      expect(target, isNotNull);
      expect(target!.side, piece.side);
      expect(target.seal, SealType.none);
      expect(piece.position.getAdjacentPositions(), contains(convertStep.targetPosition));
    });

    test('Every step has non-empty title, instruction, and hint text', () {
      for (final step in steps) {
        expect(step.title, isNotEmpty);
        expect(step.instruction, isNotEmpty);
        expect(step.hint, isNotEmpty);
      }
    });
  });
}
