import 'package:flutter/material.dart' show ThemeMode; // only for ThemeMode type
import 'package:flutter/widgets.dart';

import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

import 'settings_vm.dart';

class SettingsOption<T> {
  final String label;
  final T value;
  const SettingsOption(this.label, this.value);
}

class SettingsSectionSpec {
  final String header;
  final List<SettingsItemSpec> items;
  const SettingsSectionSpec({required this.header, required this.items});
}

sealed class SettingsItemSpec {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool enabled;

  const SettingsItemSpec({
    required this.icon,
    required this.title,
    this.subtitle,
    this.enabled = true,
  });
}

class SettingsToggleSpec extends SettingsItemSpec {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SettingsToggleSpec({
    required super.icon,
    required super.title,
    super.subtitle,
    super.enabled,
    required this.value,
    required this.onChanged,
  });
}

enum MaterialChoiceLayout {
  trailingDropdown, // ListTile trailing DropdownButton (your current style)
  inlineDropdown, // ListTile title Column(Text + DropdownButton) (your current map style)
}

class SettingsChoiceSpec<T> extends SettingsItemSpec {
  final T value;
  final List<SettingsOption<T>> options;
  final ValueChanged<T?>? onChanged;

  /// Material should render EXACTLY as before.
  final MaterialChoiceLayout materialLayout;

  /// Optional: display string for Cupertino right-side value
  final String Function(T v)? valueLabel;

  const SettingsChoiceSpec({
    required super.icon,
    required super.title,
    super.subtitle,
    super.enabled,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.materialLayout,
    this.valueLabel,
  });
}

class SettingsCurrencySpec extends SettingsItemSpec {
  final String currencyCode;
  final VoidCallback onPick;

  const SettingsCurrencySpec({
    required super.icon,
    required super.title,
    super.subtitle,
    super.enabled,
    required this.currencyCode,
    required this.onPick,
  });
}

enum DangerActionStyle {
  clearCache,
  deleteAccount,
}

class SettingsDangerActionSpec extends SettingsItemSpec {
  final DangerActionStyle style;
  final VoidCallback onPressed;

  const SettingsDangerActionSpec({
    required super.icon,
    required super.title,
    super.subtitle,
    super.enabled,
    required this.style,
    required this.onPressed,
  });
}

class SettingsVersionSpec extends SettingsItemSpec {
  final Future<String> Function() versionFuture;
  final VoidCallback onTap;

  const SettingsVersionSpec({
    required super.icon,
    required super.title,
    super.subtitle,
    super.enabled,
    required this.versionFuture,
    required this.onTap,
  });
}

class SettingsPaletteLegendSpec extends SettingsItemSpec {
  final MapColorPalette palette;

  SettingsPaletteLegendSpec({
    required this.palette,
  }) : super(
          // icon/title are not used by the renderer for this spec
          icon: AdaptiveIcons.palette,
          title: '',
        );
}

