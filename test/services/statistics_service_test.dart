import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/models/game_statistics.dart';
import 'package:mondori/models/piece.dart';
import 'package:mondori/services/statistics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GameStatistics sampleGame(String id, {DateTime? playedAt}) {
    return GameStatistics(
      gameId: id,
      mode: GameMode.ai,
      winner: PlayerSide.A,
      humanSide: PlayerSide.A,
      turnCount: 10,
      duration: const Duration(minutes: 2),
      playedAt: playedAt ?? DateTime(2026, 1, 1),
      moveHistory: const [],
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StatisticsService - recordGameResult / getGameHistory', () {
    test('Returns empty list when nothing recorded', () async {
      final service = StatisticsService();
      final history = await service.getGameHistory();
      expect(history, isEmpty);
    });

    test('Recorded game appears in history', () async {
      final service = StatisticsService();
      await service.recordGameResult(sampleGame('g1'));

      final history = await service.getGameHistory();
      expect(history.length, 1);
      expect(history.first.gameId, 'g1');
    });

    test('New games are prepended (most recent first)', () async {
      final service = StatisticsService();
      await service.recordGameResult(sampleGame('g1'));
      await service.recordGameResult(sampleGame('g2'));

      final history = await service.getGameHistory();
      expect(history.length, 2);
      expect(history.first.gameId, 'g2');
      expect(history.last.gameId, 'g1');
    });

    test('Filters history by GameMode', () async {
      final service = StatisticsService();
      await service.recordGameResult(sampleGame('g1'));
      await service.recordGameResult(
        GameStatistics(
          gameId: 'g2',
          mode: GameMode.hotSeat,
          winner: PlayerSide.B,
          turnCount: 4,
          duration: const Duration(minutes: 1),
          playedAt: DateTime(2026, 1, 1),
          moveHistory: const [],
        ),
      );

      final aiOnly = await service.getGameHistory(filterMode: GameMode.ai);
      expect(aiOnly.length, 1);
      expect(aiOnly.first.gameId, 'g1');

      final hotSeatOnly = await service.getGameHistory(filterMode: GameMode.hotSeat);
      expect(hotSeatOnly.length, 1);
      expect(hotSeatOnly.first.gameId, 'g2');
    });

    test('History is capped at maxHistorySize', () async {
      final service = StatisticsService();

      for (var i = 0; i < StatisticsService.maxHistorySize + 10; i++) {
        await service.recordGameResult(sampleGame('g$i'));
      }

      final history = await service.getGameHistory();
      expect(history.length, StatisticsService.maxHistorySize);
      // 最新のものが残っているはず
      expect(history.first.gameId, 'g${StatisticsService.maxHistorySize + 9}');
    });
  });

  group('StatisticsService - clearHistory', () {
    test('Removes all recorded games', () async {
      final service = StatisticsService();
      await service.recordGameResult(sampleGame('g1'));
      await service.clearHistory();

      final history = await service.getGameHistory();
      expect(history, isEmpty);
    });
  });
}
