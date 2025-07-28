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
    final appLocalization = AppLocalizations.of(context)!;
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return ListView(
          children: [
            _SettingsCategory(title: appLocalization.settingsAppCategory),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: Text(appLocalization.settingsThemeMode),
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
                    child: Text(appLocalization.settingsLight),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text(appLocalization.settingsDark),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text(appLocalization.settingsSystem),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(appLocalization.settingsLanguage),
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
            _SettingsCategory(title: appLocalization.settingsMapCategory),
            ListTile(
              leading: const Icon(Icons.layers),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocalization.settingsMapPathDisplayOrder,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  DropdownButton<PathDisplayOrder>(
                    isExpanded: true,
                    value: settings.pathDisplayOrder,
                    onChanged: (PathDisplayOrder? newValue) {
                      if (newValue != null) {
                        settings.setPathDisplayOrder(newValue);
                      }
                    },
                    items: [
                      DropdownMenuItem(
                        value: PathDisplayOrder.creationDate,
                        child: Text(appLocalization.settingMapPathDisplayOrderByCreation),
                      ),
                      DropdownMenuItem(
                        value: PathDisplayOrder.tripDate,
                        child: Text(appLocalization.settingMapPathDisplayOrderByTrip),
                      ),
                      DropdownMenuItem(
                        value: PathDisplayOrder.tripDatePlaneOver,
                        child: Text(appLocalization.settingMapPathDisplayOrderByTripAndPlane),
                      ),
                    ],
                  ),
                ],
              ),
              // Remove trailing to avoid layout clash
            ),
            _SettingsCategory(title: appLocalization.settingsAccountCategory),
          ],
        );
      },
    );
  }
}

class _SettingsCategory extends StatelessWidget {
  final String title;
  const _SettingsCategory({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
