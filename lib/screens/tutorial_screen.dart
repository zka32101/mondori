import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mondori/models/board.dart';
import 'package:mondori/models/move.dart';
import 'package:mondori/models/piece.dart';
import 'package:mondori/providers/audio_provider.dart';
import 'package:mondori/services/audio_service.dart';
import 'package:mondori/widgets/board_widget.dart';

/// チュートリアルの1ステップ
///
/// 各ステップは独立した小さな盤面シナリオを持ち、指定した駒で指定した
/// 位置に対して指定したアクション（移動・奪取・教化）を行うと次のステップへ
/// 進む。
class TutorialStep {
  final String title;
  final String instruction;
  final Board Function() buildBoard;
  final String pieceId;
  final Position targetPosition;
  final MoveType actionType;
  final String hint;

  const TutorialStep({
    required this.title,
    required this.instruction,
    required this.buildBoard,
    required this.pieceId,
    required this.targetPosition,
    required this.actionType,
    required this.hint,
  });
}

/// チュートリアルの全ステップを構築する（テストからも参照するため公開）。
List<TutorialStep> buildTutorialSteps() {
  return [
    // ステップ1：移動
    TutorialStep(
      title: '① 移動',
      instruction:
          '駒には「本体」と「刻印（能力）」があります。「進」は前方1マスだけ移動できます。\n\n'
          'まずは c3 の駒をタップして選択し、c4 をタップして移動させましょう。',
      buildBoard: () => Board(pieces: {
        Position(column: 'c', row: 3): Piece(
          id: 'tutorial-piece',
          side: PlayerSide.A,
          seal: SealType.advance,
          position: Position(column: 'c', row: 3),
        ),
      }),
      pieceId: 'tutorial-piece',
      targetPosition: Position(column: 'c', row: 4),
      actionType: MoveType.move,
      hint: 'c3 の駒をタップしてから c4 をタップしてください',
    ),

    // ステップ2：奪取
    TutorialStep(
      title: '② 奪取',
      instruction:
          '「奪取」は隣接する敵駒に対して行うアクションで、移動を伴いません。\n\n'
          '駒の移動パターンとは無関係に、8方向どこでも隣接していれば奪取できます。\n\n'
          'c3 の駒を選択し、隣の d3 にいる敵駒を奪取してみましょう。',
      buildBoard: () => Board(pieces: {
        Position(column: 'c', row: 3): Piece(
          id: 'tutorial-piece',
          side: PlayerSide.A,
          seal: SealType.counter,
          position: Position(column: 'c', row: 3),
        ),
        Position(column: 'd', row: 3): Piece(
          id: 'enemy-piece',
          side: PlayerSide.B,
          seal: SealType.advance,
          position: Position(column: 'd', row: 3),
        ),
      }),
      pieceId: 'tutorial-piece',
      targetPosition: Position(column: 'd', row: 3),
      actionType: MoveType.capture,
      hint: 'c3 の駒を選択してから、隣の敵駒（d3）をタップしてください',
    ),

    // ステップ3：教化
    TutorialStep(
      title: '③ 教化',
      instruction:
          '「教化」は隣接する自陣の無印駒（奪取されて能力を失った駒）に、\n'
          '自分の刻印をコピーして復活させるアクションです。\n\n'
          'c3 の駒を選択し、隣の無印駒（d3）を教化してみましょう。',
      buildBoard: () => Board(pieces: {
        Position(column: 'c', row: 3): Piece(
          id: 'tutorial-piece',
          side: PlayerSide.A,
          seal: SealType.swift,
          position: Position(column: 'c', row: 3),
        ),
        Position(column: 'd', row: 3): Piece(
          id: 'none-piece',
          side: PlayerSide.A,
          seal: SealType.none,
          position: Position(column: 'd', row: 3),
        ),
      }),
      pieceId: 'tutorial-piece',
      targetPosition: Position(column: 'd', row: 3),
      actionType: MoveType.convert,
      hint: 'c3 の駒を選択してから、隣の無印駒（d3）をタップしてください',
    ),

    // ステップ4：勝利条件
    TutorialStep(
      title: '④ 勝利条件',
      instruction:
          '相手の「王」刻印を奪取すれば、あなたの勝利です！\n\n'
          '最後の練習として、隣にいる敵の王を奪取してみましょう。',
      buildBoard: () => Board(pieces: {
        Position(column: 'c', row: 3): Piece(
          id: 'tutorial-piece',
          side: PlayerSide.A,
          seal: SealType.counter,
          position: Position(column: 'c', row: 3),
        ),
        Position(column: 'd', row: 3): Piece(
          id: 'enemy-king',
          side: PlayerSide.B,
          seal: SealType.king,
          position: Position(column: 'd', row: 3),
        ),
      }),
      pieceId: 'tutorial-piece',
      targetPosition: Position(column: 'd', row: 3),
      actionType: MoveType.capture,
      hint: 'c3 の駒を選択してから、隣の敵の王（d3）をタップしてください',
    ),
  ];
}

/// チュートリアル（遊び方ガイド）画面
class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  late final List<TutorialStep> _steps;
  int _stepIndex = 0;
  late Board _board;
  Piece? _selectedPiece;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _steps = buildTutorialSteps();
    _board = _steps[0].buildBoard();
  }

  TutorialStep get _currentStep => _steps[_stepIndex];

  void _showHint(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _onPieceSelected(Piece piece) {
    if (piece.id != _currentStep.pieceId) {
      _showHint(_currentStep.hint);
      return;
    }
    setState(() => _selectedPiece = piece);
    ref.read(audioServiceProvider).playSound(SoundEffect.pieceTap);
  }

  void _onPositionTapped(Position position) {
    if (_selectedPiece == null) return;

    final step = _currentStep;
    if (position != step.targetPosition) {
      _showHint(step.hint);
      return;
    }

    // 正解：ステップ完了
    ref.read(audioServiceProvider).playSound(SoundEffect.capture);
    _advanceStep();
  }

  void _advanceStep() {
    if (_stepIndex >= _steps.length - 1) {
      setState(() {
        _completed = true;
        _selectedPiece = null;
      });
      ref.read(audioServiceProvider).playSound(SoundEffect.gameWon);
      return;
    }

    setState(() {
      _stepIndex++;
      _board = _steps[_stepIndex].buildBoard();
      _selectedPiece = null;
    });
  }

  void _skipToStep(int index) {
    setState(() {
      _stepIndex = index;
      _board = _steps[index].buildBoard();
      _selectedPiece = null;
      _completed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('遊び方チュートリアル'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('スキップ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _completed ? _buildCompletionView() : _buildStepView(),
    );
  }

  Widget _buildStepView() {
    final step = _currentStep;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_stepIndex + 1) / _steps.length,
          ),
          const SizedBox(height: 16),
          Text(step.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(step.instruction),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BoardWidget(
              board: _board,
              selectedPiece: _selectedPiece,
              onPieceSelected: _onPieceSelected,
              onPositionTapped: _onPositionTapped,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _stepIndex > 0 ? () => _skipToStep(_stepIndex - 1) : null,
                child: const Text('戻る'),
              ),
              Text('${_stepIndex + 1} / ${_steps.length}'),
              TextButton(
                onPressed: () => _skipToStep(_stepIndex),
                child: const Text('やり直す'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 72, color: Colors.amber),
            const SizedBox(height: 24),
            Text(
              'チュートリアル完了！',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              '移動・奪取・教化のルールを学びました。\nそれでは実際に対戦してみましょう！',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ホームに戻る'),
            ),
          ],
        ),
      ),
    );
  }
}
