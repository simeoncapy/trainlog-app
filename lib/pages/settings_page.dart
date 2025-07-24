import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';

class Language {
  final String name;
  final String code;

  Language(this.name, this.code);
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Language> languages = [
      Language('English', 'en'),
      Language('Français', 'fr'),
      Language('日本語', 'ja'),
    ];
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: Text(AppLocalizations.of(context)!.settingsThemeMode),
              trailing: DropdownButton<ThemeMode>(
                value: settings.themeMode,
                onChanged: (ThemeMode? newValue) {
                  if (newValue != null) {
                    settings.setTheme(newValue);
                  }
                },
                items: [
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text(AppLocalizations.of(context)!.settingsLight),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text(AppLocalizations.of(context)!.settingsDark),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text(AppLocalizations.of(context)!.settingsSystem),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(AppLocalizations.of(context)!.settingsLanguage),
              trailing: DropdownButton<String>(
                value: settings.locale.languageCode,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    settings.setLocale(Locale(newValue));
                  }
                },
                items: languages
                    .map<DropdownMenuItem<String>>(
                      (Language language) => DropdownMenuItem<String>(
                        value: language.code,
                        child: Text(language.name),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
