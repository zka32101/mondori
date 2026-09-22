import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mondori/l10n/app_strings.dart';
import 'package:mondori/providers/settings_provider.dart';
import 'package:mondori/screens/home_screen.dart';

void main() {
  runApp(const MondoriApp());
}

/// アプリのルートウィジェット
///
/// ProviderScope をここに内包することで、`MondoriApp()` を直接
/// pumpWidget するテストからも Riverpod プロバイダにアクセスできる
/// （main() 側だけで囲むと、テストが MondoriApp を直接使う場合に
/// ProviderScope が無くエラーになる）。
class MondoriApp extends StatelessWidget {
  const MondoriApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _MondoriAppView());
  }
}

class _MondoriAppView extends ConsumerWidget {
  const _MondoriAppView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: AppStrings(const Locale('ja')).appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: settings.flutterThemeMode,
      locale: settings.localeOverride,
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    );
  }
}
