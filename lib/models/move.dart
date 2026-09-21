import 'package:equatable/equatable.dart';
import 'package:mondori/models/piece.dart';

/// 手番で選択できる3つのアクション
///
/// - [move]: 刻印の移動パターンに従って空マスへ移動
/// - [capture]: 隣接する敵の有効駒（無印以外）の刻印を奪う（移動を伴わない）
/// - [convert]: 隣接する自陣の無印駒に刻印をコピーして付与（移動を伴わない）
enum MoveType { move, capture, convert }

/// ゲーム上の1手を表す
class Move extends Equatable {
  final Piece piece; // アクションを行う駒（capture/convert では位置は変わらない）
  final Position fromPosition; // アクション実行時の駒の位置
  final Position toPosition; // 対象位置（move: 移動先 / capture・convert: 対象駒の位置）
  final MoveType type;

  const Move({
    required this.piece,
    required this.fromPosition,
    required this.toPosition,
    this.type = MoveType.move,
  });

  @override
  List<Object?> get props => [piece.id, fromPosition, toPosition, type];

  @override
  String toString() {
    switch (type) {
      case MoveType.move:
        return '${piece.seal} $fromPosition -> $toPosition';
      case MoveType.capture:
        return '${piece.seal} $fromPosition が $toPosition を奪取';
      case MoveType.convert:
        return '${piece.seal} $fromPosition が $toPosition を教化';
    }
  }

  /// JSON へのシリアライズ（統計・リプレイ用）
  Map<String, dynamic> toJson() => {
        'piece': piece.toJson(),
        'fromPosition': fromPosition.toJson(),
        'toPosition': toPosition.toJson(),
        'type': type.name,
      };

  /// JSON からの復元
  factory Move.fromJson(Map<String, dynamic> json) => Move(
        piece: Piece.fromJson(Map<String, dynamic>.from(json['piece'] as Map)),
        fromPosition: Position.fromJson(
          Map<String, dynamic>.from(json['fromPosition'] as Map),
        ),
        toPosition: Position.fromJson(
          Map<String, dynamic>.from(json['toPosition'] as Map),
        ),
        // 旧バージョンのデータには type が存在しないため move をデフォルトとする
        type: json['type'] != null
            ? MoveType.values.byName(json['type'] as String)
            : MoveType.move,
      );
}
