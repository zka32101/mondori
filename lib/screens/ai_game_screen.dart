import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mondori/ai/ai_engine.dart';
import 'package:mondori/models/piece.dart';
import 'package:mondori/providers/ai_game_provider.dart';
import 'package:mondori/widgets/board_widget.dart';

/// AI 対戦ゲーム画面
class AIGameScreen extends ConsumerStatefulWidget {
  final AIDifficulty difficulty;
  final PlayerSide? humanPlayer;

  const AIGameScreen({
    Key? key,
    this.difficulty = AIDifficulty.normal,
    this.humanPlayer,
  }) : super(key: key);

  @override
  ConsumerState<AIGameScreen> createState() => _AIGameScreenState();
}

class _AIGameScreenState extends ConsumerState<AIGameScreen> {
  Piece? selectedPiece;

  @override
  void initState() {
    super.initState();
    // ゲーム状態は最初のフレーム後に一度だけ初期化する
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiGameStateProvider.notifier).initGame(
            widget.difficulty,
            humanPlayer: widget.humanPlayer ?? PlayerSide.A,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(aiGameStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('AI対戦 (${widget.difficulty.label})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 統計情報パネル
          _buildStatsPanel(gameState),

          // ゲームボード
          Expanded(
            child: Center(
              child: gameState.gameOver
                  ? _buildGameOverScreen(gameState)
                  : _buildGameBoard(gameState),
            ),
          ),
        ],
      ),
    );
  }

  /// 統計情報パネル
  Widget _buildStatsPanel(AIGameState gameState) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ターン: ${gameState.moveCount}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                gameState.isAIThinking
                    ? 'AI 考え中...'
                    : gameState.isHumanTurn
                        ? 'あなたのターン'
                        : 'AI のターン',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: gameState.isAIThinking
                      ? Colors.orange
                      : gameState.isHumanTurn
                          ? Colors.blue
                          : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '最後のアクション: ${gameState.lastAction}',
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// ゲームボード
  Widget _buildGameBoard(AIGameState gameState) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPiece = null;
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ボード
            Expanded(
              child: BoardWidget(
                board: gameState.board,
                selectedPiece: selectedPiece,
                onPieceSelected: (piece) {
                  if (!gameState.isHumanTurn || gameState.isAIThinking) return;
                  if (piece.side == gameState.humanPlayer &&
                      piece.seal != SealType.none) {
                    setState(() {
                      selectedPiece =
                          selectedPiece?.id == piece.id ? null : piece;
                    });
                  }
                },
                onPositionTapped: (position) {
                  if (!gameState.isHumanTurn || gameState.isAIThinking) return;
                  if (selectedPiece != null &&
                      selectedPiece!.side == gameState.humanPlayer) {
                    ref
                        .read(aiGameStateProvider.notifier)
                        .makeHumanMove(selectedPiece!, position);
                    setState(() {
                      selectedPiece = null;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 24),

            // ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('ゲームをリセット'),
                  onPressed: () {
                    ref.read(aiGameStateProvider.notifier).resetGame();
                    setState(() {
                      selectedPiece = null;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ゲーム終了画面
  Widget _buildGameOverScreen(AIGameState gameState) {
    final isHumanWon = gameState.winner == gameState.humanPlayer;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isHumanWon ? 'あなたの勝利！' : 'AI の勝利',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: isHumanWon ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ターン数: ${gameState.moveCount}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              ref.read(aiGameStateProvider.notifier).resetGame();
              setState(() {
                selectedPiece = null;
              });
            },
            child: const Text('もう一度プレイ'),
          ),
        ],
      ),
    );
  }
}
