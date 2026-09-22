import 'package:flutter/material.dart';
import 'package:mondori/models/board.dart';
import 'package:mondori/models/game_statistics.dart';
import 'package:mondori/models/move.dart';
import 'package:mondori/widgets/board_widget.dart';

/// 過去のゲームを1手ずつ再生するリプレイ画面
class ReplayScreen extends StatefulWidget {
  final GameStatistics game;

  const ReplayScreen({Key? key, required this.game}) : super(key: key);

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen> {
  late List<Board> _boardSnapshots;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _boardSnapshots = _buildSnapshots(widget.game.moveHistory);
  }

  /// 初期配置から各手を順に適用し、各時点の盤面スナップショットを生成
  List<Board> _buildSnapshots(List<Move> moveHistory) {
    final snapshots = <Board>[Board.initialPlacement1()];
    var board = snapshots.first;

    for (final move in moveHistory) {
      switch (move.type) {
        case MoveType.move:
          board = board.movePiece(move.piece, move.toPosition);
          break;
        case MoveType.capture:
          final targetPiece = board.getPieceAt(move.toPosition);
          if (targetPiece != null) {
            board = board.capturePiece(move.piece, targetPiece);
          }
          break;
        case MoveType.convert:
          final targetPiece = board.getPieceAt(move.toPosition);
          if (targetPiece != null) {
            board = board.convertPiece(move.piece, targetPiece);
          }
          break;
      }
      snapshots.add(board);
    }

    return snapshots;
  }

  @override
  Widget build(BuildContext context) {
    final totalSteps = _boardSnapshots.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('リプレイ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '戻る',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '手 $_currentStep / $totalSteps'
              '${_currentStep == 0 ? '（初期配置）' : ''}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: BoardWidget(
                board: _boardSnapshots[_currentStep],
                selectedPiece: null,
                onPieceSelected: (_) {},
                onPositionTapped: (_) {},
              ),
            ),
          ),
          if (_currentStep > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.game.moveHistory[_currentStep - 1].toString(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.first_page),
                  tooltip: '最初の手に戻る',
                  onPressed: _currentStep > 0 ? () => setState(() => _currentStep = 0) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: '1手戻る',
                  onPressed:
                      _currentStep > 0 ? () => setState(() => _currentStep--) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: '1手進む',
                  onPressed: _currentStep < totalSteps
                      ? () => setState(() => _currentStep++)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.last_page),
                  tooltip: '最後の手まで進む',
                  onPressed: _currentStep < totalSteps
                      ? () => setState(() => _currentStep = totalSteps)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
