# 🎯 Next Steps: Phase 1B & Phase 1C ロードマップ

**現在のステータス**: Phase 1A ✅ 完了 (2026-09-02)  
**目標**: v1.0-beta リリース (2026-09-15)  
**最終目標**: v1.0 正式リリース (2026-10-31)

---

## 📋 Phase 1B: パイルール実装 & 統合テスト

### タスク1: パイルール UI 実装 (推定: 2-3時間)

#### パイルール とは？
先手有利を抑制するため、後手がプレイヤーAの初手を見てから陣営を交換できるルール。

#### 実装内容

1. **初手判定ロジック追加** (`game_screen.dart`)
   ```dart
   int moveCount = 0;  // 既存
   bool pieModeActive = moveCount == 1;  // 初手後のみ True
   ```

2. **陣営交換画面作成** (`lib/screens/pie_rule_dialog.dart`)
   ```dart
   class PieRuleDialog extends StatelessWidget {
     // プレイヤーA の初手を表示
     // 「陣営を交換しますか？」ダイアログ
     // Yes / No ボタン
   }
   ```

3. **盤面 90° 回転エフェクト** (オプション)
   ```dart
   // AnimationController で回転
   Transform.rotate(
     angle: _rotationAnimation.value * pi / 2,
     child: BoardWidget(...)
   )
   ```

4. **プレイヤーID交換ロジック**
   ```dart
   if (userAcceptedPieRule) {
     currentPlayer = PlayerSide.B;  // 後手スタート
     // 盤面は 90° 回転表示（視覚的効果）
   }
   ```

#### テスト方法
```
手動テスト:
1. ゲーム開始 (モード選択 → GameScreen)
2. プレイヤーA が駒を 1手 移動
3. 陣営交換ダイアログが表示される
4. ✅ Yes → 盤面回転、B スタート
   ❌ No  → A が続行
```

**所要時間**: 2-3時間

---

### タスク2: ウィジェットテスト (推定: 3-4時間)

#### test/widgets/board_widget_test.dart

```dart
testWidgets('タップでピース選択できる', (WidgetTester tester) async {
  // 1. BoardWidget を build
  // 2. ピースをタップ
  // 3. onPieceSelected コールバック検証
  // 4. セルのカラー変更を検証
});

testWidgets('移動可能位置に脈動エフェクトが表示', (WidgetTester tester) async {
  // 1. ピース選択
  // 2. 移動可能位置を探す
  // 3. ScaleTransition が実行中か確認
});

testWidgets('敵駒タップで奪取', (WidgetTester tester) async {
  // 隣接する敵駒をタップ
  // onPositionTapped が呼ばれ、奪取処理が実行
});
```

#### test/screens/game_screen_test.dart

```dart
testWidgets('ゲームフロー: 開始→移動→ターン切替→終了', 
    (WidgetTester tester) async {
  // E2E テスト
  // 1. GameScreen 表示
  // 2. プレイヤーA が駒選択・移動
  // 3. プレイヤー表示が B に変更
  // 4. プレイヤーB が操作
  // 5. ターン数が増加
});

testWidgets('王奪取でゲーム終了ダイアログ表示', 
    (WidgetTester tester) async {
  // 王刻印を奪取したら、ゲーム終了ダイアログが表示
});
```

#### test/screens/game_mode_screen_test.dart

```dart
testWidgets('ホットシートプレイをタップ→GameScreen へ遷移', 
    (WidgetTester tester) async {
  // 1. GameModeScreen 表示
  // 2. ホットシートプレイカードをタップ
  // 3. GameScreen が表示される
});

testWidgets('AI対戦・オンライン対戦は準備中状態', 
    (WidgetTester tester) async {
  // グレイアウト + 「準備中」バッジ表示確認
  // タップで SnackBar 表示確認
});
```

**テスト総数**: 10+ テストケース  
**所要時間**: 3-4時間

---

## 📝 Phase 1C: 実機テスト & バグ修正

### タスク3: 実機テスト (推定: 2-3時間)

