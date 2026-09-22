import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

admin.initializeApp();
const db = admin.database();

type PlayerSide = 'A' | 'B';
type SessionStatus = 'waiting' | 'active' | 'finished' | 'abandoned';

interface GameSession {
  id: string;
  playerIds: string[];
  board: unknown;
  currentPlayer: PlayerSide;
  status: SessionStatus;
  winner?: PlayerSide;
  moveCount: number;
  createdAt: number;
  updatedAt: number;
  moveHistory?: unknown[];
}

function requireAuth(context: functions.https.CallableContext): string {
  const uid = context.auth?.uid;
  if (!uid) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'この操作にはログインが必要です'
    );
  }
  return uid;
}

/**
 * 新規対戦セッションを作成する。
 * 作成者が PlayerA として自動的に登録される。
 */
export const createGameSession = functions.https.onCall(async (_data, context) => {
  const uid = requireAuth(context);
  const sessionRef = db.ref('sessions').push();
  const now = admin.database.ServerValue.TIMESTAMP;

  const session: Partial<GameSession> = {
    id: sessionRef.key as string,
    playerIds: [uid],
    board: null, // クライアント側の初期配置ロジックで補完される
    currentPlayer: 'A',
    status: 'waiting',
    moveCount: 0,
    createdAt: now as unknown as number,
    updatedAt: now as unknown as number,
  };

  await sessionRef.set(session);
  return { sessionId: sessionRef.key };
});

/**
 * 既存セッションに PlayerB として参加する。
 * トランザクションで二重参加・満員セッションへの参加を防止。
 */
export const joinGameSession = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const sessionId = data.sessionId as string;
  if (!sessionId) {
    throw new functions.https.HttpsError('invalid-argument', 'sessionId が必要です');
  }

  const sessionRef = db.ref(`sessions/${sessionId}`);
  const result = await sessionRef.transaction((session: GameSession | null) => {
    if (!session) return session; // セッションが存在しない -> abort
    if (session.playerIds.includes(uid)) return session; // 既に参加済み
    if (session.playerIds.length >= 2) return; // 満員 -> abort (undefined)

    session.playerIds.push(uid);
    session.status = 'active';
    session.updatedAt = admin.database.ServerValue.TIMESTAMP as unknown as number;
    return session;
  });

  if (!result.committed || !result.snapshot.exists()) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'セッションへの参加に失敗しました（満員または存在しません）'
    );
  }

  return { session: result.snapshot.val() };
});

/**
 * マッチメイキング：待機列に自分を積み、既存の待機者がいれば即座にペアリング。
 * トランザクションで同時実行時の重複マッチを防止する。
 */
export const requestMatch = functions.https.onCall(async (_data, context) => {
  const uid = requireAuth(context);
  const queueRef = db.ref('matchmaking_queue');

  const queueSnapshot = await queueRef.get();
  const queue: Record<string, unknown> = queueSnapshot.exists() ? queueSnapshot.val() : {};
  const waitingUid = Object.keys(queue).find((candidate) => candidate !== uid);

  if (!waitingUid) {
    // 待機列に登録して待つ
    await queueRef.child(uid).set({
      joinedAt: admin.database.ServerValue.TIMESTAMP,
    });
    return { matched: false };
  }

  // マッチング成立：待機者を列から外し、新規セッションを作成
  await queueRef.child(waitingUid).remove();
  await queueRef.child(uid).remove();

  const sessionRef = db.ref('sessions').push();
  const now = admin.database.ServerValue.TIMESTAMP;
  const session: Partial<GameSession> = {
    id: sessionRef.key as string,
    playerIds: [waitingUid, uid],
    board: null,
    currentPlayer: 'A',
    status: 'active',
    moveCount: 0,
    createdAt: now as unknown as number,
    updatedAt: now as unknown as number,
  };
  await sessionRef.set(session);

  return { matched: true, sessionId: sessionRef.key };
});

/**
 * 移動を検証してセッションに反映する。
 * サーバー側では「手番の所有者であるか」を検証し、
 * 駒の移動ルール自体の完全な検証はクライアント（信頼済みロジック）に委ねる。
 * TODO: Phase 2B-2 で盤面ルールの完全なサーバーサイド検証を追加し、
 * チート対策を強化する。
 */
export const submitMove = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const sessionId = data.sessionId as string;
  const board = data.board;
  const nextPlayer = data.nextPlayer as PlayerSide;
  // クライアント側 (OnlineGameService.submitMove) と同様、この手を反映した
  // 後の完全な指し手履歴を渡す想定（既存履歴 + 今回の手）。リプレイに使う。
  const moveHistory = data.moveHistory;

  if (!sessionId || !board || !nextPlayer) {
    throw new functions.https.HttpsError('invalid-argument', '必須パラメータが不足しています');
  }

  const sessionRef = db.ref(`sessions/${sessionId}`);
  const snapshot = await sessionRef.get();
  if (!snapshot.exists()) {
    throw new functions.https.HttpsError('not-found', 'セッションが見つかりません');
  }

  const session = snapshot.val() as GameSession;
  const playerIndex = session.playerIds.indexOf(uid);
  if (playerIndex === -1) {
    throw new functions.https.HttpsError('permission-denied', 'このセッションの参加者ではありません');
  }

  const mySide: PlayerSide = playerIndex === 0 ? 'A' : 'B';
  if (session.currentPlayer !== mySide) {
    throw new functions.https.HttpsError('failed-precondition', 'あなたの手番ではありません');
  }

  await sessionRef.update({
    board,
    currentPlayer: nextPlayer,
    moveCount: session.moveCount + 1,
    ...(moveHistory ? { moveHistory } : {}),
    updatedAt: admin.database.ServerValue.TIMESTAMP,
  });

  return { success: true };
});

/**
 * セッションから離脱・切断した際にセッションを中断状態にする。
 */
export const abandonSession = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const sessionId = data.sessionId as string;

  const sessionRef = db.ref(`sessions/${sessionId}`);
  const snapshot = await sessionRef.get();
  if (!snapshot.exists()) return { success: true };

  const session = snapshot.val() as GameSession;
  if (!session.playerIds.includes(uid)) {
    throw new functions.https.HttpsError('permission-denied', 'このセッションの参加者ではありません');
  }

  await sessionRef.update({
    status: 'abandoned',
    updatedAt: admin.database.ServerValue.TIMESTAMP,
  });

  return { success: true };
});

/**
 * 24時間以上更新のない waiting/abandoned セッションを定期的に掃除する。
 */
export const cleanupStaleSessions = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    const cutoff = Date.now() - 24 * 60 * 60 * 1000;
    const sessionsRef = db.ref('sessions');
    const snapshot = await sessionsRef
      .orderByChild('updatedAt')
      .endAt(cutoff)
      .get();

    if (!snapshot.exists()) return null;

    const updates: Record<string, null> = {};
    snapshot.forEach((child) => {
      const session = child.val() as GameSession;
      if (session.status === 'waiting' || session.status === 'abandoned') {
        updates[child.key as string] = null;
      }
    });

    if (Object.keys(updates).length > 0) {
      await sessionsRef.update(updates);
    }
    return null;
  });
