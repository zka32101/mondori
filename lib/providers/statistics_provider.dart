import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mondori/models/game_statistics.dart';
import 'package:mondori/models/player_stats.dart';
import 'package:mondori/services/statistics_service.dart';

final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  return StatisticsService();
});

/// ゲーム履歴の状態管理
final gameHistoryProvider =
    StateNotifierProvider<GameHistoryNotifier, AsyncValue<List<GameStatistics>>>(
        (ref) {
  return GameHistoryNotifier(ref.read(statisticsServiceProvider));
});

class GameHistoryNotifier extends StateNotifier<AsyncValue<List<GameStatistics>>> {
  final StatisticsService _service;

  GameHistoryNotifier(this._service) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final history = await _service.getGameHistory();
      state = AsyncValue.data(history);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> recordGameResult(GameStatistics stats) async {
    await _service.recordGameResult(stats);
    await refresh();
  }

  Future<void> clearHistory() async {
    await _service.clearHistory();
    await refresh();
  }
}

/// 現在の履歴から算出したプレイヤー成績
final playerStatsProvider = Provider<PlayerStats>((ref) {
  final history = ref.watch(gameHistoryProvider);
  return history.when(
    data: (data) => PlayerStats.fromHistory(data),
    loading: () => PlayerStats.empty(),
    error: (_, __) => PlayerStats.empty(),
  );
});
