import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/models/piece.dart';

void main() {
  group('Position', () {
    group('isValid()', () {
      test('有効な位置: a1', () {
        expect(Position(column: 'a', row: 1).isValid(), true);
      });

      test('有効な位置: f6', () {
        expect(Position(column: 'f', row: 6).isValid(), true);
      });

      test('有効な位置: c3', () {
        expect(Position(column: 'c', row: 3).isValid(), true);
      });

      test('無効: 列が範囲外 (g1)', () {
        expect(Position(column: 'g', row: 1).isValid(), false);
      });

      test('無効: 列が範囲外 (@1)', () {
        expect(Position(column: '@', row: 1).isValid(), false);
      });

      test('無効: 行が0', () {
        expect(Position(column: 'a', row: 0).isValid(), false);
      });

      test('無効: 行が7', () {
        expect(Position(column: 'a', row: 7).isValid(), false);
      });

      test('無効: 列が複数文字', () {
        expect(Position(column: 'ab', row: 1).isValid(), false);
      });
    });

    group('getAdjacentPositions()', () {
      test('中央マス (c3) の隣接位置は8個', () {
        final pos = Position(column: 'c', row: 3);
        final adjacent = pos.getAdjacentPositions();
        expect(adjacent.length, 8);
      });

      test('隅マス (a1) の隣接位置は3個', () {
        final pos = Position(column: 'a', row: 1);
        final adjacent = pos.getAdjacentPositions();
        expect(adjacent.length, 3);
        expect(adjacent.contains(Position(column: 'b', row: 1)), true);
        expect(adjacent.contains(Position(column: 'a', row: 2)), true);
        expect(adjacent.contains(Position(column: 'b', row: 2)), true);
      });

      test('隅マス (f6) の隣接位置は3個', () {
        final pos = Position(column: 'f', row: 6);
        final adjacent = pos.getAdjacentPositions();
        expect(adjacent.length, 3);
        expect(adjacent.contains(Position(column: 'e', row: 6)), true);
        expect(adjacent.contains(Position(column: 'f', row: 5)), true);
        expect(adjacent.contains(Position(column: 'e', row: 5)), true);
      });

      test('辺マス (c1) の隣接位置は5個', () {
        final pos = Position(column: 'c', row: 1);
        final adjacent = pos.getAdjacentPositions();
        expect(adjacent.length, 5);
      });

      test('中央マスの隣接位置に特定方向を含む', () {
        final pos = Position(column: 'd', row: 3);
        final adjacent = pos.getAdjacentPositions();
        // 上下左右の4方向と斜めの4方向
        expect(adjacent.contains(Position(column: 'd', row: 4)), true); // 上
        expect(adjacent.contains(Position(column: 'd', row: 2)), true); // 下
        expect(adjacent.contains(Position(column: 'c', row: 3)), true); // 左
        expect(adjacent.contains(Position(column: 'e', row: 3)), true); // 右
        expect(adjacent.contains(Position(column: 'c', row: 4)), true); // 左上
        expect(adjacent.contains(Position(column: 'e', row: 4)), true); // 右上
        expect(adjacent.contains(Position(column: 'c', row: 2)), true); // 左下
        expect(adjacent.contains(Position(column: 'e', row: 2)), true); // 右下
      });
    });

    group('toString()', () {
      test('a1 の文字列表現', () {
        expect(Position(column: 'a', row: 1).toString(), 'a1');
      });

      test('f6 の文字列表現', () {
        expect(Position(column: 'f', row: 6).toString(), 'f6');
      });
    });

    group('Equatable', () {
      test('同じ位置は等価', () {
        expect(
          Position(column: 'a', row: 1) == Position(column: 'a', row: 1),
          true,
        );
      });

      test('異なる列は非等価', () {
        expect(
          Position(column: 'a', row: 1) == Position(column: 'b', row: 1),
          false,
        );
      });

      test('異なる行は非等価', () {
        expect(
          Position(column: 'a', row: 1) == Position(column: 'a', row: 2),
          false,
        );
      });
    });
  });

  group('Piece', () {
    group('getMovablePositions() - 進（advance）', () {
      test('A陣営: a1から上へ移動 (a2)', () {
        final piece = Piece(
          id: 'test',
          side: PlayerSide.A,
          seal: SealType.advance,
          position: Position(column: 'a', row: 1),
        );
        final movable = piece.getMovablePositions();
        expect(movable.length, 1);
        expect(movable.contains(Position(column: 'a', row: 2)), true);
      });

      test('B陣営: f6から下へ移動 (f5)', () {
        final piece = Piece(
          id: 'test',
          side: PlayerSide.B,
          seal: SealType.advance,
          position: Position(column: 'f', row: 6),
        );
        final movable = piece.getMovablePositions();
        expect(movable.length, 1);
        expect(movable.contains(Position(column: 'f', row: 5)), true);
      });

      test('A陣営: a6 (端) からは移動不可', () {
        final piece = Piece(
          id: 'test',
          side: PlayerSide.A,
          seal: SealType.advance,
          position: Position(column: 'a', row: 6),
        );
        expect(piece.getMovablePositions().isEmpty, true);
      });

      test('B陣営: f1 (端) からは移動不可', () {
        final piece = Piece(
          id: 'test',
          side: PlayerSide.B,
          seal: SealType.advance,
          position: Position(column: 'f', row: 1),
        );
        expect(piece.getMovablePositions().isEmpty, true);
      });
    });

    group('getMovablePositions() - 早（swift）', () {
      test('c3 中央からの移動は12マス', () {
        final piece = Piece(
          id: 'test',
          side: PlayerSide.A,
          seal: SealType.swift,
          position: Position(column: 'c', row: 3),
        );
        final movable = piece.getMovablePositions();
        // 左右各2 = 4マス、上下各2 = 4マス、計8マス
        expect(movable.length, 8);
      });

      test('c3 からの移動は左右2マス含む', () {
        final piece = Piece(
          id: 'test',
          side: PlayerSide.A,
          seal: SealType.swift,
          position: Position(column: 'c', row: 3),
        );
        final movable = piece.getMovablePositions();
        expect(movable.contains(Position(column: 'a', row: 3)), true); // 左2
        expect(movable.contains(Position(column: 'b', row: 3)), true); // 左1
        expect(movable.contains(Position(column: 'd', row: 3)), true); // 右1
        expect(movable.contains(Position(column: 'e', row: 3)), true); // 右2
      });

      test('c3 からの移動は上下2マス含む', () {
        final piece = Piece(
          id: 'test',
          side: PlayerSide.A,
          seal: SealType.swift,
          position: Position(column: 'c', row: 3),
        );
        final movable = piece.getMovablePositions();
        expect(movable.contains(Position(column: 'c', row: 1)), true); // 下2
        expect(movable.contains(Position(column: 'c', row: 2)), true); // 下1
        expect(movable.contains(Position(column: 'c', row: 4)), true); // 上1
        expect(movable.contains(Position(column: 'c', row: 5)), true); // 上2
      });

      test('a1 隅からの移動は4マス', () {
        final piece = Piece(
          id: 'test',
          side: PlayerSide.A,
          seal: SealType.swift,
          position: Position(column: 'a', row: 1),
        );
        final movable = piece.getMovablePositions();
        expect(movable.length, 4);
        expect(movable.contains(Position(column: 'b', row: 1)), true);
        expect(movable.contains(Position(column: 'c', row: 1)), true);
        expect(movable.contains(Position(column: 'a', row: 2)), true);
        expect(movable.contains(Position(column: 'a', row: 3)), true);
      });
    });

    group('getMovablePositions() - 対（counter）', () {
      test('c3 中央からは斜め4マス', () {
        final piece = Piece(
          id: 'test',
          side: PlayerSide.A,
          seal: SealType.counter,
          position: Position(column: 'c', row: 3),
        );
        final movable = piece.getMovablePositions();
        expect(movable.length, 4);
        expect(movable.contains(Position(column: 'b', row: 2)), true);
        expect(movable.contains(Position(column: 'd', row: 2)), true);
        expect(movable.contains(Position(column: 'b', row: 4)), true);
        expect(movable.contains(Position(column: 'd', row: 4)), true);
      });

      test('a1 隅からは斜め1マス', () {
        final piece = Piece(
          id: 'test',
          side: PlayerSide.A,
          seal: SealType.counter,
          position: Position(column: 'a', row: 1),
        );
        final movable = piece.getMovablePositions();
        expect(movable.length, 1);
        expect(movable.contains(Position(column: 'b', row: 2)), true);
      });
    });

    group('getMovablePositions() - 王（king）', () {
      test('c3 中央からは8方向全て', () {
        final piece = Piece(
          id: 'test',
          side: PlayerSide.A,
          seal: SealType.king,
          position: Position(column: 'c', row: 3),
        );
        final movable = piece.getMovablePositions();
        expect(movable.length, 8);
      });

      test('a1 隅からは3方向', () {
        final piece = Piece(
          id: 'test',
          side: PlayerSide.A,
          seal: SealType.king,
          position: Position(column: 'a', row: 1),
        );
        final movable = piece.getMovablePositions();
        expect(movable.length, 3);
      });
    });

    group('getMovablePositions() - 無印（none）', () {
      test('無印駒は移動不可', () {
        final piece = Piece(
          id: 'test',
          side: PlayerSide.A,
          seal: SealType.none,
          position: Position(column: 'c', row: 3),
        );
        expect(piece.getMovablePositions().isEmpty, true);
      });
    });

    group('withNewSeal()', () {
      test('新しい刻印を持つ駒を生成', () {
        final original = Piece(
          id: 'test',
          side: PlayerSide.A,
          seal: SealType.advance,
          position: Position(column: 'c', row: 3),
        );
        final newPiece = original.withNewSeal(SealType.king);

        expect(newPiece.id, 'test');
        expect(newPiece.side, PlayerSide.A);
        expect(newPiece.seal, SealType.king);
        expect(newPiece.position, Position(column: 'c', row: 3));
      });

      test('元の駒は変更されない（イミュータビリティ）', () {
        final original = Piece(
          id: 'test',
          side: PlayerSide.A,
          seal: SealType.advance,
          position: Position(column: 'c', row: 3),
        );
        original.withNewSeal(SealType.king);

        expect(original.seal, SealType.advance);
      });
    });

    group('asNonePiece()', () {
      test('無印駒に変更', () {
        final original = Piece(
          id: 'test',
          side: PlayerSide.A,
          seal: SealType.king,
          position: Position(column: 'c', row: 3),
        );
        final nonePiece = original.asNonePiece();

        expect(nonePiece.seal, SealType.none);
        expect(nonePiece.id, 'test');
        expect(nonePiece.side, PlayerSide.A);
        expect(nonePiece.position, Position(column: 'c', row: 3));
      });
    });

    group('moveTo()', () {
      test('新しい位置に移動した駒を生成', () {
        final original = Piece(
          id: 'test',
          side: PlayerSide.A,
          seal: SealType.advance,
          position: Position(column: 'c', row: 3),
        );
        final newPos = Position(column: 'c', row: 4);
        final moved = original.moveTo(newPos);

        expect(moved.position, newPos);
        expect(moved.id, 'test');
        expect(moved.side, PlayerSide.A);
        expect(moved.seal, SealType.advance);
      });

      test('元の駒は変更されない', () {
        final original = Piece(
          id: 'test',
          side: PlayerSide.A,
          seal: SealType.advance,
          position: Position(column: 'c', row: 3),
        );
        original.moveTo(Position(column: 'c', row: 4));

        expect(original.position, Position(column: 'c', row: 3));
      });
    });

    group('Equatable', () {
      test('同じ駒は等価', () {
        final piece1 = Piece(
          id: 'test',
          side: PlayerSide.A,
          seal: SealType.advance,
          position: Position(column: 'c', row: 3),
        );
        final piece2 = Piece(
          id: 'test',
          side: PlayerSide.A,
          seal: SealType.advance,
          position: Position(column: 'c', row: 3),
        );
        expect(piece1 == piece2, true);
      });

      test('異なるID は非等価', () {
        final piece1 = Piece(
          id: 'test1',
          side: PlayerSide.A,
          seal: SealType.advance,
          position: Position(column: 'c', row: 3),
        );
        final piece2 = Piece(
          id: 'test2',
          side: PlayerSide.A,
          seal: SealType.advance,
          position: Position(column: 'c', row: 3),
        );
        expect(piece1 == piece2, false);
      });

      test('異なる刻印は非等価', () {
        final piece1 = Piece(
          id: 'test',
          side: PlayerSide.A,
          seal: SealType.advance,
          position: Position(column: 'c', row: 3),
        );
        final piece2 = Piece(
          id: 'test',
          side: PlayerSide.A,
          seal: SealType.king,
          position: Position(column: 'c', row: 3),
        );
        expect(piece1 == piece2, false);
      });
    });
  });
}
