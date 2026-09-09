import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/screens/game_mode_screen.dart';
import 'package:mondori/screens/game_screen.dart';

void main() {
  group('GameModeScreen', () {
    // ヘルパーメソッド: GameModeScreen をテストアプリにラップ
    Widget _createTestWidget() {
      return const MaterialApp(
        home: GameModeScreen(),
      );
    }

    testWidgets('ゲームモード選択画面が表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());

      // タイトルが表示される
      expect(find.text('ゲームモード選択'), findsOneWidget);

      // AppBar が表示される
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('紋取り'), findsOneWidget);
    });

    testWidgets('戻るボタンが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());

      // 戻るボタンが表示される
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('ホットシートプレイモードカードが表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());

      // ホットシートプレイカードの要素を確認
      expect(find.text('ホットシートプレイ'), findsOneWidget);
      expect(find.text('1台のデバイスで2人が交代でプレイします'),
          findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
    });

    testWidgets('AI対戦モードカードが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());

      // AI対戦カードの要素を確認
      expect(find.text('AI対戦'), findsOneWidget);
      expect(find.text('コンピュータ相手にプレイします'), findsOneWidget);
      expect(find.byIcon(Icons.android), findsOneWidget);
    });

    testWidgets('オンライン対戦モードカードが表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());

      // オンライン対戦カードの要素を確認
      expect(find.text('オンライン対戦'), findsOneWidget);
      expect(find.text('インターネット経由で他のプレイヤーと対戦します'),
          findsOneWidget);
      expect(find.byIcon(Icons.cloud), findsOneWidget);
    });

    testWidgets('AI対戦と オンライン対戦に「準備中」バッジが表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());

      // 「準備中」バッジの確認
      expect(find.text('準備中'), findsWidgets);
    });

    testWidgets('ホットシートプレイをタップするとGameScreenに遷移する',
        (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      // ホットシートプレイカードをタップ
      await tester.tap(find.text('ホットシートプレイ'));
      await tester.pumpAndSettle();

      // GameScreen が表示される
      expect(find.byType(GameScreen), findsOneWidget);
    });

    testWidgets('AI対戦をタップするとSnackBarが表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      // AI対戦をタップ
      await tester.tap(find.text('AI対戦'));
      await tester.pumpAndSettle();

      // SnackBar が表示される
      expect(find.text('AI対戦は今後のバージョンで実装予定です'),
          findsOneWidget);
    });

    testWidgets('オンライン対戦をタップするとSnackBarが表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      // オンライン対戦をタップ
      await tester.tap(find.text('オンライン対戦'));
      await tester.pumpAndSettle();

      // SnackBar が表示される
      expect(find.text('オンライン対戦は今後のバージョンで実装予定です'),
          findsOneWidget);
    });

    testWidgets('モードカードがスクロール可能である',
        (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());

      // SingleChildScrollView が存在する
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('戻るボタンで前の画面に戻る', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      // 戻るボタンをタップ
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // 前の画面に戻る（Navigator.pop() が呼ばれる）
    });

    testWidgets('モードカードのホバーエフェクト', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      // MouseRegion と AnimatedBuilder が存在する
      expect(find.byType(MouseRegion), findsWidgets);
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });

    testWidgets('各モードカードがCard Widgetで表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());

      // Card ウィジェットが複数表示される
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('各モードカードにアイコンが表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());

      // アイコンが表示される
      expect(find.byIcon(Icons.people), findsOneWidget);      // ホットシート
      expect(find.byIcon(Icons.android), findsOneWidget);     // AI
      expect(find.byIcon(Icons.cloud), findsOneWidget);       // オンライン
    });

    testWidgets('ゲームモード選択後にGameScreenが正常に動作する',
        (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      // ホットシートプレイをタップ
      await tester.tap(find.text('ホットシートプレイ'));
      await tester.pumpAndSettle();

      // GameScreen が表示されることを確認
      expect(find.byType(GameScreen), findsOneWidget);

      // GameScreen の要素が表示されることを確認
      expect(find.text('紋取り'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
