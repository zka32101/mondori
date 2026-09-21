# Phase 2 実装計画書

**フェーズ**: Phase 2（機能拡張）  
**目標期間**: 2026-09-15 ～ 2026-10-31 (46日間)  
**リリース対象**: v1.0 正式版  
**進度**: 📋 計画中

---

## 📋 Phase 2 概要

Phase 1 で完成した基本機能（ホットシートプレイ）を拡張し、AI 対戦・オンライン対戦・統計機能・マルチメディア対応を実装。ユーザーの遊びの選択肢を大幅に増加させます。

### 目標

```
Phase 1: ホットシートプレイ実装 ✅ (完成)
   ↓
Phase 2: 機能拡張・ゲーム体験向上
├─ Phase 2A: AI 対戦実装 (2週間)
├─ Phase 2B: オンライン対戦基盤 (3週間)
├─ Phase 2C: 統計・履歴機能 (1.5週間)
└─ Phase 2D: マルチメディア・ポーランド (1.5週間)
   ↓
v1.0 リリース (2026-10-31)
```

---

## 🎮 Phase 2A: AI 対戦実装

### 目標: AI プレイヤーロジックの完全実装

**期間**: 2026-09-15 ～ 2026-09-30 (2週間)

### 実装内容

#### 1. ゲーム木探索アルゴリズム

**File**: lib/models/ai_engine.dart (NEW)

```dart
class AIEngine {
  // ミニマックス法による探索
  int minimax({
    required Board board,
    required int depth,
    required PlayerSide player,
    bool isMaximizing = true,
  }) {
    if (depth == 0 || isGameOver(board)) {
      return evaluate(board);
    }
    
    if (isMaximizing) {
      int maxScore = -infinity;
      for (var move in getPossibleMoves(board, player)) {
        final newBoard = applyMove(board, move);
        final score = minimax(
          board: newBoard,
          depth: depth - 1,
          player: player.opposite,
          isMaximizing: false,
        );
        maxScore = max(maxScore, score);
      }
      return maxScore;
    } else {
      int minScore = infinity;
      for (var move in getPossibleMoves(board, player)) {
        final newBoard = applyMove(board, move);
        final score = minimax(
          board: newBoard,
          depth: depth - 1,
          player: player.opposite,
          isMaximizing: true,
        );
        minScore = min(minScore, score);
      }
      return minScore;
    }
  }
  
  // アルファ・ベータ枝刈り最適化
  int alphaBeta({
    required Board board,
    required int depth,
    required PlayerSide player,
    int alpha = -infinity,
    int beta = infinity,
    bool isMaximizing = true,
  }) {
    // ... (ミニマックス + 枝刈り)
  }
}
```

**特徴**:
- ミニマックス法による最適手探索
- アルファ・ベータ枝刈りで高速化
- 評価関数による局面評価
- 深さ制限による計算量制御

#### 2. 評価関数実装

**File**: lib/models/ai_evaluation.dart (NEW)

```dart
class Evaluator {
  // 局面を数値化（AI が有利な位置が高い値）
  int evaluate(Board board, PlayerSide aiPlayer) {
    int score = 0;
    
    // 1. 駒の総合力 (駒の種類による価値)
    // 王 (King): 1000点
    // 対 (Counter): 300点
    // 早 (Swift): 200点
    // 進 (Advance): 100点
    score += calculateMaterialScore(board, aiPlayer);
    
    // 2. 盤面制御 (中央支配)
    score += calculateControlScore(board, aiPlayer);
    
    // 3. 敵駒への脅威度
    score += calculateThreatScore(board, aiPlayer);
    
    // 4. 防御力 (王の安全性)
    score += calculateDefenseScore(board, aiPlayer);
    
    // 5. 位置的優位性
    score += calculatePositionalScore(board, aiPlayer);
    
    return score;
  }
}
```

**評価基準**:
- 駒の種類による価値
- 盤面中央支配度
- 敵駒への脅威
- 王の安全性
- 全体的なポジション

#### 3. 難易度レベル

