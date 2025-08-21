import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/utils/cached_data_utils.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/utils/style_utils.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';

class Language {
  final String name;
  final String code;

  Language(this.name, this.code);
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _totalCacheSize = 0.0;

  void _refreshCacheSize() {
    final sizeDb = computeCacheFileSize(AppCacheFilePath.database);
    final sizePolylines = computeCacheFileSize(AppCacheFilePath.polylines);
    setState(() {
      _totalCacheSize = sizeDb + sizePolylines;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshCacheSize();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<TripsProvider>().repository;

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
            ListTile(
              leading: const Icon(Icons.cloud_download),
              title: Text(appLocalization.settingsCache(formatNumber(context, _totalCacheSize))),
              trailing: ElevatedButton.icon(
                onPressed: _totalCacheSize  > 0
                  ? () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(appLocalization.settingsCacheClearConfirmTitle),
                          content: Text(appLocalization.settingsCacheClearConfirmMessage),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(MaterialLocalizations.of(context).okButtonLabel),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        if(repo != null) await repo.clearAllTrips();

                        await File(AppCacheFilePath.polylines)
                              .delete()
                              .catchError((e) {
                                debugPrint('Failed to delete polylines: $e');
                                return File(AppCacheFilePath.polylines);
                              });

                        if (!mounted) return;
                        _refreshCacheSize();
                        settings.setShouldReloadPolylines(true);
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(appLocalization.settingsCacheClearedMessage)),
                        );
                      }
                    }
                  : null, // disabled if cache size is 0
                label: Text(appLocalization.settingsCacheClearButton),
                icon: Icon(Icons.delete),
                style: buttonStyleHelper(Theme.of(context).colorScheme.error, Theme.of(context).colorScheme.onError)
              )
            ),
            _SettingsCategory(title: appLocalization.settingsMapCategory), // ---------------------------------------------
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
                        settings.setShouldReloadPolylines(true);
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
            ),
            ListTile(
              leading: const Icon(Icons.palette),
              title: Text(appLocalization.settingsMapColorPalette),
              trailing: DropdownButton<MapColorPalette>(
                value: settings.mapColorPalette,
                onChanged: (MapColorPalette? newValue) {
                  if (newValue != null) {
                    settings.setMapColorPalette(newValue);
                    settings.setShouldReloadPolylines(true);
                  }
                },
                items: [
                  DropdownMenuItem(
                    value: MapColorPalette.trainlogWeb,
                    child: Text(appLocalization.settingsMapColorPaletteTrainlogWeb),
                  ),
                  DropdownMenuItem(
                    value: MapColorPalette.trainlogVariation,
                    child: Text(appLocalization.settingsMapColorPaletteTrainlogVariation),
                  ),
                  DropdownMenuItem(
                    value: MapColorPalette.red,
                    child: Text(appLocalization.settingsMapColorPaletteTrainlogRed),
                  ),
                  DropdownMenuItem(
                    value: MapColorPalette.green,
                    child: Text(appLocalization.settingsMapColorPaletteTrainlogGreen),
                  ),
                  DropdownMenuItem(
                    value: MapColorPalette.blue,
                    child: Text(appLocalization.settingsMapColorPaletteTrainlogBlue),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.my_location),
              title: Text(appLocalization.settingsDisplayUserMarker),
              trailing: Switch(
                value: settings.mapDisplayUserLocationMarker, 
                onChanged: (bool val) {
                  settings.setMapDisplayUserLocationMarker(val);
                }
              ),
            ),
            _SettingsCategory(title: appLocalization.settingsAccountCategory), // ---------------------------------------------
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
