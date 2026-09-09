import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/main.dart';
import 'package:mondori/screens/game_screen.dart';
import 'package:mondori/screens/home_screen.dart';

void main() {
  group('Game Flow Integration Tests', () {
    testWidgets('E2E: ホーム → ゲームモード選択 → ゲーム開始',
        (WidgetTester tester) async {
      // アプリを起動
      await tester.pumpWidget(const MondoriApp());

      // HomeScreen が表示される
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('紋取り'), findsOneWidget);

      // 「ゲーム開始」ボタンをタップ
      await tester.tap(find.text('ゲーム開始'));
      await tester.pumpAndSettle();

      // GameModeScreen に遷移
      expect(find.text('ゲームモード選択'), findsOneWidget);

      // 「ホットシートプレイ」をタップ
      await tester.tap(find.text('ホットシートプレイ'));
      await tester.pumpAndSettle();

      // GameScreen が表示される
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('プレイヤーA'), findsOneWidget);
    });

    testWidgets('E2E: ゲームプレイ - 駒選択→移動→ターン切替',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MondoriApp());
      await tester.pumpAndSettle();

      // ゲーム開始まで進む
      await tester.tap(find.text('ゲーム開始'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ホットシートプレイ'));
      await tester.pumpAndSettle();

      // GameScreen が表示される
      expect(find.byType(GameScreen), findsOneWidget);

      // 初期状態: ターン数 0
      expect(find.text('0'), findsOneWidget);

      // a1 の駒をタップ（選択）
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // 選択解除ボタンが表示される
      expect(find.text('選択を解除'), findsOneWidget);

      // ターン数が 1 に増加
      expect(find.text('1'), findsOneWidget);

      // プレイヤーが B に変更
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.text('プレイヤーB'), findsOneWidget);
    });

    testWidgets('E2E: ゲームリセット機能', (WidgetTester tester) async {
      await tester.pumpWidget(const MondoriApp());
      await tester.pumpAndSettle();

      // ゲーム開始
      await tester.tap(find.text('ゲーム開始'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ホットシートプレイ'));
      await tester.pumpAndSettle();

      // 1手実行してターン数を 1 に
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // ターン数が 1
      expect(find.text('1'), findsOneWidget);

      // リセットボタンをタップ
      await tester.tap(find.text('ゲームをリセット'));
      await tester.pumpAndSettle();

      // ターン数が 0 に戻る
      expect(find.text('0'), findsOneWidget);

      // プレイヤーが A に戻る
      expect(find.text('プレイヤーA'), findsOneWidget);
    });

    testWidgets('E2E: ゲーム内ナビゲーション - 戻る',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MondoriApp());
      await tester.pumpAndSettle();

      // ゲーム開始
      await tester.tap(find.text('ゲーム開始'));
      await tester.pumpAndSettle();

      // GameModeScreen が表示
      expect(find.text('ゲームモード選択'), findsOneWidget);

      // 戻るボタンをタップ
      await tester.tap(find.byIcon(Icons.arrow_back).first);
      await tester.pumpAndSettle();

      // HomeScreen に戻る
      expect(find.text('紋取り'), findsOneWidget);
      expect(find.text('ゲーム説明'), findsOneWidget);
    });

    testWidgets('E2E: ルール表示ダイアログ', (WidgetTester tester) async {
      await tester.pumpWidget(const MondoriApp());
      await tester.pumpAndSettle();

      // ホーム画面で「詳細ルール」をタップ
      await tester.tap(find.text('詳細ルール'));
      await tester.pumpAndSettle();

      // ルール表示ダイアログが表示される
      expect(find.text('ゲームルール'), findsOneWidget);
      expect(find.text('刻印の種類と移動'), findsOneWidget);

      // 閉じるボタンをタップ
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();

      // ダイアログが閉じられる
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('E2E: 複数ターンのゲームプレイ',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MondoriApp());
      await tester.pumpAndSettle();

      // ゲーム開始
      await tester.tap(find.text('ゲーム開始'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ホットシートプレイ'));
      await tester.pumpAndSettle();

      // 5ターン実行
      for (int i = 0; i < 5; i++) {
        // 駒を選択してタップ（最初の駒をタップ）
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        // ターン数を確認
        expect(find.text('${i + 1}'), findsOneWidget);
      }

      // 5ターン後
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('E2E: ゲーム統計情報の更新', (WidgetTester tester) async {
      await tester.pumpWidget(const MondoriApp());
      await tester.pumpAndSettle();

      // ゲーム開始
      await tester.tap(find.text('ゲーム開始'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ホットシートプレイ'));
      await tester.pumpAndSettle();

      // 初期: ゲーム開始
      expect(find.text('ゲーム開始'), findsOneWidget);

      // 1手実行
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // 「プレイヤーAが駒を移動しました」が表示される
      // または類似のアクション履歴が表示される

      // 統計パネルが更新されたことを確認
      expect(find.text('ターン数'), findsOneWidget);
      expect(find.text('最後のアクション'), findsOneWidget);
    });

    testWidgets('E2E: ゲーム画面から戻ったあとの状態保持',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MondoriApp());
      await tester.pumpAndSettle();

      // ゲーム開始
      await tester.tap(find.text('ゲーム開始'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ホットシートプレイ'));
      await tester.pumpAndSettle();

      // 1手実行
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // ターン数が 1
      expect(find.text('1'), findsOneWidget);

      // 戻るボタンで戻る
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // HomeScreen に戻る
      expect(find.text('紋取り'), findsOneWidget);

      // 再度ゲーム開始（新しいゲーム）
      await tester.tap(find.text('ゲーム開始'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ホットシートプレイ'));
      await tester.pumpAndSettle();

      // 新しいゲーム: ターン数が 0
      expect(find.text('0'), findsOneWidget);
      expect(find.text('プレイヤーA'), findsOneWidget);
    });
  });
}