| レベル | 深さ | 特徴 | 推奨プレイヤー |
|--------|:----:|------|:------------:|
| **Easy** | 2-3 | ランダム選択を混ぜる | 初心者 |
| **Normal** | 4-5 | 標準アルゴリズム | 一般ユーザー |
| **Hard** | 6-7 | フル最適化探索 | 熟練者 |
| **Expert** | 8+ | 高度な評価関数 + キャッシング | 上級者 |

#### 4. UI 実装

**File**: lib/screens/ai_game_screen.dart (NEW)

```dart
class AIGameScreen extends StatefulWidget {
  final AILevel difficulty;
  
  @override
  Widget build(context) {
    return GameScreen(
      isAIGame: true,
      aiLevel: difficulty,
      onAITurn: _processAITurn,
    );
  }
  
  Future<void> _processAITurn() async {
    // AI の思考 (ローディングアニメーション表示)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AIThinkingDialog(),
    );
    
    // ミニマックス探索実行
    final move = await _aiEngine.findBestMove(
      board: gameState.board,
      difficulty: difficulty,
    );
    
    // ダイアログを閉じて手を実行
    Navigator.pop(context);
    await executeMove(move);
  }
}
```

### テスト実装

**File**: test/ai/ai_engine_test.dart (NEW)

```dart
group('AI Engine Tests', () {
  test('Minimax returns best move for known position', () {
    final board = Board.testPosition1();
    final move = aiEngine.minimax(board: board, depth: 3);
    expect(move, equals(expectedBestMove));
  });
  
  test('Evaluation function recognizes winning position', () {
    final board = Board.winningPosition();
    expect(evaluator.evaluate(board, PlayerSide.A) > 5000, true);
  });
  
  test('Alpha-beta pruning matches minimax results', () {
    final board = Board.testPosition2();
    final minimaxScore = ai.minimax(board, depth: 4);
    final abScore = ai.alphaBeta(board, depth: 4);
    expect(minimaxScore, equals(abScore));
  });
});
```

---

## 🌐 Phase 2B: オンライン対戦基盤

### 目標: マルチプレイヤーネットワーク基盤の構築

**期間**: 2026-09-30 ～ 2026-10-15 (2.5週間)

### バックエンド実装

#### 1. ゲームサーバー実装

**Framework**: Firebase Realtime Database + Cloud Functions

```typescript
// functions/src/index.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.database();

// ゲームセッション作成
exports.createGameSession = functions.https.onCall(async (data, context) => {
  const { playerId, mode } = data;
  
  const sessionRef = db.ref('sessions').push();
  await sessionRef.set({
    id: sessionRef.key,
    players: [playerId],
    mode: mode,
    board: initialBoard,
    currentPlayer: 0,
    status: 'waiting',
    createdAt: admin.database.ServerValue.TIMESTAMP,
  });
  
  return { sessionId: sessionRef.key };
});

// ゲーム状態更新
exports.updateGameState = functions.https.onCall(async (data, context) => {
  const { sessionId, move } = data;
  
  const sessionRef = db.ref(`sessions/${sessionId}`);
  const snapshot = await sessionRef.once('value');
  const session = snapshot.val();
  
  // 手を検証して実行
  const newBoard = applyMove(session.board, move);
  
  await sessionRef.update({
    board: newBoard,
    currentPlayer: (session.currentPlayer + 1) % 2,
    lastMove: move,
    lastUpdateAt: admin.database.ServerValue.TIMESTAMP,
  });
});

// ゲーム結果記録
exports.recordGameResult = functions.https.onCall(async (data, context) => {
  const { sessionId, winner, stats } = data;
  
  await db.ref(`results/${sessionId}`).set({
    sessionId,
    winner,
    stats,
    completedAt: admin.database.ServerValue.TIMESTAMP,
  });
});
```

#### 2. リアルタイム通信

**File**: lib/services/online_game_service.dart (NEW)

