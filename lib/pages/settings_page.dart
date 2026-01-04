import 'dart:io';
import 'package:currency_picker/currency_picker.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/utils/app_info_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/utils/cached_data_utils.dart';
import 'package:trainlog_app/utils/date_utils.dart';
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

class DateFormat {
  final String display;
  final String code;

  DateFormat(this.display, this.code);
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _totalCacheSize = 0.0;

  void _refreshCacheSize() {
    setState(() {
      _totalCacheSize = AppCacheFilePath.computeAllCacheFileSize();
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
    final trainLogDeleteAccountEmail = 'admin@trainlog.me';
    final trainlog = Provider.of<TrainlogProvider>(context, listen: false);
    final scaffMsg = ScaffoldMessenger.of(context);

    final List<Language> languages = [
      Language('English', 'en'),
      Language('Français', 'fr'),
      Language('日本語', 'ja'),
    ];
    final List<DateFormat> dateFormats = [
      DateFormat('DD/MM/YYYY', 'dd/MM/yyyy'),
      DateFormat('YYYY/MM/DD', 'yyyy/MM/dd'),
      DateFormat('MM/DD/YYYY', 'MM/dd/yyyy'),
    ];
    final trevithickBirth = DateTime(1771, 4, 13);
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
              leading: const Icon(Icons.date_range),
              title: Text(appLocalization.settingsDateFormat),
              subtitle: Text("(${appLocalization.settingsExampleShort} ${formatDateTime(context, trevithickBirth, hasTime: false)})"),
              trailing: DropdownButton<String>(
                value: settings.dateFormat,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    settings.setDateFormat(newValue);
                  }
                },
                items: dateFormats
                    .map<DropdownMenuItem<String>>(
                      (DateFormat format) => DropdownMenuItem<String>(
                        value: format.code,
                        child: Text(format.display),
                      ),
                    )
                    .toList(),
              ),
            ),
            ListTile(
              leading: Icon(Icons.watch),
              title: Text(appLocalization.settingsHourFormat12),
              subtitle: Text("(${appLocalization.settingsExampleShort} ${formatDateTime(context, DateTime.now(), timeOnly: true)})"),
              trailing: Switch(
                value: settings.hourFormat12, 
                onChanged: (bool val) {
                  settings.setHourFormat12(val);
                }
              ),
            ),
            ListTile(
              leading: const Icon(Icons.currency_exchange),
              title: Text(appLocalization.settingsCurrency),
              trailing: OutlinedButton(
                onPressed: () {
                  showCurrencyPicker(
                    context: context,
                    showFlag: true,
                    showCurrencyName: true,
                    onSelect: (currency) {
                      settings.setCurrency(currency.code);
                    },
                  );
                },
                child: Text(settings.currency),
              ),
            ),            
            ListTile(
              leading: Icon(Icons.warning),
              title: Text(appLocalization.settingsHideWarningMessage),
              trailing: Switch(
                value: settings.hideWarningMessage, 
                onChanged: (bool val) {
                  settings.setHideWarningMessage(val);
                }
              ),
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
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocalization.settingsMapColorPalette,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  DropdownButton<MapColorPalette>(
                    isExpanded: true,
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
                        value: MapColorPalette.colorBlind,
                        child: Text(appLocalization.settingsMapColorPaletteColourBlind),
                      ),
                      DropdownMenuItem(
                        value: MapColorPalette.vibrantTones,
                        child: Text(appLocalization.settingsMapColorPaletteVibrantTones),
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
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: VehicleType.values.map((type) {
                  final color = MapColorPaletteHelper
                      .getPalette(settings.mapColorPalette)[type] ?? Colors.grey;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      type.icon().icon, // reuse enum icon
                      color: color,
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 8,),
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
            _SettingsCategory(title: appLocalization.settingsDangerZoneCategory), // ---------------------------------------------
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

                        await AppCacheFilePath.deleteFile(AppCacheFilePath.polylines);
                        await AppCacheFilePath.deleteFile(AppCacheFilePath.preRecord);

                        if (!mounted) return;
                        _refreshCacheSize();
                        settings.setShouldReloadPolylines(true);
                        // ignore: use_build_context_synchronously
                        scaffMsg.showSnackBar(
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
            ListTile(
              leading: const Icon(Icons.no_accounts),
              title: Text(appLocalization.settingsDeleteAccount),
              trailing: ElevatedButton.icon(
                icon: const Icon(Icons.mail),
                label: Text(appLocalization.settingsDeleteAccountRequest),
                onPressed: () async {
                  final body = [
                    'Hello,',
                    '',
                    'I would like to delete my account, my username is ${trainlog.username}.',
                    '',
                    'Thanks in advance,',
                    '',
                    'NB: message sent with Trainlog App.',
                  ].join('\r\n');
                  final subject = 'Request to delete my account';
                  final uri = Uri.parse(
                    'mailto:$trainLogDeleteAccountEmail'
                    '?subject=${Uri.encodeComponent(subject)}'
                    '&body=${Uri.encodeComponent(body)}',
                  );

                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    // Optional: show error snackbar
                    scaffMsg.showSnackBar(
                      SnackBar(content: Text(appLocalization.settingsDeleteAccountError(trainLogDeleteAccountEmail))),
                    );
                  }
                },
              ),
            ),
            ListTile(
              //leading: Icon(Icons.my_location),
              title: Text(appLocalization.appVersion),
              trailing: FutureBuilder<String>(
                future: getAppVersionString(),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  return Text('v${snap.data}');
                },
              ),
            ),
            SizedBox(height: 12,),
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
