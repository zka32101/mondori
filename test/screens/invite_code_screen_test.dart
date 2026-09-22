import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/screens/invite_code_screen.dart';

void main() {
  Widget createTestWidget() {
    return const ProviderScope(
      child: MaterialApp(
        home: InviteCodeScreen(playerId: 'test-player'),
      ),
    );
  }

  group('InviteCodeScreen', () {
    testWidgets('Shows the host/join choice by default', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('コードを作成してホストする'), findsOneWidget);
      expect(find.text('コードを入力して参加する'), findsOneWidget);
    });

    testWidgets('Tapping "参加する" mode reveals a code input field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('コードを入力して参加する'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '参加する'), findsOneWidget);
      // ホスト側の選択肢はもう表示されない
      expect(find.text('コードを作成してホストする'), findsNothing);
    });

    testWidgets('Back button has an accessible tooltip', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byTooltip('戻る'), findsOneWidget);
    });

    testWidgets('Join button does nothing when the code field is empty', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('コードを入力して参加する'));
      await tester.pumpAndSettle();

      // 空欄のまま「参加する」を押しても _submitJoinCode は早期リターンし、
      // Firebase 呼び出しは発生しない（例外なく完了することを確認）。
      await tester.tap(find.widgetWithText(FilledButton, '参加する'));
      await tester.pumpAndSettle();

      // まだ参加モードの画面のまま
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