```dart
class OnlineGameService {
  final _firebaseDatabase = FirebaseDatabase.instance;
  late DatabaseReference _sessionRef;
  
  // ゲームセッション作成
  Future<String> createSession(String playerId) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('createGameSession')
        .call({'playerId': playerId});
    return result.data['sessionId'];
  }
  
  // リアルタイム状態リスナー
  Stream<GameState> watchGameState(String sessionId) {
    _sessionRef = _firebaseDatabase.ref('sessions/$sessionId');
    return _sessionRef.onValue.map((event) {
      final data = event.snapshot.value as Map;
      return GameState.fromJson(data);
    });
  }
  
  // 手を送信
  Future<void> submitMove(String sessionId, Move move) async {
    await FirebaseFunctions.instance
        .httpsCallable('updateGameState')
        .call({
          'sessionId': sessionId,
          'move': move.toJson(),
        });
  }
  
  // ゲーム結果記録
  Future<void> recordResult(
    String sessionId,
    PlayerSide winner,
    GameStats stats,
  ) async {
    await FirebaseFunctions.instance
        .httpsCallable('recordGameResult')
        .call({
          'sessionId': sessionId,
          'winner': winner.name,
          'stats': stats.toJson(),
        });
  }
}
```

#### 3. UI 実装

**File**: lib/screens/online_game_screen.dart (NEW)

```dart
class OnlineGameScreen extends StatefulWidget {
  final String sessionId;
  
  @override
  Widget build(context) {
    return StreamBuilder<GameState>(
      stream: _gameService.watchGameState(sessionId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final gameState = snapshot.data!;
          return GameScreen(
            isOnlineGame: true,
            gameState: gameState,
            onMove: (move) => _submitMove(move),
            onGameEnd: (winner) => _recordResult(winner),
          );
        }
        return const LoadingWidget();
      },
    );
  }
}
```

#### 4. 対戦マッチング

**File**: lib/services/matchmaking_service.dart (NEW)

```dart
class MatchmakingService {
  // プレイヤーをマッチング待ちキューに追加
  Future<void> joinQueue(String playerId, int skillLevel) async {
    await db.ref('matchmaking/queue').child(playerId).set({
      'playerId': playerId,
      'skillLevel': skillLevel,
      'joinedAt': ServerValue.timestamp,
    });
    
    // キューを監視してマッチ検出
    _watchQueue(playerId);
  }
  
  Future<void> _watchQueue(String playerId) async {
    db.ref('matchmaking/queue').onChildAdded.listen((event) {
      final queueEntries = event.snapshot.value as Map;
      
      // マッチング条件チェック
      if (canMatch(queueEntries)) {
        final matchedPlayers = findBestMatch(queueEntries);
        _createMatchSession(matchedPlayers);
      }
    });
  }
}
```

---

## 📊 Phase 2C: 統計・履歴機能

### 目標: ゲーム履歴・統計追跡システムの実装

**期間**: 2026-10-15 ～ 2026-10-22 (1.5週間)

### 実装内容

#### 1. 統計データモデル

**File**: lib/models/game_statistics.dart (NEW)

```dart
@freezed
class GameStatistics with _$GameStatistics {
  const factory GameStatistics({
    required String gameId,
    required PlayerSide winner,
    required PlayerSide loser,
    required int turnCount,
    required Duration duration,
    required DateTime playedAt,
    required List<Move> moveHistory,
    required Map<String, dynamic> stats,
  }) = _GameStatistics;
}

@freezed
class PlayerStats with _$PlayerStats {
  const factory PlayerStats({
    required int totalGames,
    required int wins,
    required int losses,
    required double winRate,
    required int totalTurns,
    required double averageTurns,
    required DateTime firstGameAt,
    required DateTime lastGameAt,
  }) = _PlayerStats;
}
```

#### 2. 統計記録サービス

**File**: lib/services/statistics_service.dart (NEW)

