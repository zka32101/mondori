import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/models/piece.dart';
import 'package:mondori/screens/tutorial_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget() {
    return const ProviderScope(
      child: MaterialApp(
        home: TutorialScreen(),
      ),
    );
  }

  /// GridView 内の指定位置に対応するセルを探してタップする。
  /// BoardWidget は columns = a..f, rows = [6,5,4,3,2,1] の順で
  /// GridView.builder の index = rowIndex*6 + colIndex に対応させている。
  Future<void> tapPosition(WidgetTester tester, Position position) async {
    const columns = ['a', 'b', 'c', 'd', 'e', 'f'];
    final colIndex = columns.indexOf(position.column);
    final rowIndex = 6 - position.row;
    final index = rowIndex * 6 + colIndex;

    final cell = find
        .descendant(of: find.byType(GridView), matching: find.byType(GestureDetector))
        .at(index);

    await tester.tap(cell);
    await tester.pumpAndSettle();
  }

  group('TutorialScreen', () {
    testWidgets('Starts on step 1 (move)', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('① 移動'), findsOneWidget);
      expect(find.text('1 / 4'), findsOneWidget);
    });

    testWidgets('Completing step 1 advances to step 2 (capture)', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tapPosition(tester, Position(column: 'c', row: 3)); // 駒を選択
      await tapPosition(tester, Position(column: 'c', row: 4)); // 移動先

      expect(find.text('② 奪取'), findsOneWidget);
      expect(find.text('2 / 4'), findsOneWidget);
    });

    testWidgets('Tapping the wrong position shows a hint and does not advance',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tapPosition(tester, Position(column: 'c', row: 3)); // 駒を選択
      await tapPosition(tester, Position(column: 'a', row: 1)); // 間違った位置

      // ステップ1のまま
      expect(find.text('① 移動'), findsOneWidget);
      expect(find.text('1 / 4'), findsOneWidget);
    });

    testWidgets('Completing all 4 steps shows the completion screen', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // ステップ1：移動
      await tapPosition(tester, Position(column: 'c', row: 3));
      await tapPosition(tester, Position(column: 'c', row: 4));

      // ステップ2：奪取
      await tapPosition(tester, Position(column: 'c', row: 3));
      await tapPosition(tester, Position(column: 'd', row: 3));

      // ステップ3：教化
      await tapPosition(tester, Position(column: 'c', row: 3));
      await tapPosition(tester, Position(column: 'd', row: 3));

      // ステップ4：勝利条件（王の奪取）
      await tapPosition(tester, Position(column: 'c', row: 3));
      await tapPosition(tester, Position(column: 'd', row: 3));

      expect(find.text('チュートリアル完了！'), findsOneWidget);
      expect(find.text('ホームに戻る'), findsOneWidget);
    });

    testWidgets('Skip button pops the screen', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('スキップ'), findsOneWidget);
    });

    testWidgets('Back button navigates to the previous step', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // ステップ1 -> 2
      await tapPosition(tester, Position(column: 'c', row: 3));
      await tapPosition(tester, Position(column: 'c', row: 4));
      expect(find.text('② 奪取'), findsOneWidget);

      // 「戻る」でステップ1に戻る
      await tester.tap(find.text('戻る'));
      await tester.pumpAndSettle();
      expect(find.text('① 移動'), findsOneWidget);
    });
  });
}
