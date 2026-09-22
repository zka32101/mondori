import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/providers/settings_provider.dart';
import 'package:mondori/screens/achievements_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget() {
    return const ProviderScope(
      child: MaterialApp(home: AchievementsScreen()),
    );
  }

  group('AchievementsScreen', () {
    testWidgets('Shows the full achievement list with none unlocked initially',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('初勝利'), findsOneWidget);
      expect(find.text('基礎を学んだ証'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('Shows 0 / N achieved when nothing is unlocked', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('0 / '), findsOneWidget);
    });

    testWidgets('Shows an unlocked achievement once its condition is met',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 実績評価は settingsProvider の tutorialCompleted も参照するため、
      // それを先に true にしてから画面を開く。
      await container.read(settingsProvider.notifier).setTutorialCompleted(true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AchievementsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.textContaining('1 / '), findsOneWidget);
    });

    testWidgets('Back button is present and has an accessible tooltip', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byTooltip('戻る'), findsOneWidget);
    });
  });
}