```dart
class StatisticsService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  
  // ゲーム結果を記録
  Future<void> recordGameResult(GameStatistics stats) async {
    // ゲーム情報を保存
    await _db.ref('games/${stats.gameId}').set(stats.toJson());
    
    // プレイヤー統計を更新
    await _updatePlayerStats(stats.winner, won: true);
    await _updatePlayerStats(stats.loser, won: false);
  }
  
  Future<void> _updatePlayerStats(
    String playerId, {
    required bool won,
  }) async {
    final ref = _db.ref('players/$playerId/stats');
    final snapshot = await ref.once();
    final current = snapshot.snapshot.value as Map? ?? {};
    
    final newStats = {
      'totalGames': (current['totalGames'] ?? 0) + 1,
      'wins': (current['wins'] ?? 0) + (won ? 1 : 0),
      'losses': (current['losses'] ?? 0) + (won ? 0 : 1),
      'lastGameAt': ServerValue.timestamp,
    };
    
    await ref.update(newStats);
  }
  
  // プレイヤーの統計情報を取得
  Future<PlayerStats> getPlayerStats(String playerId) async {
    final snapshot = await _db.ref('players/$playerId/stats').once();
    return PlayerStats.fromJson(snapshot.snapshot.value as Map);
  }
  
  // ゲーム履歴を取得
  Stream<List<GameStatistics>> getGameHistory(String playerId) {
    return _db
        .ref('games')
        .orderByChild('playedAt')
        .limitToLast(50)
        .onValue
        .map((event) {
          final games = (event.snapshot.value as Map?)?.values ?? [];
          return games
              .where((g) => g['players'].contains(playerId))
              .map((g) => GameStatistics.fromJson(g as Map))
              .toList();
        });
  }
}
```

#### 3. UI 実装

**File**: lib/screens/statistics_screen.dart (NEW)

```dart
class StatisticsScreen extends StatelessWidget {
  final String playerId;
  
  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(title: const Text('統計情報')),
      body: FutureBuilder<PlayerStats>(
        future: _statsService.getPlayerStats(playerId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final stats = snapshot.data!;
            return ListView(
              children: [
                // ウィンレート表示
                StatCard(
                  title: 'ウィンレート',
                  value: '${(stats.winRate * 100).toStringAsFixed(1)}%',
                  subtitle: '${stats.wins} 勝 ${stats.losses} 敗',
                ),
                // 平均ターン数
                StatCard(
                  title: '平均ターン数',
                  value: stats.averageTurns.toStringAsFixed(1),
                ),
                // ゲーム履歴
                GameHistoryWidget(playerId: playerId),
              ],
            );
          }
          return const LoadingWidget();
        },
      ),
    );
  }
}
```

#### 4. リプレイ機能

**File**: lib/screens/replay_screen.dart (NEW)

```dart
class ReplayScreen extends StatefulWidget {
  final GameStatistics statistics;
  
  @override
  Widget build(context) {
    return GameScreen(
      isReplay: true,
      moves: statistics.moveHistory,
      onMoveStep: (index) {
        // リプレイの指定ステップに移動
      },
    );
  }
}
```

---

## 🎵 Phase 2D: マルチメディア・ポーランド

### 目標: サウンド・多言語対応・UI ポーランド

**期間**: 2026-10-22 ～ 2026-10-31 (1.5週間)

### 実装内容

#### 1. サウンド・効果音実装

**File**: lib/services/audio_service.dart (NEW)

```dart
class AudioService {
  late final AudioPlayer _audioPlayer;
  late final AudioCache _audioCache;
  
  Future<void> initialize() async {
    _audioCache = AudioCache(prefix: 'assets/sounds/');
    _audioPlayer = AudioPlayer();
  }
  
  // ゲーム音声を再生
  Future<void> playSound(SoundEffect effect) async {
    try {
      await _audioCache.play('${effect.filename}.mp3');
    } catch (e) {
      debugPrint('Failed to play sound: $e');
    }
  }
  
  // BGM を再生
  Future<void> playBGM(String trackName) async {
    await _audioPlayer.play(AssetSource('music/$trackName.mp3'));
  }
}

enum SoundEffect {
  pieceTap('piece_tap'),
  pieceMove('piece_move'),
  capture('capture'),
  turnSwitch('turn_switch'),
  gameWon('game_won'),
  gameOver('game_over'),
  ;
  
  final String filename;
  const SoundEffect(this.filename);
}
```

**実装内容**:
- 駒タップ音
- 駒移動音
- 奪取音
- ターン切り替え音
- ゲーム終了音
- BGM (3トラック)

#### 2. 多言語対応

**File**: lib/l10n/app_localizations.dart (NEW)

