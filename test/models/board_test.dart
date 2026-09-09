import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/models/board.dart';
import 'package:mondori/models/piece.dart';

void main() {
  group('Board', () {
    group('initialPlacement1()', () {
      test('初期盤の駒数は10個', () {
        final board = Board.initialPlacement1();
        expect(board.pieces.length, 10);
      });

      test('A陣営の駒数は5個', () {
        final board = Board.initialPlacement1();
        final aPieces = board.getPiecesBySide(PlayerSide.A);
        expect(aPieces.length, 5);
      });

      test('B陣営の駒数は5個', () {
        final board = Board.initialPlacement1();
        final bPieces = board.getPiecesBySide(PlayerSide.B);
        expect(bPieces.length, 5);
      });

      test('各陣営が王刻印を持つ', () {
        final board = Board.initialPlacement1();
        final aKing = board.getKingPiece(PlayerSide.A);
        final bKing = board.getKingPiece(PlayerSide.B);
        expect(aKing, isNotNull);
        expect(bKing, isNotNull);
        expect(aKing!.seal, SealType.king);
        expect(bKing!.seal, SealType.king);
      });

      test('A陣営の王は d2 に配置', () {
        final board = Board.initialPlacement1();
        final aKing = board.getKingPiece(PlayerSide.A);
        expect(aKing!.position, Position(column: 'd', row: 2));
      });

      test('B陣営の王は d6 に配置', () {
        final board = Board.initialPlacement1();
        final bKing = board.getKingPiece(PlayerSide.B);
        expect(bKing!.position, Position(column: 'd', row: 6));
      });

      test('A陣営: a1 に進刻印', () {
        final board = Board.initialPlacement1();
        final piece = board.getPieceAt(Position(column: 'a', row: 1));
        expect(piece, isNotNull);
        expect(piece!.side, PlayerSide.A);
        expect(piece.seal, SealType.advance);
      });

      test('A陣営: b2 に早刻印', () {
        final board = Board.initialPlacement1();
        final piece = board.getPieceAt(Position(column: 'b', row: 2));
        expect(piece, isNotNull);
        expect(piece!.side, PlayerSide.A);
        expect(piece.seal, SealType.swift);
      });

      test('B陣営: f6 に早刻印', () {
        final board = Board.initialPlacement1();
        final piece = board.getPieceAt(Position(column: 'f', row: 6));
        expect(piece, isNotNull);
        expect(piece!.side, PlayerSide.B);
        expect(piece.seal, SealType.swift);
      });
    });

    group('getPieceAt()', () {
      test('盤上の駒を取得', () {
        final board = Board.initialPlacement1();
        final piece = board.getPieceAt(Position(column: 'a', row: 1));
        expect(piece, isNotNull);
        expect(piece!.side, PlayerSide.A);
      });

      test('空のマスは null を返す', () {
        final board = Board.initialPlacement1();
        final piece = board.getPieceAt(Position(column: 'c', row: 3));
        expect(piece, isNull);
      });
    });

    group('getPiecesBySide()', () {
      test('A陣営の駒のみを取得', () {
        final board = Board.initialPlacement1();
        final pieces = board.getPiecesBySide(PlayerSide.A);
        expect(pieces.length, 5);
        for (final piece in pieces) {
          expect(piece.side, PlayerSide.A);
        }
      });

      test('B陣営の駒のみを取得', () {
        final board = Board.initialPlacement1();
        final pieces = board.getPiecesBySide(PlayerSide.B);
        expect(pieces.length, 5);
        for (final piece in pieces) {
          expect(piece.side, PlayerSide.B);
        }
      });
    });

    group('getKingPiece()', () {
      test('A陣営の王を取得', () {
        final board = Board.initialPlacement1();
        final king = board.getKingPiece(PlayerSide.A);
        expect(king, isNotNull);
        expect(king!.seal, SealType.king);
        expect(king.side, PlayerSide.A);
      });

      test('B陣営の王を取得', () {
        final board = Board.initialPlacement1();
        final king = board.getKingPiece(PlayerSide.B);
        expect(king, isNotNull);
        expect(king!.seal, SealType.king);
        expect(king.side, PlayerSide.B);
      });
    });

    group('movePiece()', () {
      test('駒を移動できる', () {
        final board = Board.initialPlacement1();
        final piece = board.getPieceAt(Position(column: 'a', row: 1))!;
        final newPos = Position(column: 'a', row: 2);
        final newBoard = board.movePiece(piece, newPos);

        expect(newBoard.getPieceAt(Position(column: 'a', row: 1)), isNull);
        expect(newBoard.getPieceAt(newPos), isNotNull);
        expect(newBoard.getPieceAt(newPos)!.seal, SealType.advance);
      });

      test('元の盤は変更されない（イミュータビリティ）', () {
        final board = Board.initialPlacement1();
        final piece = board.getPieceAt(Position(column: 'a', row: 1))!;
        final newPos = Position(column: 'a', row: 2);
        board.movePiece(piece, newPos);

        expect(board.getPieceAt(Position(column: 'a', row: 1)), isNotNull);
        expect(board.getPieceAt(newPos), isNull);
      });

      test('移動後の駒の ID は変わらない', () {
        final board = Board.initialPlacement1();
        final piece = board.getPieceAt(Position(column: 'a', row: 1))!;
        final newPos = Position(column: 'a', row: 2);
        final newBoard = board.movePiece(piece, newPos);
        final movedPiece = newBoard.getPieceAt(newPos)!;

        expect(movedPiece.id, piece.id);
      });
    });

    group('capturePiece()', () {
      test('敵駒の刻印を奪取できる', () {
        final board = Board.initialPlacement1();

        // テスト用の盤を作成: c3 に A陣営の進、d3 に B陣営の対
        final pieces = <Position, Piece>{
          Position(column: 'c', row: 3): Piece(
            id: 'A-advance',
            side: PlayerSide.A,
            seal: SealType.advance,
            position: Position(column: 'c', row: 3),
          ),
          Position(column: 'd', row: 3): Piece(
            id: 'B-counter',
            side: PlayerSide.B,
            seal: SealType.counter,
            position: Position(column: 'd', row: 3),
          ),
        };
        final testBoard = Board(pieces: pieces);

        final myPiece = testBoard.getPieceAt(Position(column: 'c', row: 3))!;
        final enemyPiece = testBoard.getPieceAt(Position(column: 'd', row: 3))!;
        final newBoard = testBoard.capturePiece(myPiece, enemyPiece);

        // 敵駒は無印に
        expect(newBoard.getPieceAt(Position(column: 'd', row: 3))!.seal, SealType.none);
        // 自駒は敵の刻印を獲得
        expect(newBoard.getPieceAt(Position(column: 'c', row: 3))!.seal, SealType.counter);
      });

      test('奪取後の敵駒は同じ位置に残る', () {
        final pieces = <Position, Piece>{
          Position(column: 'c', row: 3): Piece(
            id: 'A-advance',
            side: PlayerSide.A,
            seal: SealType.advance,
            position: Position(column: 'c', row: 3),
          ),
          Position(column: 'd', row: 3): Piece(
            id: 'B-counter',
            side: PlayerSide.B,
            seal: SealType.counter,
            position: Position(column: 'd', row: 3),
          ),
        };
        final testBoard = Board(pieces: pieces);

        final myPiece = testBoard.getPieceAt(Position(column: 'c', row: 3))!;
        final enemyPiece = testBoard.getPieceAt(Position(column: 'd', row: 3))!;
        final newBoard = testBoard.capturePiece(myPiece, enemyPiece);

        // 敵駒は d3 に残っている
        expect(newBoard.getPieceAt(Position(column: 'd', row: 3)), isNotNull);
      });

      test('元の盤は変更されない', () {
        final pieces = <Position, Piece>{
          Position(column: 'c', row: 3): Piece(
            id: 'A-advance',
            side: PlayerSide.A,
            seal: SealType.advance,
            position: Position(column: 'c', row: 3),
          ),
          Position(column: 'd', row: 3): Piece(
            id: 'B-counter',
            side: PlayerSide.B,
            seal: SealType.counter,
            position: Position(column: 'd', row: 3),
          ),
        };
        final testBoard = Board(pieces: pieces);

        final myPiece = testBoard.getPieceAt(Position(column: 'c', row: 3))!;
        final enemyPiece = testBoard.getPieceAt(Position(column: 'd', row: 3))!;
        testBoard.capturePiece(myPiece, enemyPiece);

        // 元の盤の敵駒は対刻印のまま
        expect(testBoard.getPieceAt(Position(column: 'd', row: 3))!.seal, SealType.counter);
      });
    });

    group('convertPiece()', () {
      test('無印駒を復活できる', () {
        final pieces = <Position, Piece>{
          Position(column: 'c', row: 3): Piece(
            id: 'A-swift',
            side: PlayerSide.A,
            seal: SealType.swift,
            position: Position(column: 'c', row: 3),
          ),
          Position(column: 'd', row: 3): Piece(
            id: 'A-none',
            side: PlayerSide.A,
            seal: SealType.none,
            position: Position(column: 'd', row: 3),
          ),
        };
        final testBoard = Board(pieces: pieces);

        final myPiece = testBoard.getPieceAt(Position(column: 'c', row: 3))!;
        final nonePiece = testBoard.getPieceAt(Position(column: 'd', row: 3))!;
        final newBoard = testBoard.convertPiece(myPiece, nonePiece);

        // 無印駒が早刻印を獲得
        expect(newBoard.getPieceAt(Position(column: 'd', row: 3))!.seal, SealType.swift);
        expect(newBoard.getPieceAt(Position(column: 'd', row: 3))!.side, PlayerSide.A);
      });

      test('教化後の駒は同じ位置に残る', () {
        final pieces = <Position, Piece>{
          Position(column: 'c', row: 3): Piece(
            id: 'A-swift',
            side: PlayerSide.A,
            seal: SealType.swift,
            position: Position(column: 'c', row: 3),
          ),
          Position(column: 'd', row: 3): Piece(
            id: 'A-none',
            side: PlayerSide.A,
            seal: SealType.none,
            position: Position(column: 'd', row: 3),
          ),
        };
        final testBoard = Board(pieces: pieces);

        final myPiece = testBoard.getPieceAt(Position(column: 'c', row: 3))!;
        final nonePiece = testBoard.getPieceAt(Position(column: 'd', row: 3))!;
        final newBoard = testBoard.convertPiece(myPiece, nonePiece);

        // 無印駒は d3 に残っている
        expect(newBoard.getPieceAt(Position(column: 'd', row: 3)), isNotNull);
      });

      test('元の盤は変更されない', () {
        final pieces = <Position, Piece>{
          Position(column: 'c', row: 3): Piece(
            id: 'A-swift',
            side: PlayerSide.A,
            seal: SealType.swift,
            position: Position(column: 'c', row: 3),
          ),
          Position(column: 'd', row: 3): Piece(
            id: 'A-none',
            side: PlayerSide.A,
            seal: SealType.none,
            position: Position(column: 'd', row: 3),
          ),
        };
        final testBoard = Board(pieces: pieces);

        final myPiece = testBoard.getPieceAt(Position(column: 'c', row: 3))!;
        final nonePiece = testBoard.getPieceAt(Position(column: 'd', row: 3))!;
        testBoard.convertPiece(myPiece, nonePiece);

        // 元の盤の無印駒は無印のまま
        expect(testBoard.getPieceAt(Position(column: 'd', row: 3))!.seal, SealType.none);
      });
    });

    group('Equatable', () {
      test('同じ盤状態は等価', () {
        final board1 = Board.initialPlacement1();
        final board2 = Board.initialPlacement1();
        expect(board1 == board2, true);
      });

      test('異なる盤状態は非等価', () {
        final board1 = Board.initialPlacement1();
        final piece = board1.getPieceAt(Position(column: 'a', row: 1))!;
        final board2 = board1.movePiece(piece, Position(column: 'a', row: 2));
        expect(board1 == board2, false);
      });
    });
  });
}
