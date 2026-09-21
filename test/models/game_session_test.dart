import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/models/game_session.dart';
import 'package:mondori/models/piece.dart';

void main() {
  group('GameSession - Creation', () {
    test('newSession creates a waiting session with one player', () {
      final session = GameSession.newSession(id: 's1', hostPlayerId: 'host-uid');

      expect(session.id, 's1');
      expect(session.playerIds, ['host-uid']);
      expect(session.status, GameSessionStatus.waiting);
      expect(session.currentPlayer, PlayerSide.A);
      expect(session.moveCount, 0);
      expect(session.isFull, false);
    });
  });

  group('GameSession - Side Resolution', () {
    test('Host resolves to PlayerSide.A', () {
      final session = GameSession.newSession(id: 's1', hostPlayerId: 'host-uid');
      expect(session.sideForPlayer('host-uid'), PlayerSide.A);
    });

    test('Guest resolves to PlayerSide.B after joining', () {
      final session = GameSession.newSession(id: 's1', hostPlayerId: 'host-uid')
          .copyWith(playerIds: ['host-uid', 'guest-uid']);

      expect(session.sideForPlayer('guest-uid'), PlayerSide.B);
      expect(session.isFull, true);
    });

    test('Unknown player resolves to null', () {
      final session = GameSession.newSession(id: 's1', hostPlayerId: 'host-uid');
      expect(session.sideForPlayer('unknown-uid'), isNull);
    });
  });

  group('GameSession - copyWith', () {
    test('Updates fields while preserving id and createdAt', () {
      final session = GameSession.newSession(id: 's1', hostPlayerId: 'host-uid');
      final updated = session.copyWith(
        status: GameSessionStatus.active,
        currentPlayer: PlayerSide.B,
        moveCount: 3,
      );

      expect(updated.id, session.id);
      expect(updated.createdAt, session.createdAt);
      expect(updated.status, GameSessionStatus.active);
      expect(updated.currentPlayer, PlayerSide.B);
      expect(updated.moveCount, 3);
    });
  });

  group('GameSession - Serialization', () {
    test('Round-trip JSON serialization preserves all fields', () {
      final session = GameSession.newSession(id: 's1', hostPlayerId: 'host-uid')
          .copyWith(
        playerIds: ['host-uid', 'guest-uid'],
        status: GameSessionStatus.active,
        moveCount: 5,
      );

      final json = session.toJson();
      final restored = GameSession.fromJson(json);

      expect(restored, session);
    });

    test('Serializes and restores winner field', () {
      final session = GameSession.newSession(id: 's1', hostPlayerId: 'host-uid')
          .copyWith(status: GameSessionStatus.finished, winner: PlayerSide.A);

      final json = session.toJson();
      final restored = GameSession.fromJson(json);

      expect(restored.winner, PlayerSide.A);
      expect(restored.status, GameSessionStatus.finished);
    });

    test('Handles null winner in JSON', () {
      final session = GameSession.newSession(id: 's1', hostPlayerId: 'host-uid');
      final json = session.toJson();

      expect(json['winner'], isNull);

      final restored = GameSession.fromJson(json);
      expect(restored.winner, isNull);
    });

    test('Board state survives serialization round-trip', () {
      final session = GameSession.newSession(id: 's1', hostPlayerId: 'host-uid');
      final json = session.toJson();
      final restored = GameSession.fromJson(json);

      expect(restored.board.pieces.length, session.board.pieces.length);
      for (final entry in session.board.pieces.entries) {
        expect(restored.board.getPieceAt(entry.key), entry.value);
      }
    });
  });
}
