import 'package:flutter/material.dart';
import 'package:mondori/models/board.dart';
import 'package:mondori/models/piece.dart';

/// スクリーンリーダー向けにセルの内容を説明するラベルを構築する。
String _buildCellSemanticLabel({
  required Position position,
  required Piece? piece,
  required bool isSelected,
  required bool isMovable,
  required bool isCaptureable,
  required bool isConvertible,
}) {
  final buffer = StringBuffer('$position');

  if (piece == null) {
    buffer.write('、空きマス');
  } else if (piece.seal == SealType.none) {
    final sideLabel = piece.side == PlayerSide.A ? '自陣' : '相手陣';
    buffer.write('、$sideLabel の無印駒');
  } else {
    final sideLabel = piece.side == PlayerSide.A ? '自分' : '相手';
    buffer.write('、$sideLabel の${_sealSemanticName(piece.seal)}');
  }

  if (isSelected) buffer.write('、選択中');
  if (isMovable) buffer.write('、移動可能');
  if (isCaptureable) buffer.write('、奪取可能');
  if (isConvertible) buffer.write('、教化可能');

  return buffer.toString();
}

String _sealSemanticName(SealType seal) {
  switch (seal) {
    case SealType.advance:
      return '進';
    case SealType.swift:
      return '早';
    case SealType.counter:
      return '対';
    case SealType.king:
      return '王';
    case SealType.none:
      return '無印駒';
  }
}

class BoardWidget extends StatefulWidget {
  final Board board;
  final Piece? selectedPiece;
  final Function(Piece) onPieceSelected;
  final Function(Position) onPositionTapped;

  const BoardWidget({
    Key? key,
    required this.board,
    required this.selectedPiece,
    required this.onPieceSelected,
    required this.onPositionTapped,
  }) : super(key: key);

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const columns = ['a', 'b', 'c', 'd', 'e', 'f'];
    const rows = [6, 5, 4, 3, 2, 1];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: AspectRatio(
        aspectRatio: 1,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // 列ラベル
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: columns
                        .map((col) => SizedBox(
                      width: 48,
                      child: Center(
                        child: Text(
                          col,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 4),
                // ゲーム盤
                Expanded(
                  child: Row(
                    children: [
                      // 行ラベル
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: rows
                            .map((row) => SizedBox(
                          height: 48,
                          child: Center(
                            child: Text(
                              '$row',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ))
                            .toList(),
                      ),
                      const SizedBox(width: 8),
                      // グリッド
                      Expanded(
                        child: GridView.builder(
                          padding: EdgeInsets.zero,
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                          ),
                          itemCount: 36,
                          itemBuilder: (context, index) {
                            final col = index % 6;
                            final row = index ~/ 6;
                            final column = columns[col];
                            final rowNum = rows[row];
                            final position = Position(
                              column: column,
                              row: rowNum,
                            );

                            final piece = widget.board.getPieceAt(position);
                            final isSelected = widget.selectedPiece?.position == position;
                            final isMovable = widget.selectedPiece != null &&
                                widget.selectedPiece!.getMovablePositions()
                                    .contains(position) &&
                                piece == null;
                            final isCaptureable = widget.selectedPiece != null &&
                                widget.selectedPiece!.position
                                    .getAdjacentPositions()
                                    .contains(position) &&
                                piece != null &&
                                piece.side != widget.selectedPiece!.side;
                            final isConvertible = widget.selectedPiece != null &&
                                widget.selectedPiece!.position
                                    .getAdjacentPositions()
                                    .contains(position) &&
                                piece != null &&
                                piece.side == widget.selectedPiece!.side &&
                                piece.seal == SealType.none;

                            void handleTap() {
                              // 有効な駒（無印以外）で、かつ「まだ何も選択していない」
                              // か「自陣の別の駒を選び直す」場合のみ選択として扱う。
                              // それ以外（空マス・無印駒・選択中に敵の有効駒をタップ）
                              // は onPositionTapped に委譲し、移動/奪取/教化の判定は
                              // 呼び出し側（各画面の onPositionTapped 実装）に任せる。
                              // これにより敵駒への奪取アクションがタップで実行できる。
                              final isSelectable =
                                  piece != null && piece.seal != SealType.none;
                              final isReselectingOwnPiece = isSelectable &&
                                  widget.selectedPiece != null &&
                                  piece.side == widget.selectedPiece!.side;

                              if (isSelectable &&
                                  (widget.selectedPiece == null ||
                                      isReselectingOwnPiece)) {
                                widget.onPieceSelected(piece);
                              } else {
                                widget.onPositionTapped(position);
                              }
                            }

                            return Semantics(
                              label: _buildCellSemanticLabel(
                                position: position,
                                piece: piece,
                                isSelected: isSelected,
                                isMovable: isMovable,
                                isCaptureable: isCaptureable,
                                isConvertible: isConvertible,
                              ),
                              button: true,
                              selected: isSelected,
                              // 子（_PieceWidget 内の刻印テキストなど）が持つ
                              // 個別のセマンティクスを隠し、このセルのラベル1つに
                              // まとめる（二重読み上げの防止）。
                              excludeSemantics: true,
                              // GestureDetector.onTap 単体はセマンティクスツリーに
                              // タップ操作を公開しないため、スクリーンリーダーの
                              // 「ダブルタップで実行」に対応させるには Semantics
                              // 側にも同じ処理を渡す必要がある。
                              onTap: handleTap,
                              child: GestureDetector(
                                onTap: handleTap,
                                child: ScaleTransition(
                                  scale: isMovable ? _pulseAnimation : AlwaysStoppedAnimation(1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _getCellColor(
                                        isSelected,
                                        isMovable,
                                        isCaptureable,
                                        isConvertible,
                                      ),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: piece != null
                                        ? _PieceWidget(
                                      piece: piece,
                                      isSelected: isSelected,
                                    )
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCellColor(
    bool isSelected,
    bool isMovable,
    bool isCaptureable,
    bool isConvertible,
  ) {
    if (isSelected) {
      return Colors.blue.shade200;
    } else if (isMovable) {
      return Colors.green.shade100;
    } else if (isCaptureable) {
      return Colors.red.shade100;
    } else if (isConvertible) {
      return Colors.amber.shade100;
    }
    return Colors.white;
  }
}

class _PieceWidget extends StatefulWidget {
  final Piece piece;
  final bool isSelected;

  const _PieceWidget({
    required this.piece,
    required this.isSelected,
  });

  @override
  State<_PieceWidget> createState() => _PieceWidgetState();
}

class _PieceWidgetState extends State<_PieceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    if (widget.isSelected) {
      _scaleController.forward();
    }
  }

  @override
  void didUpdateWidget(_PieceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _scaleController.forward();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _scaleController.reverse();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.piece.side == PlayerSide.A
              ? Colors.deepPurple
              : Colors.orange,
          border: widget.isSelected
              ? Border.all(
                  color: Colors.blue,
                  width: 4,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: (widget.piece.side == PlayerSide.A
                      ? Colors.deepPurple
                      : Colors.orange)
                  .withOpacity(widget.isSelected ? 0.6 : 0.3),
              blurRadius: widget.isSelected ? 12 : 4,
              spreadRadius: widget.isSelected ? 2 : 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getSealLabel(widget.piece.seal),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSealLabel(SealType seal) {
    switch (seal) {
      case SealType.advance:
        return '進';
      case SealType.swift:
        return '早';
      case SealType.counter:
        return '対';
      case SealType.king:
        return '王';
      case SealType.none:
        return '';
    }
  }
}
