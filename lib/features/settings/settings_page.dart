import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/app/app_globals.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/features/trainlog/egg.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_button.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_dialog.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_information_message.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_page_route.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_switch.dart';
import 'package:trainlog_app/features/settings/widgets/delete_account_dialog.dart';
import 'package:trainlog_app/features/settings/widgets/settings_group.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/core/providers/trips_provider.dart';
import 'package:trainlog_app/core/services/geo_permission_service.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

import 'settings_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

// iOS icon colours: one per section, so the colour says where you are
// (Apple has no rule for this; its own Settings app is mostly per item).
const Color _appleAppColor = CupertinoColors.systemBlue;
const Color _appleMapColor = CupertinoColors.systemGreen;
const Color _appleAccountColor = CupertinoColors.systemIndigo;
const Color _appleDangerColor = CupertinoColors.systemRed;
const Color _appleAboutColor = CupertinoColors.systemGrey;

class _SettingsPageState extends State<SettingsPage> {
  final SettingsController _vm = SettingsController();
  final GeoPermissionService _geo = const GeoPermissionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _vm.init(
        settings: context.read<SettingsProvider>(),
        trainlog: context.read<TrainlogProvider>(),
      );
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  /// What the account visibility means, under its row.
  static String? _visibilityHelper(AppLocalizations l10n, int? visibility) =>
      switch (visibility) {
        0 => l10n.settingsAccountVisibilitPrivateHelper,
        1 => l10n.settingsAccountVisibilitRestrictedHelper,
        2 => l10n.settingsAccountVisibilitPublicHelper,
        _ => null,
      };

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _showCurrencyPicker() async {
    final settings = context.read<SettingsProvider>();
    final trainlog = context.read<TrainlogProvider>();

    showCurrencyPicker(
      context: context,
      showFlag: true,
      currencyFilter: trainlog.availableCurrencies.isEmpty
          ? null
          : trainlog.availableCurrencies,
      showCurrencyName: true,
      onSelect: (currency) => settings.setCurrency(currency.code),
    );
  }

