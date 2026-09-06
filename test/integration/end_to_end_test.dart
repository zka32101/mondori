import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/main.dart';
import 'package:mondori/screens/game_screen.dart';
import 'package:mondori/screens/home_screen.dart';

void main() {
  group('End-to-End Integration Tests', () {
    testWidgets('E2E: 完全なゲームセッション - ホーム→ゲーム→リセット→ホーム',
        (WidgetTester tester) async {
      // 1. アプリ起動
      await tester.pumpWidget(const MondoriApp());
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('紋取り'), findsOneWidget);

      // 2. ゲーム開始ボタン押下
      await tester.tap(find.text('ゲーム開始'));
      await tester.pumpAndSettle();

      // 3. ゲームモード選択画面へ遷移
      expect(find.text('ゲームモード選択'), findsOneWidget);

      // 4. ホットシートプレイ選択
      await tester.tap(find.text('ホットシートプレイ'));
      await tester.pumpAndSettle();

      // 5. ゲーム画面表示
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('プレイヤーA'), findsOneWidget);
      expect(find.text('0'), findsOneWidget); // ターン数 0

      // 6. 複数手を実行 (5ターン)
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      }

      // 7. ターン数が 5 に達していることを確認
      expect(find.text('5'), findsOneWidget);

      // 8. リセットボタンをタップ
      await tester.tap(find.text('ゲームをリセット'));
      await tester.pumpAndSettle();

      // 9. リセット後の状態確認
      expect(find.text('0'), findsOneWidget); // ターン数が 0 に戻る
      expect(find.text('プレイヤーA'), findsOneWidget); // プレイヤーが A に戻る

      // 10. 戻るボタンでホームに戻る
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // 11. ホーム画面に戻っている
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('紋取り'), findsOneWidget);
      expect(find.text('ゲーム説明'), findsOneWidget);
    });

    testWidgets('E2E: 複数ゲームセッションの独立性 - リセット後の新規ゲームは独立',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MondoriApp());
      await tester.pumpAndSettle();

      // 第1セッション: ゲーム開始 → 3手実行
      await tester.tap(find.text('ゲーム開始'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ホットシートプレイ'));
      await tester.pumpAndSettle();

      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      }

      // ターン数が 3
      expect(find.text('3'), findsOneWidget);

      // ゲームをリセット
      await tester.tap(find.text('ゲームをリセット'));
      await tester.pumpAndSettle();

      // リセット後の状態確認
      expect(find.text('0'), findsOneWidget);
      expect(find.text('プレイヤーA'), findsOneWidget);

      // 第2セッション: ホームに戻って新規ゲーム開始
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // ホーム画面に戻っている
      expect(find.byType(HomeScreen), findsOneWidget);

      // 再度ゲーム開始
      await tester.tap(find.text('ゲーム開始'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ホットシートプレイ'));
      await tester.pumpAndSettle();

      // 新規ゲーム: 状態がリセット
      expect(find.text('0'), findsOneWidget); // ターン数 0
      expect(find.text('プレイヤーA'), findsOneWidget); // プレイヤーA
      expect(find.byType(GameScreen), findsOneWidget);

      // 新規ゲームで1手実行
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // ターン数が 1 (独立した状態)
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('E2E: パイルール統合フロー - Yes/No どちらの経路でもゲーム続行可能',
        (WidgetTester tester) async {
      // セッション A: パイルール Yes 経路
      await tester.pumpWidget(const MondoriApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('ゲーム開始'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ホットシートプレイ'));
      await tester.pumpAndSettle();

      // 1手実行
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // パイルールダイアログ表示
      expect(find.text('陸営を交換しますか？'), findsOneWidget);

      // Yes を選択
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle(const Duration(milliseconds: 700));

      // ゲーム続行可能
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('プレイヤーB'), findsOneWidget); // 交換後

      // さらに2手実行
      for (int i = 0; i < 2; i++) {
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      }

      // ターン数が 3
      expect(find.text('3'), findsOneWidget);

      // ゲームをリセット
      await tester.tap(find.text('ゲームをリセット'));
      await tester.pumpAndSettle();

      // リセット確認
      expect(find.text('0'), findsOneWidget);
      expect(find.text('プレイヤーA'), findsOneWidget);

      // 戻ってホーム
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // セッション B: パイルール No 経路
      await tester.tap(find.text('ゲーム開始'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ホットシートプレイ'));
      await tester.pumpAndSettle();

      // 1手実行
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // パイルールダイアログ表示
      expect(find.text('陸営を交換しますか？'), findsOneWidget);

      // No を選択
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle(const Duration(milliseconds: 700));

      // ゲーム続行可能
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('プレイヤーB'), findsOneWidget); // 通常ターン交代

      // さらに2手実行
      for (int i = 0; i < 2; i++) {
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      }

      // ターン数が 3
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('E2E: 画面復帰テスト - バックボタン→再開時の状態保持',
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
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // パイルールダイアログ処理
      if (find.text('陸営を交換しますか？').evaluate().isNotEmpty) {
        await tester.tap(find.text('No'));
        await tester.pumpAndSettle(const Duration(milliseconds: 700));
      }

      // ターン数が 1
      expect(find.text('1'), findsOneWidget);

      // ゲーム画面から戻る
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // ホーム画面に戻る
      expect(find.byType(HomeScreen), findsOneWidget);

      // 再度ゲーム開始（新規ゲーム）
      await tester.tap(find.text('ゲーム開始'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ホットシートプレイ'));
      await tester.pumpAndSettle();

      // 新規ゲームの状態確認（前セッション状態は引き継がない）
      expect(find.text('0'), findsOneWidget); // 新規ターン数 0
      expect(find.text('プレイヤーA'), findsOneWidget); // 初期プレイヤーA
    });
  });
}