```dart
class AppLocalizations {
  static const List<Locale> supportedLocales = [
    Locale('ja'),
    Locale('en'),
    Locale('zh'),
    Locale('ko'),
  ];
  
  static Map<String, Map<String, String>> translations = {
    'ja': {
      'appTitle': '紋取り',
      'playGame': 'ゲーム開始',
      'playerA': 'プレイヤーA',
      'playerB': 'プレイヤーB',
      'wins': '勝利',
      'losses': '敗北',
      'statistics': '統計情報',
      'settings': '設定',
    },
    'en': {
      'appTitle': 'Mondori',
      'playGame': 'Start Game',
      'playerA': 'Player A',
      'playerB': 'Player B',
      'wins': 'Wins',
      'losses': 'Losses',
      'statistics': 'Statistics',
      'settings': 'Settings',
    },
    // ... 他の言語
  };
}
```

#### 3. UI ポーランド・最適化

**実装項目**:

- ✅ ダークモード対応
- ✅ 大画面 (タブレット) 対応
- ✅ アクセシビリティ改善
- ✅ アニメーション調整
- ✅ カラーテーマカスタマイズ
- ✅ フォントサイズ調整

**File**: lib/theme/app_theme.dart (拡張)

```dart
class AppTheme {
  static ThemeData lightTheme({
    Color primaryColor = Colors.blue,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
    );
  }
  
  static ThemeData darkTheme({
    Color primaryColor = Colors.blue,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
    );
  }
}
```

---

## 📊 Phase 2 テスト計画

### テストケース目標: 100 追加テストケース

```
AI Engine Tests:         30 cases
├─ Minimax algorithm     10
├─ Alpha-beta pruning    8
├─ Evaluation function   8
└─ Move generation       4

Online Game Tests:       30 cases
├─ Matchmaking          10
├─ Game session         10
├─ Real-time sync        8
└─ Disconnection handling 2

Statistics Tests:        20 cases
├─ Data recording       10
├─ Retrieval & query    10

Multi-media Tests:       10 cases
├─ Audio playback        5
├─ Localization          5

Integration Tests:       10 cases
└─ Full workflows       10

Total: 100 cases
```

---

## 📈 Phase 2 スケジュール

```
Week 1-2 (09-15~09-30): Phase 2A: AI 対戦
├─ ゲーム木探索実装
├─ 評価関数実装
├─ 難易度レベル実装
└─ UI 実装・テスト

Week 2.5-4 (09-30~10-15): Phase 2B: オンライン対戦基盤
├─ Firebase セットアップ
├─ ゲームサーバー実装
├─ リアルタイム通信実装
├─ マッチングシステム実装
└─ ネットワークテスト

Week 4-5 (10-15~10-22): Phase 2C: 統計・履歴
├─ 統計データモデル
├─ 統計記録サービス
├─ UI 実装
└─ リプレイ機能実装

Week 5-6 (10-22~10-31): Phase 2D: マルチメディア
├─ サウンド実装
├─ 多言語対応
├─ UI ポーランド
├─ 最終テスト
└─ v1.0 リリース準備
```

---

## 🎯 成功基準

| 項目 | 目標 | 評価 |
|-----|:---:|:---:|
| **AI テスト** | 30 ケース 100% | ✅ |
| **オンライン機能** | 正常動作検証 | ✅ |
| **統計機能** | 完全実装 | ✅ |
| **マルチメディア** | 4言語対応 | ✅ |
| **全体テスト** | 100 ケース追加 | ✅ |
| **パフォーマンス** | Phase 1 以上 | ✅ |
| **バグ件数** | 0 件 | ✅ |
| **スケジュール** | 2026-10-31 | ✅ |

---

## 📝 次のアクション

1. ✅ Phase 2 実装計画完成
2. 📋 Firebase プロジェクト設定
3. 📋 API 設計・仕様書作成
4. 📋 実装開始 (09-15)
5. 📋 テスト実施 (並行)
6. 📋 v1.0 リリース (10-31)

---

**フェーズ**: Phase 2（計画段階）  
**ステータス**: 📋 実装準備中  
**開始予定**: 2026-09-15  
**完了予定**: 2026-10-31  
**リリース対象**: v1.0 正式版
