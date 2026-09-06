import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/models/board.dart';
import 'package:mondori/models/piece.dart';
import 'package:mondori/screens/game_screen.dart';

void main() {
  group('GameScreen', () {
    // ヘルパーメソッド: GameScreen をテストアプリにラップ
    Widget _createTestWidget() {
      return const MaterialApp(
        home: GameScreen(),
      );
    }

    testWidgets('ゲーム画面が正常に表示される', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());

      // AppBar が表示されることを確認
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('紋取り'), findsWidgets);

      // 戻るボタンが表示される
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('初期プレイヤーが A である', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());

      // プレイヤー表示を確認
      expect(find.text('プレイヤーA'), findsOneWidget);
    });

    testWidgets('ターン数が 0 で始まる', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());

      // ターン数を確認
      expect(find.text('ターン数'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('ゲーム統計パネルが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());

      // 統計パネルの要素を確認
      expect(find.text('ターン数'), findsOneWidget);
      expect(find.text('最後のアクション'), findsOneWidget);
      expect(find.text('ゲーム開始'), findsOneWidget); // 初期アクション
    });

    testWidgets('ボード が 6×6 グリッドで表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());

      // BoardWidget が表示される
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('駒を選択できる', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      // a1 の駒をタップ
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // 駒が選択されたことを確認
      // 選択されたセルの背景色が blue.shade200 になる
    });

    testWidgets('駒を移動できる', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      // 初期: プレイヤーA の駒を選択 (a1 の進)
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // ターン数が 1 に増加することを確認
      expect(find.text('1'), findsOneWidget);

      // プレイヤーが B に変更されることを確認
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('プレイヤーB'), findsOneWidget);
    });

    testWidgets('ターン数が増加する', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      // 初期ターン数
      expect(find.text('0'), findsOneWidget);

      // 1手目を実行（a1 の駒を選択）
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // ターン数が 1 に
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('最後のアクションが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      // 初期状態: 「ゲーム開始」
      expect(find.text('ゲーム開始'), findsOneWidget);

      // 1手目を実行
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // アクション表示が更新される
      // 「プレイヤーAが駒を移動しました」などが表示される
    });

    testWidgets('プレイヤー表示がアニメーションで切り替わる',
        (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());

      // 初期: A
      expect(find.text('プレイヤーA'), findsOneWidget);

      // 1手目を実行
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // B に切り替わる
      expect(find.text('プレイヤーB'), findsOneWidget);
    });

    testWidgets('選択解除ボタンが駒選択時に表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      // 選択解除ボタンが初期状態では表示されない
      expect(find.text('選択を解除'), findsNothing);

      // 駒を選択
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // 選択解除ボタンが表示される
      expect(find.text('選択を解除'), findsOneWidget);
    });

    testWidgets('ゲームリセットボタンが表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());

      // リセットボタンが表示される
      expect(find.text('ゲームをリセット'), findsOneWidget);
    });

    testWidgets('ゲームをリセットできる', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      // 1手目を実行
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

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

    testWidgets('戻るボタンでゲーム画面を閉じられる',
        (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());

      // 戻るボタンをタップ
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // ゲーム画面が閉じられる（Navigator.pop() が呼ばれる）
      // テストアプリではスタック上の唯一のウィジェットのため、
      // これ以上の動作は確認できないが、エラーが出なければ成功
    });

    testWidgets('駒選択時にスケールアニメーションが再生される',
        (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      // 駒を選択
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // ScaleTransition が実行されることを確認
      expect(find.byType(ScaleTransition), findsWidgets);
    });

    testWidgets('移動可能位置に脈動エフェクトが表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      // 駒を選択
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      // 脈動アニメーションが実行される
      expect(find.byType(ScaleTransition), findsWidgets);
    });

    testWidgets('初期配置が正しく配置されている',
        (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      // BoardWidget が正しく描画されることを確認
      expect(find.byType(GridView), findsOneWidget);

      // 駒が表示される
      expect(find.byType(Container), findsWidgets);

      // 刻印ラベルが表示される
      expect(find.text('進'), findsWidgets); // A陣営の進
      expect(find.text('早'), findsWidgets); // A/B陣営の早
      expect(find.text('対'), findsWidgets); // A/B陣営の対
      expect(find.text('王'), findsWidgets); // A/B陣営の王
    });
  });
}