#### Android テスト環境
```bash
# Android エミュレータで実行
flutter run -d emulator-5554

# チェックリスト:
- [ ] ホーム画面正常に表示
- [ ] ゲームモード選択画面が開く
- [ ] ホットシートプレイで GameScreen 遷移
- [ ] 駒選択・移動がタップで反応
- [ ] アニメーションが滑らか (60fps)
- [ ] 王奪取時にゲーム終了ダイアログ表示
- [ ] ゲームリセット機能が動作
```

#### iOS テスト環境
```bash
# iOS シミュレータで実行
flutter run -d "iPhone 15"

# 同じチェックリスト
```

#### パフォーマンス検証
```bash
# Widget tree の深さを確認
flutter run --profile

# CPU/メモリ使用率
# - 期待値: CPU <30%, Memory <100MB
# - 30手時点でも安定動作確認
```

**所要時間**: 2-3時間

---

### タスク4: バグ修正 & 最適化

#### 予想されるバグ
- [ ] 駒選択後のキャンセル ボタンが見えにくい
- [ ] 移動可能位置の脈動が画面によって見えない
- [ ] ゲーム統計パネルの表示崩れ (小画面)
- [ ] パイルール ダイアログが長く見える

#### 修正方針
```
優先度 High (v1.0 必須):
- [ ] クリティカルバグ
- [ ] UIの見栄え

優先度 Medium (v1.1 推奨):
- [ ] パフォーマンス微調整
- [ ] アニメーション調整

優先度 Low (Phase 2 以降):
- [ ] オプション機能の追加
```

---

## ✅ チェックリスト

### Phase 1B (2026-09-05 完了目標)
- [ ] パイルール UI 実装
- [ ] パイルール ダイアログ表示・選択
- [ ] 陸営交換ロジック実装
- [ ] 盤面 90° 回転表示 (オプション)

### Phase 1C (2026-09-10 完了目標)
- [ ] ウィジェットテスト (10+ ケース)
- [ ] 統合テスト実装
- [ ] Android 実機テスト
- [ ] iOS 実機テスト
- [ ] バグ修正・最適化

### v1.0-beta リリース準備 (2026-09-15)
- [ ] テスト全パス確認
- [ ] コードレビュー完了
- [ ] ドキュメント更新完了
- [ ] リリースノート準備

---

## 🚀 コマンドリファレンス

### テスト実行
```bash
# 全テスト実行
flutter test

# 特定のテストファイル
flutter test test/models/piece_test.dart
flutter test test/models/board_test.dart
flutter test test/widgets/board_widget_test.dart

# テストカバレッジ
flutter test --coverage
lcov --list coverage/lcov.info
```

### アプリ実行
```bash
# 通常実行
flutter run

# プロファイル (パフォーマンス測定)
flutter run --profile

# リリース (最適化版)
flutter run --release

# 特定デバイス
flutter run -d emulator-5554  # Android
flutter run -d "iPhone 15"    # iOS
```

### コード品質確認
```bash
# lint チェック
flutter analyze

# フォーマット
dart format lib/ test/

# パッケージアップデート
flutter pub upgrade
```

---

## 📊 進度追跡

```
Phase 1 Progress:
┌─────────────────────────────────┐
│ Phase 1A: UI改善      [████████░░] 100% ✅
│ Phase 1B: テスト      [██████░░░░] 60%  🟡
│ Phase 1C: 統合テスト  [██░░░░░░░░] 20%  📋
├─────────────────────────────────┤
│ 全体: Phase 1          [███████░░] 70%  🟡
│ v1.0-beta 準備        [████░░░░░░] 40%  📋
└─────────────────────────────────┘
```

---

## 📞 問い合わせ & サポート

### 実装中に問題が発生した場合

1. **テストがコンパイルできない**
   ```bash
   flutter pub get
   flutter pub upgrade flutter_test
   ```

2. **アニメーションが動作しない**
   - `vsync: this` の確認
   - `SingleTickerProviderStateMixin` の継承確認

3. **パイルール ロジックがわからない**
   - `IMPLEMENTATION.md` の "L3 先手有利抑制" セクション参照

---

**Next Review**: Phase 1B 完了時 (2026-09-05)  
**目標リリース**: 2026-10-31  
**プロジェクト進行中**: ✅ オントラック
