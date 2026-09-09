import 'package:equatable/equatable.dart';
import 'package:mondori/models/piece.dart';

/// ゲーム盤
class Board extends Equatable {
  /// 盤上のすべての駒（位置 -> 駒）
  final Map<Position, Piece> pieces;

  const Board({required this.pieces});

  /// 初期配置を生成（案1：前線重視型）
  factory Board.initialPlacement1() {
    final pieces = <Position, Piece>{};

    // A陣営（下側）
    pieces[Position(column: 'a', row: 1)] = Piece(
      id: 'A-piece-1',
      side: PlayerSide.A,
      seal: SealType.advance,
      position: Position(column: 'a', row: 1),
    );
    pieces[Position(column: 'f', row: 1)] = Piece(
      id: 'A-piece-2',
      side: PlayerSide.A,
      seal: SealType.advance,
      position: Position(column: 'f', row: 1),
    );
    pieces[Position(column: 'b', row: 2)] = Piece(
      id: 'A-piece-3',
      side: PlayerSide.A,
      seal: SealType.swift,
      position: Position(column: 'b', row: 2),
    );
    pieces[Position(column: 'd', row: 2)] = Piece(
      id: 'A-piece-4',
      side: PlayerSide.A,
      seal: SealType.king,
      position: Position(column: 'd', row: 2),
    );
    pieces[Position(column: 'e', row: 2)] = Piece(
      id: 'A-piece-5',
      side: PlayerSide.A,
      seal: SealType.counter,
      position: Position(column: 'e', row: 2),
    );

    // B陣営（上側）
    pieces[Position(column: 'a', row: 6)] = Piece(
      id: 'B-piece-1',
      side: PlayerSide.B,
      seal: SealType.counter,
      position: Position(column: 'a', row: 6),
    );
    pieces[Position(column: 'd', row: 6)] = Piece(
      id: 'B-piece-2',
      side: PlayerSide.B,
      seal: SealType.king,
      position: Position(column: 'd', row: 6),
    );
    pieces[Position(column: 'f', row: 6)] = Piece(
      id: 'B-piece-3',
      side: PlayerSide.B,
      seal: SealType.swift,
      position: Position(column: 'f', row: 6),
    );

    return Board(pieces: pieces);
  }

  /// 指定位置の駒を取得
  Piece? getPieceAt(Position position) => pieces[position];

  /// 指定された陣営のすべての駒を取得
  List<Piece> getPiecesBySide(PlayerSide side) {
    return pieces.values.where((p) => p.side == side).toList();
  }

  /// 王刻印を持つ駒を取得
  Piece? getKingPiece(PlayerSide side) {
    try {
      return pieces.values.firstWhere(
        (p) => p.side == side && p.seal == SealType.king,
      );
    } catch (e) {
      return null;
    }
  }

  /// 駒を移動
  Board movePiece(Piece piece, Position newPosition) {
    final newPieces = Map<Position, Piece>.from(pieces);
    newPieces.remove(piece.position);
    newPieces[newPosition] = piece.moveTo(newPosition);
    return Board(pieces: newPieces);
  }

  /// 駒を奪取（敵駒の刻印を奪う）
  Board capturePiece(Piece myPiece, Piece enemyPiece) {
    final newPieces = Map<Position, Piece>.from(pieces);

    // 敵駒を無印駒に変更
    newPieces[enemyPiece.position] = enemyPiece.asNonePiece();

    // 自駒が敵の刻印を獲得
    newPieces[myPiece.position] = myPiece.withNewSeal(enemyPiece.seal);

    return Board(pieces: newPieces);
  }

  /// 教化（無印駒を復活）
  Board convertPiece(Piece myPiece, Piece nonePiece) {
    final newPieces = Map<Position, Piece>.from(pieces);

    // 無印駒が自駒と同じ刻印を獲得
    newPieces[nonePiece.position] = nonePiece.withNewSeal(myPiece.seal);

    return Board(pieces: newPieces);
  }

  @override
  List<Object?> get props => [pieces];
}
