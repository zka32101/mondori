import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mondori/ai/ai_engine.dart';
import 'package:mondori/models/player_stats.dart';
import 'package:mondori/providers/statistics_provider.dart';
import 'package:mondori/screens/game_history_screen.dart';

/// 個人成績ダッシュボード画面
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(gameHistoryProvider);
    final stats = ref.watch(playerStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('統計・履歴'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '対戦履歴を見る',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GameHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: historyAsync.when(
        data: (_) => _buildStatsBody(context, ref, stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('読み込みエラー: $e')),
      ),
    );
  }

  Widget _buildStatsBody(BuildContext context, WidgetRef ref, PlayerStats stats) {
    if (stats.totalGames == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bar_chart, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'まだ AI 対戦・オンライン対戦の記録がありません',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'ホットシート対戦は履歴に記録されますが、\n個人成績には反映されません',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummaryCard(context, stats),
          const SizedBox(height: 16),
          _buildDifficultyBreakdown(context, stats),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('履歴をすべて削除'),
            onPressed: () => _confirmClearHistory(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, PlayerStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('総合成績', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatTile(label: '対戦数', value: '${stats.totalGames}'),
                _StatTile(label: '勝利', value: '${stats.wins}', color: Colors.green),
                _StatTile(label: '敗北', value: '${stats.losses}', color: Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: stats.winRate,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text('勝率: ${(stats.winRate * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            Text('平均ターン数: ${stats.averageTurnCount.toStringAsFixed(1)}'),
            Text('平均対戦時間: ${_formatDuration(stats.averageDuration)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyBreakdown(BuildContext context, PlayerStats stats) {
    if (stats.gamesByDifficulty.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI 難度別成績', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final difficulty in AIDifficulty.values)
              if (stats.gamesByDifficulty.containsKey(difficulty))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(difficulty.label),
                      Text(
                        '${stats.winsByDifficulty[difficulty] ?? 0} / '
                        '${stats.gamesByDifficulty[difficulty]} 勝 '
                        '(${(stats.winRateForDifficulty(difficulty) * 100).toStringAsFixed(0)}%)',
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  void _confirmClearHistory(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('履歴を削除しますか？'),
        content: const Text('すべての対戦履歴と統計が削除されます。この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              ref.read(gameHistoryProvider.notifier).clearHistory();
              Navigator.pop(context);
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes分$seconds秒';
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatTile({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
