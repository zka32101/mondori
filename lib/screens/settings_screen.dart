import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mondori/l10n/app_strings.dart';
import 'package:mondori/providers/settings_provider.dart';
import 'package:mondori/services/settings_service.dart';

/// 設定画面：テーマ・言語・サウンドを管理
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final strings = context.strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _SectionHeader(title: strings.theme),
          RadioListTile<AppThemeMode>(
            title: Text(strings.themeSystem),
            value: AppThemeMode.system,
            groupValue: settings.themeMode,
            onChanged: (mode) => notifier.setThemeMode(mode!),
          ),
          RadioListTile<AppThemeMode>(
            title: Text(strings.themeLight),
            value: AppThemeMode.light,
            groupValue: settings.themeMode,
            onChanged: (mode) => notifier.setThemeMode(mode!),
          ),
          RadioListTile<AppThemeMode>(
            title: Text(strings.themeDark),
            value: AppThemeMode.dark,
            groupValue: settings.themeMode,
            onChanged: (mode) => notifier.setThemeMode(mode!),
          ),
          const Divider(),
          _SectionHeader(title: strings.language),
          RadioListTile<Locale?>(
            title: Text(strings.themeSystem),
            value: null,
            groupValue: settings.localeOverride,
            onChanged: (locale) => notifier.setLocale(locale),
          ),
          for (final locale in AppStrings.supportedLocales)
            RadioListTile<Locale?>(
              title: Text(AppStrings.localeName(locale.languageCode)),
              value: locale,
              groupValue: settings.localeOverride,
              onChanged: (l) => notifier.setLocale(l),
            ),
          const Divider(),
          _SectionHeader(title: strings.soundEffects),
          SwitchListTile(
            title: Text(strings.soundEffects),
            value: settings.soundEnabled,
            onChanged: notifier.setSoundEnabled,
          ),
          SwitchListTile(
            title: Text(strings.backgroundMusic),
            value: settings.musicEnabled,
            onChanged: notifier.setMusicEnabled,
          ),
          ListTile(
            title: Text(strings.volume),
            subtitle: Slider(
              value: settings.volume,
              onChanged: notifier.setVolume,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: '${(settings.volume * 100).round()}%',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
