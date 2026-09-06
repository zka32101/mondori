import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/main.dart';
import 'package:mondori/screens/game_screen.dart';

void main() {
  group('Pie Rule Flow Integration Tests', () {
    testWidgets('E2E: パイルール - 初手実行後にダイアログが表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MondoriApp());
      await tester.pumpAndSettle();

      // ゲーム開始
      await tester.tap(find.text('ゲーム開始'));
      await tester.pumpAndSettle();

      // ホットシートプレイ選択
      await tester.tap(find.text('ホットシートプレイ'));
      await tester.pumpAndSettle();

      // GameScreen が表示される
      expect(find.byType(GameScreen), findsOneWidget);

      // 初期状態: パイルール情報パネルは表示されない
      expect(find.text('パイルール'), findsNothing);

      // a1 の駒をタップ（初手実行）
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // パイルールダイアログが表示される
      expect(find.text('陸営を交換しますか？'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
    });

    testWidgets('E2E: パイルール - Yes で陸営交換（チームA ↔ チームB）',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MondoriApp());
      await tester.pumpAndSettle();

      // ゲーム開始
      await tester.tap(find.text('ゲーム開始'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ホットシートプレイ'));
      await tester.pumpAndSettle();

      // 初期プレイヤーは A
      expect(find.text('プレイヤーA'), findsOneWidget);

      // 初手を実行
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // パイルールダイアログが表示される
      expect(find.text('陸営を交換しますか？'), findsOneWidget);

      // Yes をタップ
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle(const Duration(milliseconds: 700));

      // パイルール情報パネルが表示される
      expect(find.text('パイルール'), findsOneWidget);
      expect(find.text('陸営交換: 実行済み'), findsOneWidget);

      // プレイヤーが B に変更されている
      expect(find.text('プレイヤーB'), findsOneWidget);

      // ターン数は 1
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('E2E: パイルール - No で通常続行',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MondoriApp());
      await tester.pumpAndSettle();

      // ゲーム開始
      await tester.tap(find.text('ゲーム開始'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ホットシートプレイ'));
      await tester.pumpAndSettle();

      // 初期プレイヤーは A
      expect(find.text('プレイヤーA'), findsOneWidget);

      // 初手を実行
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // パイルールダイアログが表示される
      expect(find.text('陸営を交換しますか？'), findsOneWidget);

      // No をタップ
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle(const Duration(milliseconds: 700));

      // パイルールダイアログが閉じられる
      expect(find.text('陸営を交換しますか？'), findsNothing);

      // プレイヤーが B に変更される（通常のターン交代）
      expect(find.text('プレイヤーB'), findsOneWidget);

      // ターン数は 1
      expect(find.text('1'), findsOneWidget);

      // パイルール情報パネルは表示されない（No を選択した場合）
      expect(find.text('陸営交換: スキップ'), findsNothing);
    });

    testWidgets('E2E: パイルール - 盤面回転アニメーションの確認（Yes 選択時）',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MondoriApp());
      await tester.pumpAndSettle();

      // ゲーム開始
      await tester.tap(find.text('ゲーム開始'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ホットシートプレイ'));
      await tester.pumpAndSettle();

      // 初手を実行
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // パイルールダイアログが表示
      expect(find.text('陸営を交換しますか？'), findsOneWidget);

      // Yes をタップ
      await tester.tap(find.text('Yes'));

      // アニメーション実行中：Transform.rotate が動作
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Transform), findsWidgets);

      // アニメーション完了待機
      await tester.pumpAndSettle(const Duration(milliseconds: 700));

      // 最終状態確認
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('プレイヤーB'), findsOneWidget);
    });

    testWidgets('E2E: パイルール - 2手目以降は表示されない',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MondoriApp());
      await tester.pumpAndSettle();

      // ゲーム開始
      await tester.tap(find.text('ゲーム開始'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ホットシートプレイ'));
      await tester.pumpAndSettle();

      // 1手目を実行
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // パイルールダイアログが表示
      expect(find.text('陸営を交換しますか？'), findsOneWidget);

      // No を選択して通常続行
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle(const Duration(milliseconds: 700));

      // 2手目を実行
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // パイルールダイアログが表示されない（2手目以降は表示されない）
      expect(find.text('陸営を交換しますか？'), findsNothing);

      // ターン数が 2 に増加
      expect(find.text('2'), findsOneWidget);
    });
  });
}
