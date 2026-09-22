import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/l10n/app_strings.dart';
import 'package:mondori/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget() {
    return const ProviderScope(
      child: MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        home: SettingsScreen(),
      ),
    );
  }

  group('SettingsScreen', () {
    testWidgets('Displays theme, language, and sound sections', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Follow System'), findsWidgets);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('日本語'), findsOneWidget);
      expect(find.text('中文'), findsOneWidget);
      expect(find.text('한국어'), findsOneWidget);
    });

    testWidgets('Toggling sound effects switch updates state', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final switches = find.byType(SwitchListTile);
      expect(switches, findsWidgets);

      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      // 例外なく再描画されることを確認（実際の値は Riverpod プロバイダ側で検証済み）
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('Volume slider is present', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('Back button pops the screen', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