  Future<void> _confirmAndClearCache() async {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.read<SettingsProvider>();
    final tripsProvider = context.read<TripsProvider>();

    bool clearGeologs = true;
    final confirmed = await AdaptiveDialog.confirm(
      context: context,
      title: l10n.settingsCacheClearConfirmTitle,
      message: l10n.settingsCacheClearConfirmMessage,
      content: StatefulBuilder(
        builder: (ctx, setState) => SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.settingsCacheClearGeologsToggle),
          value: clearGeologs,
          onChanged: (value) => setState(() => clearGeologs = value),
        ),
      ),
      confirmLabel: l10n.settingsCacheClearButton,
      destructive: true,
    );

    if (confirmed) {
      await _vm.clearCache(
        settings: settings,
        tripsProvider: tripsProvider,
        clearGeologs: clearGeologs,
      );
      if (!mounted) return;
      AdaptiveInformationMessage.showInfo(l10n.settingsCacheClearedMessage);
    }
  }

  /// In-app account deletion needs the `?raw=1` JSON mode of the backend's
  /// delete_account route. Until that is deployed, the button only tells the
  /// user it is coming: set this to true once the server supports it.
  static const bool _accountDeletionEnabled = false;

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_accountDeletionEnabled) {
      AdaptiveInformationMessage.showInfo(l10n.featureAvailableNextUpdate);
      return;
    }
    final deleted = await showDeleteAccountDialog(context);
    if (deleted != true) return;
    // The user is logged out by now and the app root shows the login page,
    // but this page (and any other pushed route) may still sit on top of it:
    // go back to the root before telling them it worked. Not tied to this
    // page's context, which may already be unmounted.
    rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    AdaptiveInformationMessage.showInfo(l10n.deleteAccountSuccess);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    final trainlog = context.read<TrainlogProvider>();
    final tripsProvider = context.read<TripsProvider>();

    return Scaffold(
      body: AnimatedBuilder(
        animation: _vm,
        builder: (ctx, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 8),
              SettingsSectionHeader(l10n.settingsAppCategory),
              _buildAppSection(ctx, l10n, settings),
              SettingsSectionHeader(l10n.settingsMapCategory),
              _buildMapSection(ctx, l10n, settings),
              SettingsSectionHeader(l10n.settingsAccountCategory),
              _buildAccountSection(ctx, l10n, trainlog),
              SettingsSectionHeader(l10n.settingsDangerZoneCategory),
              _buildDangerSection(ctx, l10n, settings, tripsProvider),
              SettingsSectionHeader(l10n.menuAboutTitle),
              _buildAboutSection(ctx, l10n, settings, trainlog, tripsProvider),
              if (kDebugMode) ...[
                SettingsSectionHeader('Debug'),
                _buildDebugSection(
                  ctx,
                  l10n,
                  settings,
                  trainlog,
                  tripsProvider,
                ),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppSection(
    BuildContext ctx,
    AppLocalizations l10n,
    SettingsProvider settings,
  ) {
    final trevithickBirth = DateTime(1771, 4, 13);

    final themeOptions = [
      (label: l10n.settingsLight, value: ThemeMode.light),
      (label: l10n.settingsSystem, value: ThemeMode.system),
      (label: l10n.settingsDark, value: ThemeMode.dark),
    ];

    final languageOptions = [
      (label: '🇬🇧 English', value: 'en'),
      (label: '🇫🇷 Français', value: 'fr'),
      (label: '🇵🇭 Tagalog', value: 'tl'),
      (label: '🇯🇵 日本語', value: 'ja'),
    ];

    final dateFormatOptions = [
      (label: 'DD/MM/YYYY', value: 'dd/MM/yyyy'),
      (label: 'YYYY/MM/DD', value: 'yyyy/MM/dd'),
      (label: 'MM/DD/YYYY', value: 'MM/dd/yyyy'),
    ];

    final radiusOptions = [
      (label: '100 m', value: 100),
      (label: '250 m', value: 250),
      (label: '500 m', value: 500),
      (label: '750 m', value: 750),
      (label: '1 km', value: 1000),
    ];

    final dateExample = formatDateTime(ctx, trevithickBirth, hasTime: false);
    final timeExample = formatDateTime(ctx, DateTime.now(), timeOnly: true);

    final landingPageOptions = [
      (label: l10n.menuMapTitle, value: LandingPage.map),
      (label: l10n.menuTripsTitle, value: LandingPage.trips),
    ];

    return SettingsGroup(
      children: [
        SettingsThemeRow(
          icon: AdaptiveIcons.theme,
          appleIconColor: _appleAppColor,
          title: l10n.settingsThemeMode,
          options: themeOptions,
          selected: settings.themeMode,
          onChanged: settings.setTheme,
        ),
        SettingsPickerTile<String>(
          icon: AdaptiveIcons.language,
          appleIconColor: _appleAppColor,
          title: l10n.settingsLanguage,
          options: languageOptions,
          selected: settings.locale.languageCode,
          onChanged: (v) => settings.setLocale(Locale(v)),
        ),
        SettingsPickerTile<String>(
          icon: AdaptiveIcons.date,
          appleIconColor: _appleAppColor,
          title: l10n.settingsDateFormat,
          subtitle: '(${l10n.settingsExampleShort} $dateExample)',
          options: dateFormatOptions,
          selected: settings.dateFormat,
          onChanged: settings.setDateFormat,
        ),
        SettingsTile(
          icon: AdaptiveIcons.hour,
          appleIconColor: _appleAppColor,
          title: l10n.settingsHourFormat12,
          subtitle: '(${l10n.settingsExampleShort} $timeExample)',
          trailing: AdaptiveSwitch(
            value: settings.hourFormat12,
            onChanged: settings.setHourFormat12,
          ),
        ),
        SettingsTile(
          icon: AdaptiveIcons.currency,
          appleIconColor: _appleAppColor,
          title: l10n.settingsCurrency,
          appleOnTap: _showCurrencyPicker,
          trailing: SettingsValueButton(
            value: settings.currency,
            onPressed: _showCurrencyPicker,
          ),
        ),
        SettingsTile(
          icon: AdaptiveIcons.warningMsg,
          appleIconColor: _appleAppColor,
          title: l10n.settingsHideWarningMessage,
          trailing: AdaptiveSwitch(
            value: settings.hideWarningMessage,
            onChanged: settings.setHideWarningMessage,
          ),
        ),
        SettingsPickerTile<int>(
          icon: AdaptiveIcons.radar,
          appleIconColor: _appleAppColor,
          title: l10n.settingsSprRadius,
          options: radiusOptions,
          selected: settings.sprRadius,
          onChanged: settings.setSprRadius,
        ),
        SettingsPickerTile<LandingPage>(
          icon: AdaptiveIcons.landingPage,
          appleIconColor: _appleAppColor,
          title: l10n.settingsLandingPage,
          options: landingPageOptions,
          selected: settings.landingPage,
          onChanged: settings.setLandingPage,
        ),
      ],
    );
  }

  Widget _buildMapSection(
    BuildContext ctx,
    AppLocalizations l10n,
    SettingsProvider settings,
  ) {
    final orderOptions = [
      (
        label: l10n.settingMapPathDisplayOrderByCreation,
        value: PathDisplayOrder.creationDate,
      ),
      (
        label: l10n.settingMapPathDisplayOrderByTrip,
        value: PathDisplayOrder.tripDate,
      ),
      (
        label: l10n.settingMapPathDisplayOrderByTripAndPlane,
        value: PathDisplayOrder.tripDatePlaneOver,
      ),
    ];

    final paletteOptions = [
      (
        label: l10n.settingsMapColorPaletteTrainlogApp,
        value: MapColorPalette.trainlogApp,
      ),
      (
        label: l10n.settingsMapColorPaletteTrainlogWeb,
        value: MapColorPalette.trainlogWeb,
      ),
      (
        label: l10n.settingsMapColorPaletteColourBlind,
        value: MapColorPalette.colorBlind,
      ),
      (
        label: l10n.settingsMapColorPaletteVibrantTones,
        value: MapColorPalette.vibrantTones,
      ),
      (
        label: l10n.settingsMapColorPaletteTrainlogRed,
        value: MapColorPalette.red,
      ),
      (
        label: l10n.settingsMapColorPaletteTrainlogGreen,
        value: MapColorPalette.green,
      ),
      (
        label: l10n.settingsMapColorPaletteTrainlogBlue,
        value: MapColorPalette.blue,
      ),
    ];

    final mapThemeOptions = [
      (label: l10n.settingsLight, value: ThemeMode.light),
      (label: l10n.settingsMapThemeFollowApp, value: ThemeMode.system),
      (label: l10n.settingsDark, value: ThemeMode.dark),
    ];

    return SettingsGroup(
      children: [
        SettingsThemeRow(
          icon: AdaptiveIcons.map,
          appleIconColor: _appleMapColor,
          title: l10n.settingsMapTheme,
          options: mapThemeOptions,
          selected: settings.mapThemeMode,
          onChanged: settings.setMapTheme,
        ),
        SettingsPickerTile<PathDisplayOrder>(
          icon: AdaptiveIcons.layers,
          appleIconColor: _appleMapColor,
          title: l10n.settingsMapPathDisplayOrder,
          options: orderOptions,
          selected: settings.pathDisplayOrder,
          onChanged: (v) {
            settings.setPathDisplayOrder(v);
            settings.setShouldReloadPolylines(true);
          },
        ),
        SettingsPickerTile<MapColorPalette>(
          icon: AdaptiveIcons.palette,
          appleIconColor: _appleMapColor,
          title: l10n.settingsMapColorPalette,
          noDivider: true,
          options: paletteOptions,
          selected: settings.mapColorPalette,
          onChanged: (v) {
            settings.setMapColorPalette(v);
            settings.setShouldReloadPolylines(true);
          },
        ),
        SettingsPaletteLegend(palette: settings.mapColorPalette),
        SettingsTile(
          icon: AdaptiveIcons.position,
          appleIconColor: _appleMapColor,
          title: l10n.settingsDisplayUserMarker,
          trailing: AdaptiveSwitch(
            value: settings.mapDisplayUserLocationMarker,
            onChanged: (value) async {
              // Enabling the marker needs location access: prompt via the
              // service first and only flip the switch on if it's granted.
              if (value && !await _geo.hasPermission()) {
                final granted = await _geo.requestPermission(settings);
                if (!granted) return;
              }
              settings.setMapDisplayUserLocationMarker(value);
            },
          ),
        ),
        SettingsTile(
          icon: AdaptiveIcons.tripDirection,
          appleIconColor: _appleMapColor,
          title: l10n.settingsDisplayTripDirection,
          trailing: AdaptiveSwitch(
            value: settings.mapDisplayTripDirection,
            onChanged: settings.setMapDisplayTripDirection,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection(
    BuildContext ctx,
    AppLocalizations l10n,
    TrainlogProvider trainlog,
  ) {
    final visibilityOptions = [
      (label: l10n.visibilityPrivate, value: 0),
      (label: l10n.visibilityRestricted, value: 1),
      (label: l10n.visibilityPublic, value: 2),
    ];

    return SettingsGroup(
      children: [
        SettingsPickerTile<int>(
          icon: AdaptiveIcons.visibility,
          appleIconColor: _appleAccountColor,
          title: l10n.settingsAccountVisibility,
          subtitle: _visibilityHelper(l10n, _vm.accountVisibility),
          enabled: _vm.accountVisibility != null,
          options: visibilityOptions,
          selected: _vm.accountVisibility,
          onChanged: (v) => _vm.setAccountVisibility(
            value: v,
            trainlog: trainlog,
          ),
        ),
        SettingsTile(
          icon: AdaptiveIcons.ranking,
          appleIconColor: _appleAccountColor,
          title: l10n.settingsAccountLeaderboard,
          enabled: _vm.accountLeaderboard != null,
          trailing: AdaptiveSwitch(
            value: _vm.accountLeaderboard ?? false,
            onChanged: _vm.accountLeaderboard == null
                ? null
                : (v) =>
                      _vm.setAccountLeaderboard(value: v, trainlog: trainlog),
          ),
        ),
        SettingsTile(
          icon: AdaptiveIcons.friends,
          appleIconColor: _appleAccountColor,
          title: l10n.settingsAccountFriendSearch,
          enabled: _vm.accountFriendSearch != null,
          trailing: AdaptiveSwitch(
            value: _vm.accountFriendSearch ?? false,
            onChanged: _vm.accountFriendSearch == null
                ? null
                : (v) =>
                      _vm.setAccountFriendSearch(value: v, trainlog: trainlog),
          ),
        ),
        SettingsTile(
          icon: AdaptiveIcons.world,
          appleIconColor: _appleAccountColor,
          title: l10n.settingsAccountAppearGlobal,
          subtitle: l10n.settingsAccountAppearGlobalSubtitle,
          enabled: _vm.accountAppearGlobal != null,
          trailing: AdaptiveSwitch(
            value: _vm.accountAppearGlobal ?? false,
            onChanged: _vm.accountAppearGlobal == null
                ? null
                : (v) =>
                      _vm.setAccountAppearGlobal(value: v, trainlog: trainlog),
          ),
        ),
      ],
    );
  }

  Widget _buildDangerSection(
    BuildContext ctx,
    AppLocalizations l10n,
    SettingsProvider settings,
    TripsProvider tripsProvider,
  ) {
    return SettingsGroup(
      children: [
        SettingsClearCacheTile(
          icon: AdaptiveIcons.cache,
          appleIconColor: _appleDangerColor,
          title: l10n.settingsCacheTitle,
          subtitle: l10n.settingsCache(formatNumber(ctx, _vm.totalCacheSize)),
          buttonLabel: l10n.settingsCacheClearButton,
          enabled: _vm.totalCacheSize > 0,
          onClear: _confirmAndClearCache,
        ),
        SettingsDeleteAccountTile(
          icon: AdaptiveIcons.deleteAccount,
          appleIconColor: _appleDangerColor,
          title: l10n.settingsDeleteAccount,
          buttonLabel: l10n.settingsDeleteAccountButton,
          onDelete: _deleteAccount,
        ),
      ],
    );
  }

  Widget _buildAboutSection(
    BuildContext ctx,
    AppLocalizations l10n,
    SettingsProvider settings,
    TrainlogProvider trainlog,
    TripsProvider tripsProvider,
  ) {
    final cs = Theme.of(ctx).colorScheme;

    return SettingsGroup(
      children: [
        SettingsTile(
          icon: AdaptiveIcons.instance,
          appleIconColor: _appleAboutColor,
          title: l10n.settingsInstanceUrl,
          appleOnTap: () => AdaptiveInformationMessage.show(
            ctx,
            l10n.settingsInstanceMsg,
            isImportant: true,
          ),
          trailing: GestureDetector(
            onTap: () => AdaptiveInformationMessage.show(
              ctx,
              l10n.settingsInstanceMsg,
              isImportant: true,
            ),
            child: Text(
              trainlog.instanceUrl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.monoFont.copyWith(
                fontSize: 13,
                color: cs.primary,
              ),
            ),
          ),
        ),
        SettingsTile(
          icon: AdaptiveIcons.info,
          appleIconColor: _appleAboutColor,
          title: l10n.appVersion,
          trailing: FutureBuilder<String>(
            future: _vm.getVersionString(),
            builder: (_, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () => _vm.onVersionTapped(
                  showCopiedInfo: () => AdaptiveInformationMessage.showInfo(
                    l10n.appVersionCopied,
                  ),
                  openSnakeGame: () =>
                      AdaptivePageRoute.push(ctx, (_) => const SnakeGame()),
                ),
                child: Text(
                  snap.data!,
                  style: AppTheme.monoFont.copyWith(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        ),
        SettingsTile(
          icon: AdaptiveIcons.license,
          appleIconColor: _appleAboutColor,
          title: l10n.settingsLicenses,
          trailing: const SettingsChevron(),
          onTap: () async {
            final version = await _vm.getVersionString();
            if (!mounted) return;
            showLicensePage(
              context: context,
              applicationName: l10n.appTitle,
              applicationVersion: version,
              applicationIcon: Image.asset(
                'assets/icon/trainlog_icon.png',
                width: 64,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDebugSection(
    BuildContext ctx,
    AppLocalizations l10n,
    SettingsProvider settings,
    TrainlogProvider trainlog,
    TripsProvider tripsProvider,
  ) {
    final icon = AdaptiveIcons.debug;

    return SettingsGroup(
      children: [
        SettingsTile(
          icon: icon,
          title: 'Reset Onboarding',
          subtitle: 'debug',
          trailing: AdaptiveButton.build(
            context: ctx,
            label: const Text('Reset'),
            size: AdaptiveButton.small,
            onPressed: () {
              settings.resetOnboarding(trainlog, tripsProvider);
              AdaptiveInformationMessage.showInfo('Onboarding reset');
            },
          ),
        ),
        SettingsTile(
          icon: icon,
          title: 'Throw Test Exception',
          subtitle: 'debug',
          trailing: AdaptiveButton.build(
            context: ctx,
            label: const Text('Throw'),
            size: AdaptiveButton.small,
            onPressed: () => throw Exception(),
          ),
        ),
        SettingsTile(
          icon: icon,
          title: 'Simulate expired session',
          subtitle: 'debug: forgets the session cookie, keeps local data',
          trailing: AdaptiveButton.build(
            context: ctx,
            label: const Text('Expire'),
            size: AdaptiveButton.small,
            onPressed: () async {
              await trainlog.debugForgetSessionCookie();
              AdaptiveInformationMessage.showInfo(
                'Session cookie deleted: refresh the trips to see the banner',
              );
            },
          ),
        ),
        SettingsTile(
          icon: icon,
          title: 'Reset changelog',
          subtitle: 'debug',
          trailing: AdaptiveButton.build(
            context: ctx,
            label: const Text('Reset'),
            size: AdaptiveButton.small,
            onPressed: () async {
              await settings.clearLastSeenChangelog();
              AdaptiveInformationMessage.showInfo('Changelog reset');
            },
          ),
        ),
      ],
    );
  }
}
