import 'package:equatable/equatable.dart';
import 'package:mondori/models/piece.dart';

/// ゲーム上の移動を表す
class Move extends Equatable {
  final Piece piece; // 移動する駒
  final Position fromPosition; // 移動元
  final Position toPosition; // 移動先

  const Move({
    required this.piece,
    required this.fromPosition,
    required this.toPosition,
  });

  @override
  List<Object?> get props => [piece.id, fromPosition, toPosition];

  @override
  String toString() => '${piece.seal} $fromPosition -> $toPosition';
}
