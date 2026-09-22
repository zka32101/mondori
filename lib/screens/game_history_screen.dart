import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mondori/models/game_statistics.dart';
import 'package:mondori/models/piece.dart';
import 'package:mondori/providers/statistics_provider.dart';
import 'package:mondori/screens/replay_screen.dart';

/// 対戦履歴一覧画面
class GameHistoryScreen extends ConsumerWidget {
  const GameHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(gameHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('対戦履歴'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '戻る',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return const Center(child: Text('対戦履歴がありません'));
          }

          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) => _HistoryTile(game: history[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('読み込みエラー: $e')),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final GameStatistics game;

  const _HistoryTile({required this.game});

  @override
  Widget build(BuildContext context) {
    final resultLabel = game.winner == null
        ? '引き分け・中断'
        : game.humanSide != null
            ? (game.didHumanWin ? '勝利' : '敗北')
            : 'プレイヤー${game.winner == PlayerSide.A ? 'A' : 'B'}の勝利';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _modeColor(game.mode).withOpacity(0.15),
        child: Icon(_modeIcon(game.mode), color: _modeColor(game.mode)),
      ),
      title: Text('${_modeLabel(game.mode)} - $resultLabel'),
      subtitle: Text(
        'ターン数: ${game.turnCount}  '
        '${_formatDate(game.playedAt)}'
        '${game.difficulty != null ? '  難度: ${game.difficulty!.label}' : ''}',
      ),
      trailing: game.hasReplay ? const Icon(Icons.play_circle_outline) : null,
      onTap: game.hasReplay
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ReplayScreen(game: game)),
              );
            }
          : null,
    );
  }

  String _modeLabel(GameMode mode) {
    switch (mode) {
      case GameMode.hotSeat:
        return 'ホットシート';
      case GameMode.ai:
        return 'AI対戦';
      case GameMode.online:
        return 'オンライン対戦';
    }
  }

  IconData _modeIcon(GameMode mode) {
    switch (mode) {
      case GameMode.hotSeat:
        return Icons.people;
      case GameMode.ai:
        return Icons.android;
      case GameMode.online:
        return Icons.cloud;
    }
  }

  Color _modeColor(GameMode mode) {
    switch (mode) {
      case GameMode.hotSeat:
        return Colors.blue;
      case GameMode.ai:
        return Colors.deepPurple;
      case GameMode.online:
        return Colors.teal;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
