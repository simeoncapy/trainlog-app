import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/platform/adaptive_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:trainlog_app/app/app_theme.dart';
import 'package:trainlog_app/features/trainlog/egg.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_button.dart';
import 'package:trainlog_app/platform/adaptive_dialog.dart';
import 'package:trainlog_app/platform/adaptive_information_message.dart';
import 'package:trainlog_app/platform/adaptive_page_route.dart';
import 'package:trainlog_app/platform/adaptive_switch.dart';
import 'package:trainlog_app/platform/settings_group.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

import 'settings_vm.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsVm _vm = SettingsVm();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      await _vm.init(
        settings: context.read<SettingsProvider>(),
        trainlog: context.read<TrainlogProvider>(),
        l10n: l10n,
      );
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionHeader(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 6),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall!.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _chevronTrailing(BuildContext context, String label) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
        const SizedBox(width: 2),
        Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
      ],
    );
  }

  Future<void> _showPicker<T>({
    required BuildContext context,
    required String title,
    required List<({String label, T value})> options,
    required T selected,
    required ValueChanged<T> onChanged,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final maxHeight = MediaQuery.sizeOf(ctx).height * 0.8;

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxHeight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),

                const Divider(height: 1),

                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = option.value == selected;

                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          onChanged(option.value);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option.label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.check_rounded,
                                  color:
                                      Theme.of(ctx).colorScheme.primary,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _showCurrencyPicker() async {
    final settings = context.read<SettingsProvider>();
    final trainlog = context.read<TrainlogProvider>();

    showCurrencyPicker(
      context: context,
      showFlag: true,
      currencyFilter:
          trainlog.availableCurrencies.isEmpty ? null : trainlog.availableCurrencies,
      showCurrencyName: true,
      onSelect: (currency) => settings.setCurrency(currency.code),
    );
  }

  Future<void> _confirmAndClearCache() async {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.read<SettingsProvider>();
    final tripsProvider = context.read<TripsProvider>();

    final confirmed = await AdaptiveDialog.confirm(
      context: context,
      title: l10n.settingsCacheClearConfirmTitle,
      message: l10n.settingsCacheClearConfirmMessage,
      confirmLabel: l10n.settingsCacheClearButton,
      destructive: true,
    );

    if (confirmed) {
      await _vm.clearCache(settings: settings, tripsProvider: tripsProvider);
      if (!mounted) return;
      AdaptiveInformationMessage.showInfo(l10n.settingsCacheClearedMessage);
    }
  }

  Future<void> _requestDeleteAccountMail() async {
    final l10n = AppLocalizations.of(context)!;
    final trainlog = context.read<TrainlogProvider>();

    final uri = _vm.buildDeleteAccountMailUri(username: trainlog.username ?? '');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      AdaptiveInformationMessage.showInfo(
        l10n.settingsDeleteAccountError(SettingsVm.deleteAccountEmail),
      );
    }
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
          _vm.setVisibilityHelperText(l10n);
          return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 8),
            _sectionHeader(ctx, l10n.settingsAppCategory),
            _buildAppSection(ctx, l10n, settings),
            _sectionHeader(ctx, l10n.settingsMapCategory),
            _buildMapSection(ctx, l10n, settings),
            _sectionHeader(ctx, l10n.settingsAccountCategory),
            _buildAccountSection(ctx, l10n, trainlog),
            _sectionHeader(ctx, l10n.settingsDangerZoneCategory),
            _buildDangerSection(ctx, l10n, settings, tripsProvider),
            _sectionHeader(ctx, l10n.menuAboutTitle),
            _buildAboutSection(ctx, l10n, settings, trainlog, tripsProvider),
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

    final langName = languageOptions
        .firstWhere(
          (o) => o.value == settings.locale.languageCode,
          orElse: () => languageOptions.first,
        )
        .label;
    final dateExample = formatDateTime(ctx, trevithickBirth, hasTime: false);
    final timeExample = formatDateTime(ctx, DateTime.now(), timeOnly: true);
    final radiusName = radiusOptions
        .firstWhere(
          (o) => o.value == settings.sprRadius,
          orElse: () => radiusOptions.first,
        )
        .label;

    return SettingsGroup(children: [
      _ThemeRow(
        icon: AdaptiveIcons.theme,
        title: l10n.settingsThemeMode,
        options: themeOptions,
        selected: settings.themeMode,
        onChanged: settings.setTheme,
      ),
      SettingsTile(
        icon: AdaptiveIcons.language,
        title: l10n.settingsLanguage,
        trailing: _chevronTrailing(ctx, langName),
        onTap: () => _showPicker<String>(
          context: ctx,
          title: l10n.settingsLanguage,
          options: languageOptions,
          selected: settings.locale.languageCode,
          onChanged: (v) => settings.setLocale(Locale(v)),
        ),
      ),
      SettingsTile(
        icon: AdaptiveIcons.date,
        title: l10n.settingsDateFormat,
        subtitle: '(${l10n.settingsExampleShort} $dateExample)',
        trailing: _chevronTrailing(ctx, settings.dateFormat),
        onTap: () => _showPicker<String>(
          context: ctx,
          title: l10n.settingsDateFormat,
          options: dateFormatOptions,
          selected: settings.dateFormat,
          onChanged: settings.setDateFormat,
        ),
      ),
      SettingsTile(
        icon: AdaptiveIcons.hour,
        title: l10n.settingsHourFormat12,
        subtitle: '(${l10n.settingsExampleShort} $timeExample)',
        trailing: AdaptiveSwitch(
          value: settings.hourFormat12,
          onChanged: settings.setHourFormat12,
        ),
      ),
      SettingsTile(
        icon: AdaptiveIcons.currency,
        title: l10n.settingsCurrency,
        trailing: OutlinedButton(
          onPressed: _showCurrencyPicker,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          child: Text(settings.currency),
        ),
      ),
      SettingsTile(
        icon: AdaptiveIcons.warningMsg,
        title: l10n.settingsHideWarningMessage,
        trailing: AdaptiveSwitch(
          value: settings.hideWarningMessage,
          onChanged: settings.setHideWarningMessage,
        ),
      ),
      SettingsTile(
        icon: AdaptiveIcons.radar,
        title: l10n.settingsSprRadius,
        trailing: _chevronTrailing(ctx, radiusName),
        onTap: () => _showPicker<int>(
          context: ctx,
          title: l10n.settingsSprRadius,
          options: radiusOptions,
          selected: settings.sprRadius,
          onChanged: settings.setSprRadius,
        ),
      ),
    ]);
  }

  Widget _buildMapSection(
    BuildContext ctx,
    AppLocalizations l10n,
    SettingsProvider settings,
  ) {
    final orderOptions = [
      (label: l10n.settingMapPathDisplayOrderByCreation, value: PathDisplayOrder.creationDate),
      (label: l10n.settingMapPathDisplayOrderByTrip, value: PathDisplayOrder.tripDate),
      (label: l10n.settingMapPathDisplayOrderByTripAndPlane, value: PathDisplayOrder.tripDatePlaneOver),
    ];

    final paletteOptions = [
      (label: l10n.settingsMapColorPaletteTrainlogApp, value: MapColorPalette.trainlogApp),
      (label: l10n.settingsMapColorPaletteTrainlogWeb, value: MapColorPalette.trainlogWeb),
      (label: l10n.settingsMapColorPaletteColourBlind, value: MapColorPalette.colorBlind),
      (label: l10n.settingsMapColorPaletteVibrantTones, value: MapColorPalette.vibrantTones),
      (label: l10n.settingsMapColorPaletteTrainlogRed, value: MapColorPalette.red),
      (label: l10n.settingsMapColorPaletteTrainlogGreen, value: MapColorPalette.green),
      (label: l10n.settingsMapColorPaletteTrainlogBlue, value: MapColorPalette.blue),
    ];

    final orderName = orderOptions
        .firstWhere(
          (o) => o.value == settings.pathDisplayOrder,
          orElse: () => orderOptions.first,
        )
        .label;
    final paletteName = paletteOptions
        .firstWhere(
          (o) => o.value == settings.mapColorPalette,
          orElse: () => paletteOptions.first,
        )
        .label;

    return SettingsGroup(children: [
      SettingsTile(
        icon: AdaptiveIcons.layers,
        title: l10n.settingsMapPathDisplayOrder,
        trailing: _chevronTrailing(ctx, orderName),
        onTap: () => _showPicker<PathDisplayOrder>(
          context: ctx,
          title: l10n.settingsMapPathDisplayOrder,
          options: orderOptions,
          selected: settings.pathDisplayOrder,
          onChanged: (v) {
            settings.setPathDisplayOrder(v);
            settings.setShouldReloadPolylines(true);
          },
        ),
      ),
      SettingsTile(
        icon: AdaptiveIcons.palette,
        title: l10n.settingsMapColorPalette,
        trailing: _chevronTrailing(ctx, paletteName),
        onTap: () => _showPicker<MapColorPalette>(
          context: ctx,
          title: l10n.settingsMapColorPalette,
          options: paletteOptions,
          selected: settings.mapColorPalette,
          onChanged: (v) {
            settings.setMapColorPalette(v);
            settings.setShouldReloadPolylines(true);
          },
        ),
      ),
      _PaletteLegendRow(palette: settings.mapColorPalette),
      SettingsTile(
        icon: AdaptiveIcons.position,
        title: l10n.settingsDisplayUserMarker,
        trailing: AdaptiveSwitch(
          value: settings.mapDisplayUserLocationMarker,
          onChanged: settings.setMapDisplayUserLocationMarker,
        ),
      ),
    ]);
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

    final visibilityLabel = _vm.accountVisibility != null
        ? visibilityOptions
            .firstWhere(
              (o) => o.value == _vm.accountVisibility,
              orElse: () => visibilityOptions.first,
            )
            .label
        : '—';

    return SettingsGroup(children: [
      SettingsTile(
        icon: AdaptiveIcons.visibility,
        title: l10n.settingsAccountVisibility,
        subtitle: _vm.accountVisibilityHelperText.isEmpty
            ? null
            : _vm.accountVisibilityHelperText,
        enabled: _vm.accountVisibility != null,
        trailing: _chevronTrailing(ctx, visibilityLabel),
        onTap: _vm.accountVisibility == null
            ? null
            : () => _showPicker<int>(
                  context: ctx,
                  title: l10n.settingsAccountVisibility,
                  options: visibilityOptions,
                  selected: _vm.accountVisibility!,
                  onChanged: (v) => _vm.setAccountVisibility(
                    value: v,
                    l10n: l10n,
                    trainlog: trainlog,
                  ),
                ),
      ),
      SettingsTile(
        icon: AdaptiveIcons.ranking,
        title: l10n.settingsAccountLeaderboard,
        enabled: _vm.accountLeaderboard != null,
        trailing: AdaptiveSwitch(
          value: _vm.accountLeaderboard ?? false,
          onChanged: _vm.accountLeaderboard == null
              ? null
              : (v) => _vm.setAccountLeaderboard(value: v, trainlog: trainlog),
        ),
      ),
      SettingsTile(
        icon: AdaptiveIcons.friends,
        title: l10n.settingsAccountFriendSearch,
        enabled: _vm.accountFriendSearch != null,
        trailing: AdaptiveSwitch(
          value: _vm.accountFriendSearch ?? false,
          onChanged: _vm.accountFriendSearch == null
              ? null
              : (v) => _vm.setAccountFriendSearch(value: v, trainlog: trainlog),
        ),
      ),
      SettingsTile(
        icon: AdaptiveIcons.world,
        title: l10n.settingsAccountAppearGlobal,
        subtitle: l10n.settingsAccountAppearGlobalSubtitle,
        enabled: _vm.accountAppearGlobal != null,
        trailing: AdaptiveSwitch(
          value: _vm.accountAppearGlobal ?? false,
          onChanged: _vm.accountAppearGlobal == null
              ? null
              : (v) => _vm.setAccountAppearGlobal(value: v, trainlog: trainlog),
        ),
      ),
    ]);
  }

  Widget _buildDangerSection(
    BuildContext ctx,
    AppLocalizations l10n,
    SettingsProvider settings,
    TripsProvider tripsProvider,
  ) {
    return SettingsGroup(children: [
      SettingsTile(
        icon: AdaptiveIcons.cache,
        title: l10n.settingsCacheTitle,
        subtitle: _vm.cacheSizeLabel(l10n, ctx),
        enabled: _vm.totalCacheSize > 0,
        trailing: AdaptiveDestructiveButton(
                  onPressed: () => _vm.totalCacheSize > 0 ? _confirmAndClearCache : null,
                ),
      ),
      SettingsTile(
        icon: AdaptiveIcons.deleteAccount,
        title: l10n.settingsDeleteAccount,
        trailing: AdaptiveButton.build(
          context: ctx,
          icon: AdaptiveIcons.mail,
          size: AdaptiveButton.small,
          label: Text(l10n.settingsDeleteAccountRequest),
          onPressed: _requestDeleteAccountMail,
        ),
      ),
    ]);
  }

  Widget _buildAboutSection(
    BuildContext ctx,
    AppLocalizations l10n,
    SettingsProvider settings,
    TrainlogProvider trainlog,
    TripsProvider tripsProvider,
  ) {
    final cs = Theme.of(ctx).colorScheme;

    return SettingsGroup(children: [
      SettingsTile(
        icon: AdaptiveIcons.instance,
        title: l10n.settingsInstanceUrl,
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
        title: l10n.appVersion,
        trailing: FutureBuilder<String>(
          future: _vm.getVersionString(),
          builder: (_, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => _vm.onVersionTapped(
                l10n: l10n,
                showCopiedInfo: () =>
                    AdaptiveInformationMessage.showInfo(l10n.appVersionCopied),
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
        title: l10n.settingsLicenses,
        trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
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
      if (kDebugMode)
        SettingsTile(
          icon: AdaptiveIcons.refresh,
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
      if (kDebugMode)
        SettingsTile(
          icon: AdaptiveIcons.refresh,
          title: 'Throw Test Exception',
          subtitle: 'debug',
          trailing: AdaptiveButton.build(
            context: ctx,
            label: const Text('Throw'),
            size: AdaptiveButton.small,
            onPressed: () => throw Exception(),
          ),
        ),
    ]);
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

/// Inline segmented-control row for theme selection.
class _ThemeRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<({String label, ThemeMode value})> options;
  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeRow({
    required this.icon,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final fgColor = isDark ? const Color(0xFFEEEEF0) : const Color(0xFF3A3A3C);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: icon square + label
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: fgColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Segmented control, centred within the tile
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Container(
              decoration: BoxDecoration(
                color: cs.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: options.map((entry) {
                  final selectedItem = selected == entry.value;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: selectedItem ? cs.secondary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => onChanged(entry.value),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            entry.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  selectedItem ? cs.onSecondary : cs.onSurface,
                              fontWeight: selectedItem
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal scrollable row showing the current palette's vehicle-type colours.
class _PaletteLegendRow extends StatelessWidget {
  final MapColorPalette palette;
  const _PaletteLegendRow({required this.palette});

  @override
  Widget build(BuildContext context) {
    final colors = MapColorPaletteHelper.getPalette(palette);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: VehicleType.values.map((type) {
            final color = colors[type] ?? Colors.grey;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(type.icon().icon, color: color),
            );
          }).toList(),
        ),
      ),
    );
  }
}
