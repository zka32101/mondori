import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mondori/models/piece.dart';
import 'package:mondori/providers/online_game_provider.dart';
import 'package:mondori/widgets/board_widget.dart';

/// オンライン対戦画面
class OnlineGameScreen extends ConsumerStatefulWidget {
  final String playerId;

  const OnlineGameScreen({Key? key, required this.playerId}) : super(key: key);

  @override
  ConsumerState<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends ConsumerState<OnlineGameScreen> {
  Piece? selectedPiece;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onlineGameStateProvider);
    final session = state.session;

    return Scaffold(
      appBar: AppBar(
        title: const Text('オンライン対戦'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '戻る',
          onPressed: () async {
            await ref.read(onlineGameStateProvider.notifier).leaveSession();
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
      body: session == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatsPanel(state, session.moveCount),
                Expanded(
                  child: Center(
                    child: session.status.name == 'finished'
                        ? _buildGameOverScreen(state)
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: BoardWidget(
                              board: session.board,
                              selectedPiece: selectedPiece,
                              onPieceSelected: (piece) {
                                if (!state.isMyTurn) return;
                                if (piece.side == state.mySide &&
                                    piece.seal != SealType.none) {
                                  setState(() {
                                    selectedPiece =
                                        selectedPiece?.id == piece.id ? null : piece;
                                  });
                                }
                              },
                              onPositionTapped: (position) {
                                if (!state.isMyTurn || selectedPiece == null) return;
                                ref
                                    .read(onlineGameStateProvider.notifier)
                                    .makeMove(selectedPiece!, position);
                                setState(() {
                                  selectedPiece = null;
                                });
                              },
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsPanel(OnlineGameState state, int moveCount) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('ターン: $moveCount', style: Theme.of(context).textTheme.titleMedium),
          Text(
            state.isMyTurn ? 'あなたのターン' : '相手のターン',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: state.isMyTurn ? Colors.blue : Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverScreen(OnlineGameState state) {
    final session = state.session!;
    final isWinner = session.winner == state.mySide;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isWinner ? 'あなたの勝利！' : '相手の勝利',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: isWinner ? Colors.green : Colors.red,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await ref.read(onlineGameStateProvider.notifier).leaveSession();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('ロビーに戻る'),
          ),
        ],
      ),
    );
  }
}
