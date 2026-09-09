import 'package:equatable/equatable.dart';

/// 刻印（能力）の種類
enum SealType {
  /// 進（しん）：前方1マスのみ
  advance,

  /// 早（そう）：縦横1～2マス
  swift,

  /// 対（たい）：斜め1マス
  counter,

  /// 王（おう）：全8方向1マス
  king,

  /// 無印：移動不可（奪取された駒）
  none,
}

/// プレイヤーの陣営
enum PlayerSide { A, B }

/// 盤上の位置（a-f, 1-6）
class Position extends Equatable {
  final String column; // 'a' to 'f'
  final int row; // 1 to 6

  const Position({
    required this.column,
    required this.row,
  });

  /// 位置の妥当性を検証
  bool isValid() {
    return column.length == 1 &&
        column.codeUnitAt(0) >= 'a'.codeUnitAt(0) &&
        column.codeUnitAt(0) <= 'f'.codeUnitAt(0) &&
        row >= 1 &&
        row <= 6;
  }

  /// 8方向の隣接位置を取得
  List<Position> getAdjacentPositions() {
    final adjacent = <Position>[];
    final dx = [-1, -1, -1, 0, 0, 1, 1, 1];
    final dy = [-1, 0, 1, -1, 1, -1, 0, 1];
    final colValue = column.codeUnitAt(0);

    for (int i = 0; i < 8; i++) {
      final newCol = String.fromCharCode(colValue + dx[i]);
      final newRow = row + dy[i];
      final newPos = Position(column: newCol, row: newRow);
      if (newPos.isValid()) {
        adjacent.add(newPos);
      }
    }
    return adjacent;
  }

  @override
  List<Object?> get props => [column, row];

  @override
  String toString() => '$column$row';
}

/// 盤上の駒
class Piece extends Equatable {
  final String id; // 駒の一意識別子
  final PlayerSide side; // A陣営 or B陣営
  final SealType seal; // 刻印の種類
  final Position position; // 盤上の位置

  const Piece({
    required this.id,
    required this.side,
    required this.seal,
    required this.position,
  });

  /// 新しい刻印を持つ駒を生成（刻印奪取時）
  Piece withNewSeal(SealType newSeal) => Piece(
    id: id,
    side: side,
    seal: newSeal,
    position: position,
  );

  /// 無印駒に変更（奪取された駒）
  Piece asNonePiece() => Piece(
    id: id,
    side: side,
    seal: SealType.none,
    position: position,
  );

  /// 新しい位置に移動した駒を生成
  Piece moveTo(Position newPosition) => Piece(
    id: id,
    side: side,
    seal: seal,
    position: newPosition,
  );

  /// この駒が移動可能な位置のリストを取得
  List<Position> getMovablePositions() {
    switch (seal) {
      case SealType.advance:
        // 前方1マスのみ
        final direction = side == PlayerSide.A ? 1 : -1;
        final newRow = position.row + direction;
        if (newRow >= 1 && newRow <= 6) {
          return [Position(column: position.column, row: newRow)];
        }
        return [];

      case SealType.swift:
        // 縦横1～2マス
        final positions = <Position>[];
        final colCode = position.column.codeUnitAt(0);

        // 左右1～2マス
        for (int delta in [-2, -1, 1, 2]) {
          final newColCode = colCode + delta;
          if (newColCode >= 'a'.codeUnitAt(0) && newColCode <= 'f'.codeUnitAt(0)) {
            positions.add(
              Position(
                column: String.fromCharCode(newColCode),
                row: position.row,
              ),
            );
          }
        }

        // 上下1～2マス
        for (int dist in [1, 2]) {
          if (position.row + dist <= 6) {
            positions.add(Position(column: position.column, row: position.row + dist));
          }
          if (position.row - dist >= 1) {
            positions.add(Position(column: position.column, row: position.row - dist));
          }
        }

        return positions;

      case SealType.counter:
        // 斜め1マス
        final positions = <Position>[];
        for (final dx in [-1, 1]) {
          for (final dy in [-1, 1]) {
            final newCol = String.fromCharCode(position.column.codeUnitAt(0) + dx);
            final newRow = position.row + dy;
            final newPos = Position(column: newCol, row: newRow);
            if (newPos.isValid()) {
              positions.add(newPos);
            }
          }
        }
        return positions;

      case SealType.king:
        // 全8方向1マス
        return position.getAdjacentPositions();

      case SealType.none:
        // 無印駒は移動不可
        return [];
    }
  }

  @override
  List<Object?> get props => [id, side, seal, position];

  @override
  String toString() => 'Piece($id, $side, $seal, $position)';
}