/// This returns the full structure (shared by Material + Cupertino).
List<SettingsSectionSpec> buildSettingsBlueprint({
  required BuildContext context,
  required SettingsProvider settings,
  required TrainlogProvider trainlog,
  required SettingsVm vm,
  required AppLocalizations l10n,
  required VoidCallback showCopiedInfo,
  required Future<void> Function() showCurrencyPickerMaterialOrCupertino,
  required Future<void> Function() confirmAndClearCache,
  required Future<void> Function() requestDeleteAccountMail,
}) {
  final trevithickBirth = DateTime(1771, 4, 13);

  // Shared option lists (no duplication)
  final themeOptions = <SettingsOption<ThemeMode>>[
    SettingsOption(l10n.settingsLight, ThemeMode.light),
    SettingsOption(l10n.settingsDark, ThemeMode.dark),
    SettingsOption(l10n.settingsSystem, ThemeMode.system),
  ];

  final languages = <SettingsOption<String>>[
    const SettingsOption('🇬🇧 English', 'en'),
    const SettingsOption('🇫🇷 Français', 'fr'),
    const SettingsOption('🇯🇵 日本語', 'ja'),
  ];

  final dateFormats = <SettingsOption<String>>[
    const SettingsOption('DD/MM/YYYY', 'dd/MM/yyyy'),
    const SettingsOption('YYYY/MM/DD', 'yyyy/MM/dd'),
    const SettingsOption('MM/DD/YYYY', 'MM/dd/yyyy'),
  ];

  final radiusOptions = <SettingsOption<int>>[
    const SettingsOption('100 m', 100),
    const SettingsOption('250 m', 250),
    const SettingsOption('500 m', 500),
    const SettingsOption('750 m', 750),
    const SettingsOption('1 km', 1000),
  ];

  final visibilityOptions = <SettingsOption<int>>[
    SettingsOption(l10n.visibilityPrivate, 0),
    SettingsOption(l10n.visibilityRestricted, 1),
    SettingsOption(l10n.visibilityPublic, 2),
  ];

  final orderOptions = <SettingsOption<PathDisplayOrder>>[
    SettingsOption(l10n.settingMapPathDisplayOrderByCreation, PathDisplayOrder.creationDate),
    SettingsOption(l10n.settingMapPathDisplayOrderByTrip, PathDisplayOrder.tripDate),
    SettingsOption(l10n.settingMapPathDisplayOrderByTripAndPlane, PathDisplayOrder.tripDatePlaneOver),
  ];

  final paletteOptions = <SettingsOption<MapColorPalette>>[
    SettingsOption(l10n.settingsMapColorPaletteTrainlogWeb, MapColorPalette.trainlogWeb),
    SettingsOption(l10n.settingsMapColorPaletteColourBlind, MapColorPalette.colorBlind),
    SettingsOption(l10n.settingsMapColorPaletteVibrantTones, MapColorPalette.vibrantTones),
    SettingsOption(l10n.settingsMapColorPaletteTrainlogRed, MapColorPalette.red),
    SettingsOption(l10n.settingsMapColorPaletteTrainlogGreen, MapColorPalette.green),
    SettingsOption(l10n.settingsMapColorPaletteTrainlogBlue, MapColorPalette.blue),
  ];

  // --- ICONS ---
  final iconTheme = AdaptiveIcons.theme;
  final iconLanguage = AdaptiveIcons.language;
  final iconDateFormat = AdaptiveIcons.date;
  final iconHourFormat = AdaptiveIcons.hour;
  final iconCurrency = AdaptiveIcons.currency;
  final iconHideWarning = AdaptiveIcons.warningMsg;
  final iconRadius = AdaptiveIcons.radar;

  final iconPathOrder = AdaptiveIcons.layers;
  final iconPalette = AdaptiveIcons.palette;
  final iconUserMarker = AdaptiveIcons.position;

  final iconVisibility = AdaptiveIcons.visibility;
  final iconLeaderboard = AdaptiveIcons.ranking;
  final iconFriendSearch = AdaptiveIcons.friends;
  final iconAppearGlobal = AdaptiveIcons.world;

  final iconCache = AdaptiveIcons.cache;
  final iconDelete = AdaptiveIcons.deleteAccount;
  final iconVersion = AdaptiveIcons.info;

  final cacheLabel = l10n.settingsCache(formatNumber(context, vm.totalCacheSize));

  return [
    SettingsSectionSpec(
      header: l10n.settingsAppCategory,
      items: [
        SettingsChoiceSpec<ThemeMode>(
          icon: iconTheme,
          title: l10n.settingsThemeMode,
          value: settings.themeMode,
          options: themeOptions,
          onChanged: (v) {
            if (v != null) settings.setTheme(v);
          },
          materialLayout: MaterialChoiceLayout.trailingDropdown,
          valueLabel: (v) => v.name,
        ),
        SettingsChoiceSpec<String>(
          icon: iconLanguage,
          title: l10n.settingsLanguage,
          value: settings.locale.languageCode,
          options: languages,
          onChanged: (v) {
            if (v != null) settings.setLocale(Locale(v));
          },
          materialLayout: MaterialChoiceLayout.trailingDropdown,
          valueLabel: (v) => v,
        ),
        SettingsChoiceSpec<String>(
          icon: iconDateFormat,
          title: l10n.settingsDateFormat,
          subtitle: '(${l10n.settingsExampleShort} ${formatDateTime(context, trevithickBirth, hasTime: false)})',
          value: settings.dateFormat,
          options: dateFormats,
          onChanged: (v) {
            if (v != null) settings.setDateFormat(v);
          },
          materialLayout: MaterialChoiceLayout.trailingDropdown,
          valueLabel: (v) => v,
        ),
        SettingsToggleSpec(
          icon: iconHourFormat,
          title: l10n.settingsHourFormat12,
          subtitle: '(${l10n.settingsExampleShort} ${formatDateTime(context, DateTime.now(), timeOnly: true)})',
          value: settings.hourFormat12,
          onChanged: settings.setHourFormat12,
        ),
        SettingsCurrencySpec(
          icon: iconCurrency,
          title: l10n.settingsCurrency,
          currencyCode: settings.currency,
          onPick: () {
            showCurrencyPickerMaterialOrCupertino();
          },
        ),
        SettingsToggleSpec(
          icon: iconHideWarning,
          title: l10n.settingsHideWarningMessage,
          value: settings.hideWarningMessage,
          onChanged: settings.setHideWarningMessage,
        ),
        SettingsChoiceSpec<int>(
          icon: iconRadius,
          title: l10n.settingsSprRadius,
          value: settings.sprRadius,
          options: radiusOptions,
          onChanged: (v) {
            if (v != null) settings.setSprRadius(v);
          },
          materialLayout: MaterialChoiceLayout.trailingDropdown,
          valueLabel: (v) => '$v',
        ),
      ],
    ),

    SettingsSectionSpec(
      header: l10n.settingsMapCategory,
      items: [
        SettingsChoiceSpec<PathDisplayOrder>(
          icon: iconPathOrder,
          title: l10n.settingsMapPathDisplayOrder,
          value: settings.pathDisplayOrder,
          options: orderOptions,
          onChanged: (v) {
            if (v == null) return;
            settings.setPathDisplayOrder(v);
            settings.setShouldReloadPolylines(true);
          },
          materialLayout: MaterialChoiceLayout.inlineDropdown,
          valueLabel: (v) => v.name,
        ),
        SettingsChoiceSpec<MapColorPalette>(
          icon: iconPalette,
          title: l10n.settingsMapColorPalette,
          value: settings.mapColorPalette,
          options: paletteOptions,
          onChanged: (v) {
            if (v == null) return;
            settings.setMapColorPalette(v);
            settings.setShouldReloadPolylines(true);
          },
          materialLayout: MaterialChoiceLayout.inlineDropdown,
          valueLabel: (v) => v.name,
        ),
        SettingsPaletteLegendSpec(
          palette: settings.mapColorPalette,
        ),
        SettingsToggleSpec(
          icon: iconUserMarker,
          title: l10n.settingsDisplayUserMarker,
          value: settings.mapDisplayUserLocationMarker,
          onChanged: settings.setMapDisplayUserLocationMarker,
        ),
      ],
    ),

    SettingsSectionSpec(
      header: l10n.settingsAccountCategory,
      items: [
        SettingsChoiceSpec<int>(
          icon: iconVisibility,
          title: l10n.settingsAccountVisibility,
          subtitle: vm.accountVisibilityHelperText.isEmpty ? null : vm.accountVisibilityHelperText,
          enabled: vm.accountVisibility != null,
          value: vm.accountVisibility ?? 0,
          options: visibilityOptions,
          onChanged: (v) {
            if (v == null) return;
            vm.setAccountVisibility(value: v, l10n: l10n, trainlog: trainlog);
          },
          materialLayout: MaterialChoiceLayout.trailingDropdown,
          valueLabel: (v) => '$v',
        ),
        SettingsToggleSpec(
          icon: iconLeaderboard,
          title: l10n.settingsAccountLeaderboard,
          enabled: vm.accountLeaderboard != null,
          value: vm.accountLeaderboard ?? false,
          onChanged: vm.accountLeaderboard == null
              ? null
              : (val) => vm.setAccountLeaderboard(value: val, trainlog: trainlog),
        ),
        SettingsToggleSpec(
          icon: iconFriendSearch,
          title: l10n.settingsAccountFriendSearch,
          enabled: vm.accountFriendSearch != null,
          value: vm.accountFriendSearch ?? false,
          onChanged: vm.accountFriendSearch == null
              ? null
              : (val) => vm.setAccountFriendSearch(value: val, trainlog: trainlog),
        ),
        SettingsToggleSpec(
          icon: iconAppearGlobal,
          title: l10n.settingsAccountAppearGlobal,
          subtitle: l10n.settingsAccountAppearGlobalSubtitle,
          enabled: vm.accountAppearGlobal != null,
          value: vm.accountAppearGlobal ?? false,
          onChanged: vm.accountAppearGlobal == null
              ? null
              : (val) => vm.setAccountAppearGlobal(value: val, trainlog: trainlog),
        ),
      ],
    ),

    SettingsSectionSpec(
      header: l10n.settingsDangerZoneCategory,
      items: [
        SettingsDangerActionSpec(
          icon: iconCache,
          title: cacheLabel,
          enabled: vm.totalCacheSize > 0,
          style: DangerActionStyle.clearCache,
          onPressed: () {
            confirmAndClearCache();
          },
        ),
        SettingsDangerActionSpec(
          icon: iconDelete,
          title: l10n.settingsDeleteAccount,
          style: DangerActionStyle.deleteAccount,
          onPressed: () {
            requestDeleteAccountMail();
          },
        ),
      ],
    ),

    SettingsSectionSpec(
      header: l10n.menuAboutTitle,
      items: [
        SettingsVersionSpec(
          icon: iconVersion,
          title: l10n.appVersion,
          versionFuture: vm.getVersionString,
          onTap: () {
            vm.onVersionTapped(
              l10n: l10n,
              showCopiedInfo: showCopiedInfo,
            );
          },
        ),
      ],
    ),
  ];
}
