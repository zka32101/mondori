import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/models/game_statistics.dart';
import 'package:mondori/models/piece.dart';
import 'package:mondori/providers/statistics_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  GameStatistics sampleGame(String id, {PlayerSide? winner, PlayerSide? humanSide}) {
    return GameStatistics(
      gameId: id,
      mode: GameMode.ai,
      winner: winner ?? PlayerSide.A,
      humanSide: humanSide ?? PlayerSide.A,
      turnCount: 10,
      duration: const Duration(minutes: 2),
      playedAt: DateTime(2026, 1, 1),
      moveHistory: const [],
    );
  }

  group('gameHistoryProvider', () {
    test('Starts empty and loads asynchronously', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 初回はローディング中の可能性がある
      await Future<void>.delayed(Duration.zero);

      final state = container.read(gameHistoryProvider);
      expect(state, isA<AsyncData<List<GameStatistics>>>());
      expect(state.value, isEmpty);
    });

    test('recordGameResult adds to history and updates state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(gameHistoryProvider.notifier).recordGameResult(
            sampleGame('g1'),
          );

      final state = container.read(gameHistoryProvider);
      expect(state.value?.length, 1);
      expect(state.value?.first.gameId, 'g1');
    });

    test('clearHistory empties the state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(gameHistoryProvider.notifier).recordGameResult(
            sampleGame('g1'),
          );
      await container.read(gameHistoryProvider.notifier).clearHistory();

      final state = container.read(gameHistoryProvider);
      expect(state.value, isEmpty);
    });
  });

  group('playerStatsProvider', () {
    test('Reflects recorded AI game results', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(gameHistoryProvider.notifier).recordGameResult(
            sampleGame('g1', winner: PlayerSide.A, humanSide: PlayerSide.A),
          );
      await container.read(gameHistoryProvider.notifier).recordGameResult(
            sampleGame('g2', winner: PlayerSide.B, humanSide: PlayerSide.A),
          );

      final stats = container.read(playerStatsProvider);
      expect(stats.totalGames, 2);
      expect(stats.wins, 1);
      expect(stats.losses, 1);
    });

    test('Empty history yields empty PlayerStats', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await Future<void>.delayed(Duration.zero);

      final stats = container.read(playerStatsProvider);
      expect(stats.totalGames, 0);
    });
  });
}
