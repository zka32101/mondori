import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mondori/models/board.dart';
import 'package:mondori/models/game_statistics.dart';
import 'package:mondori/models/piece.dart';
import 'package:mondori/providers/audio_provider.dart';
import 'package:mondori/screens/pie_rule_dialog.dart';
import 'package:mondori/services/audio_service.dart';
import 'package:mondori/services/statistics_service.dart';
import 'package:mondori/widgets/board_widget.dart';
import 'package:uuid/uuid.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {
  late Board board;
  late PlayerSide currentPlayer;
  Piece? selectedPiece;
  int moveCount = 0;
  String? lastAction;
  bool pieModeResolved = false;
  bool sidesSwitched = false;
  late AnimationController _boardRotationController;
  late Animation<double> _boardRotation;
  final _statisticsService = StatisticsService();
  final _uuid = const Uuid();
  DateTime _startedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    // _initializeGame() は _boardRotationController.reset() を呼ぶため、
    // 必ずコントローラ構築後に呼び出す（逆順だと LateInitializationError）。
    _boardRotationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _boardRotation = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _boardRotationController, curve: Curves.easeInOut),
    );
    _initializeGame();
  }

  @override
  void dispose() {
    _boardRotationController.dispose();
    super.dispose();
  }

  void _initializeGame() {
    board = Board.initialPlacement1();
    currentPlayer = PlayerSide.A;
    selectedPiece = null;
    moveCount = 0;
    lastAction = null;
    pieModeResolved = false;
    sidesSwitched = false;
    _startedAt = DateTime.now();
    _boardRotationController.reset();
  }

  /// ホットシート対戦の結果を統計に記録
  ///
  /// 両陣営とも同一端末のプレイヤーのため humanSide は null とし、
  /// 個人成績の集計対象からは除外する（履歴・リプレイの閲覧対象にはなる）。
  void _recordGameResult(PlayerSide winnerSide) {
    final stats = GameStatistics(
      gameId: _uuid.v4(),
      mode: GameMode.hotSeat,
      winner: winnerSide,
      turnCount: moveCount,
      duration: DateTime.now().difference(_startedAt),
      playedAt: DateTime.now(),
      moveHistory: const [],
    );
    _statisticsService.recordGameResult(stats);
  }

  void _selectPiece(Piece piece) {
    // 現在のプレイヤーの駒のみ選択可能
    if (piece.side == currentPlayer && piece.seal != SealType.none) {
      setState(() {
        selectedPiece = piece;
      });
      ref.read(audioServiceProvider).playSound(SoundEffect.pieceTap);
    }
  }

  void _movePiece(Position newPosition) async {
    if (selectedPiece == null) return;

    // 移動可能かチェック
    final movablePositions = selectedPiece!.getMovablePositions();
    if (!movablePositions.contains(newPosition)) return;

    // 移動先に駒がないか確認
    if (board.getPieceAt(newPosition) != null) return;

    setState(() {
      board = board.movePiece(selectedPiece!, newPosition);
      moveCount++;
      lastAction = 'プレイヤー${currentPlayer == PlayerSide.A ? 'A' : 'B'}が駒を移動しました';
      _switchTurn();
      selectedPiece = null;
    });
    ref.read(audioServiceProvider).playSound(SoundEffect.pieceMove);

    // パイルールチェック
    await _checkAndApplyPieRule();
  }

  void _capturePiece(Position targetPosition) {
    if (selectedPiece == null) return;

    final targetPiece = board.getPieceAt(targetPosition);
    if (targetPiece == null ||
        targetPiece.side == selectedPiece!.side ||
        targetPiece.seal == SealType.none) {
      // 無印駒（既に奪取済みの敵駒）は奪取対象にならない
      return;
    }

    // 隣接しているか確認
    final adjacent = selectedPiece!.position.getAdjacentPositions();
    if (!adjacent.contains(targetPosition)) return;

    final isKingCapture = targetPiece.seal == SealType.king;
    final capturingSide = selectedPiece!.side;

    setState(() {
      board = board.capturePiece(selectedPiece!, targetPiece);
      moveCount++;
      lastAction = 'プレイヤー${currentPlayer == PlayerSide.A ? 'A' : 'B'}が駒を奪取しました';
      _switchTurn();
      selectedPiece = null;
    });
    ref.read(audioServiceProvider).playSound(SoundEffect.capture);

    // 敵の王が奪取されたか確認（勝者は駒を奪取した側であり、手番交代後の
    // currentPlayer ではない点に注意）
    if (isKingCapture) {
      _showGameOverDialog(capturingSide);
    }
  }

  void _convertPiece(Position nonePiecePosition) {
    if (selectedPiece == null) return;

    final nonePiece = board.getPieceAt(nonePiecePosition);
    if (nonePiece == null || nonePiece.seal != SealType.none) return;

    // 隣接しているか確認
    final adjacent = selectedPiece!.position.getAdjacentPositions();
    if (!adjacent.contains(nonePiecePosition)) return;

    setState(() {
      board = board.convertPiece(selectedPiece!, nonePiece);
      moveCount++;
      lastAction = 'プレイヤー${currentPlayer == PlayerSide.A ? 'A' : 'B'}が駒を教化しました';
      _switchTurn();
      selectedPiece = null;
    });
    ref.read(audioServiceProvider).playSound(SoundEffect.convert);
  }

  void _switchTurn() {
    currentPlayer = currentPlayer == PlayerSide.A ? PlayerSide.B : PlayerSide.A;
  }

  /// パイルールチェック: 初手後にダイアログを表示
  Future<void> _checkAndApplyPieRule() async {
    if (pieModeResolved) return;
    if (moveCount != 1) return;

    pieModeResolved = true;
    ref.read(audioServiceProvider).playSound(SoundEffect.pieRule);

    // パイルールダイアログを表示
    final switchSides = await showPieRuleDialog(context);

    if (switchSides) {
      // 陣営交換
      setState(() {
        sidesSwitched = true;
        // プレイヤーを交換
        currentPlayer = currentPlayer == PlayerSide.A ? PlayerSide.B : PlayerSide.A;
        // 盤面をアニメーションで回転
        _boardRotationController.forward();
      });

      // アニメーション完了後、メッセージ表示
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('陣営が交換されました！盤面が 180° 回転します。'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showGameOverDialog(PlayerSide winnerSide) {
    _recordGameResult(winnerSide);
    ref.read(audioServiceProvider).playSound(SoundEffect.gameWon);

    final winner = winnerSide == PlayerSide.A ? 'A' : 'B';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ゲーム終了'),
        content: Text('プレイヤー$winnerが勝利しました！'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('ホームに戻る'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _initializeGame());
            },
            child: const Text('もう一度プレイ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('紋取り'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '戻る',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 現在のプレイヤー表示（アニメーション付き）
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Card(
                  key: ValueKey<PlayerSide>(currentPlayer),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          '現在のプレイヤー',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'プレイヤー${currentPlayer == PlayerSide.A ? 'A' : 'B'}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ゲーム統計情報
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'ターン数',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          Text(
                            '$moveCount',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '最後のアクション',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            Text(
                              lastAction ?? 'ゲーム開始',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // パイルール情報
              if (pieModeResolved)
                Card(
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Colors.amber.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            sidesSwitched
                                ? '🍰 パイルール適用: 陣営が交換されました'
                                : '🍰 パイルール: 交換なし',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.amber.shade900,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (pieModeResolved) const SizedBox(height: 24),

              // ゲーム盤（パイルール適用時は回転アニメーション）
              AnimatedBuilder(
                animation: _boardRotation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _boardRotation.value,
                    child: child,
                  );
                },
                child: BoardWidget(
                  board: board,
                  selectedPiece: selectedPiece,
                  onPieceSelected: _selectPiece,
                  onPositionTapped: (position) {
                    if (selectedPiece == null) return;

                    final targetPiece = board.getPieceAt(position);

                    // 移動か奪取か教化かを判定
                    if (targetPiece == null) {
                      // 空マス：移動か教化
                      _movePiece(position);
                    } else if (targetPiece.side != selectedPiece!.side) {
                      // 敵駒：奪取
                      _capturePiece(position);
                    } else if (targetPiece.seal == SealType.none) {
                      // 自陣の無印駒：教化
                      _convertPiece(position);
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),

              // アクションボタン
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selectedPiece != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilledButton.tonal(
                        onPressed: () => setState(() => selectedPiece = null),
                        child: const Text('選択を解除'),
                      ),
                    ),
                  FilledButton.tonal(
                    onPressed: () => setState(() => _initializeGame()),
                    child: const Text('ゲームをリセット'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
