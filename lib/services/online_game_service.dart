import 'package:firebase_database/firebase_database.dart';
import 'package:mondori/models/board.dart';
import 'package:mondori/models/game_session.dart';
import 'package:mondori/models/piece.dart';
import 'package:uuid/uuid.dart';

/// オンライン対戦バックエンド (Firebase Realtime Database) との通信サービス
///
/// Firebase プロジェクト未接続の環境でも import エラーにならないよう、
/// DatabaseReference の取得は遅延させている。
class OnlineGameService {
  final FirebaseDatabase _database;
  final Uuid _uuid;

  OnlineGameService({
    FirebaseDatabase? database,
    Uuid? uuid,
  })  : _database = database ?? FirebaseDatabase.instance,
        _uuid = uuid ?? const Uuid();

  DatabaseReference get _sessionsRef => _database.ref('sessions');
  DatabaseReference get _matchmakingRef => _database.ref('matchmaking_queue');

  /// 新規対戦セッションを作成し、作成者を PlayerA として登録
  Future<GameSession> createSession(String hostPlayerId) async {
    final sessionId = _uuid.v4();
    final session = GameSession.newSession(
      id: sessionId,
      hostPlayerId: hostPlayerId,
    );

    await _sessionsRef.child(sessionId).set(session.toJson());
    return session;
  }

  /// 既存のセッションに PlayerB として参加
  Future<GameSession> joinSession(String sessionId, String guestPlayerId) async {
    final snapshot = await _sessionsRef.child(sessionId).get();
    if (!snapshot.exists) {
      throw StateError('セッションが見つかりません: $sessionId');
    }

    final session = GameSession.fromJson(
      Map<String, dynamic>.from(snapshot.value as Map),
    );

    if (session.isFull) {
      throw StateError('セッションは既に満員です: $sessionId');
    }

    final updated = session.copyWith(
      playerIds: [...session.playerIds, guestPlayerId],
      status: GameSessionStatus.active,
    );

    await _sessionsRef.child(sessionId).update(updated.toJson());
    return updated;
  }

  /// セッションの状態変更をリアルタイム監視
  Stream<GameSession> watchSession(String sessionId) {
    return _sessionsRef.child(sessionId).onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) {
        throw StateError('セッションが削除されました: $sessionId');
      }
      return GameSession.fromJson(Map<String, dynamic>.from(value as Map));
    });
  }

  /// 移動を送信してボードとターンを更新
  Future<void> submitMove({
    required String sessionId,
    required Board newBoard,
    required PlayerSide nextPlayer,
    required int moveCount,
  }) async {
    await _sessionsRef.child(sessionId).update({
      'board': newBoard.toJson(),
      'currentPlayer': nextPlayer.name,
      'moveCount': moveCount,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// ゲーム結果を記録してセッションを終了
  Future<void> recordResult({
    required String sessionId,
    required PlayerSide winner,
  }) async {
    await _sessionsRef.child(sessionId).update({
      'status': GameSessionStatus.finished.name,
      'winner': winner.name,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// セッションを中断状態にする（切断・退出時）
  Future<void> abandonSession(String sessionId) async {
    await _sessionsRef.child(sessionId).update({
      'status': GameSessionStatus.abandoned.name,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// マッチメイキングキューに参加し、対戦相手が見つかるまで待機
  ///
  /// 実装方針: キューに自分の uid を積み、既に他プレイヤーが並んでいれば
  /// 即座にペアリングしてセッションを作成する。本番運用では Cloud Functions
  /// によるトランザクション処理に置き換える想定（重複マッチ防止のため）。
  Future<String> findOrCreateMatch(String playerId) async {
    final queueSnapshot = await _matchmakingRef.get();

    String? waitingPlayerId;
    if (queueSnapshot.exists) {
      final queue = Map<String, dynamic>.from(queueSnapshot.value as Map);
      final candidates = queue.keys.where((uid) => uid != playerId);
      if (candidates.isNotEmpty) {
        waitingPlayerId = candidates.first;
      }
    }

    if (waitingPlayerId != null) {
      // 待機中のプレイヤーとマッチング
      await _matchmakingRef.child(waitingPlayerId).remove();
      final session = await createSession(waitingPlayerId);
      final joined = await joinSession(session.id, playerId);
      return joined.id;
    } else {
      // キューに登録して待機
      await _matchmakingRef.child(playerId).set({
        'joinedAt': DateTime.now().millisecondsSinceEpoch,
      });
      return '';
    }
  }

  /// マッチメイキングキューから離脱
  Future<void> cancelMatchmaking(String playerId) async {
    await _matchmakingRef.child(playerId).remove();
  }
}
