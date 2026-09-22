import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/l10n/app_strings.dart';

void main() {
  group('AppStrings - Supported locales', () {
    test('Includes Japanese, English, Chinese, and Korean', () {
      final codes = AppStrings.supportedLocales.map((l) => l.languageCode).toSet();
      expect(codes, {'ja', 'en', 'zh', 'ko'});
    });

    test('localeName returns display name for each supported locale', () {
      expect(AppStrings.localeName('ja'), '日本語');
      expect(AppStrings.localeName('en'), 'English');
      expect(AppStrings.localeName('zh'), '中文');
      expect(AppStrings.localeName('ko'), '한국어');
    });

    test('localeName falls back to the code itself for unknown locales', () {
      expect(AppStrings.localeName('fr'), 'fr');
    });
  });

  group('AppStrings - Translations', () {
    test('Returns the correct string for each supported locale', () {
      expect(AppStrings(const Locale('ja')).startGame, 'ゲーム開始');
      expect(AppStrings(const Locale('en')).startGame, 'Start Game');
      expect(AppStrings(const Locale('zh')).startGame, '开始游戏');
      expect(AppStrings(const Locale('ko')).startGame, '게임 시작');
    });

    test('Falls back to English for an unsupported locale', () {
      expect(AppStrings(const Locale('fr')).startGame, 'Start Game');
    });

    test('Falls back to the key itself for an unknown key', () {
      expect(AppStrings(const Locale('en')).get('doesNotExist'), 'doesNotExist');
    });

    test('Common navigation keys resolve to a distinct string in each locale', () {
      // 4言語すべてに翻訳が存在するキーでは、英語フォールバックに落ちて
      // 全言語が同じ文字列になることはないはず。
      const keys = ['startGame', 'aiBattle', 'settings', 'theme'];
      for (final key in keys) {
        final values = {
          for (final locale in AppStrings.supportedLocales)
            locale.languageCode: AppStrings(locale).get(key),
        };
        expect(
          values.values.toSet().length,
          4,
          reason: 'Key "$key" should have 4 distinct translations, got $values',
        );
      }
    });
  });

  group('AppStringsContext extension', () {
    testWidgets('context.strings resolves to the current locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) => Text(context.strings.startGame),
          ),
        ),
      );

      expect(find.text('Start Game'), findsOneWidget);
    });
  });
}
