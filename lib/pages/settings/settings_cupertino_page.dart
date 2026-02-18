import 'dart:async';

import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/platform/adaptive_information_message.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';

import 'settings_blueprint.dart';
import 'settings_vm.dart';

class SettingsCupertinoPage extends StatefulWidget {
  const SettingsCupertinoPage({super.key});

  @override
  State<SettingsCupertinoPage> createState() => _SettingsCupertinoPageState();
}

class _SettingsCupertinoPageState extends State<SettingsCupertinoPage> {
  final SettingsVm _vm = SettingsVm();

  @override
  void initState() {
    super.initState();

    // Same init pattern as Material page: after first frame so context is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
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

  // ----------------------------
  // iOS helpers
  // ----------------------------

  Future<void> _showChoiceSheet(SettingsChoiceSpec<dynamic> item) async {
    if (!item.enabled) return;

    final dyn = item as dynamic;
    final List options = dyn.options as List;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        return CupertinoActionSheet(
          title: Text(item.title),
          message: item.subtitle == null ? null : Text(item.subtitle!),
          actions: [
            for (final o in options)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  // dyn.onChanged expects (T?) in blueprint, but here we pass the value.
                  if (dyn.onChanged != null) {
                    dyn.onChanged((o as dynamic).value);
                  }
                },
                child: Text(
                  style: TextStyle(
                    fontWeight: dyn.value == (o as dynamic).value ? FontWeight.bold : null
                  ),
                  (o as dynamic).label as String
                ),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(CupertinoLocalizations.of(context).cancelButtonLabel),
          ),
        );
      },
    );
  }

  Future<void> _confirmAndClearCache() async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.settingsCacheClearConfirmTitle),
        content: Text(l10n.settingsCacheClearConfirmMessage),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(CupertinoLocalizations.of(context).cancelButtonLabel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.settingsCacheClearButton),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final settings = context.read<SettingsProvider>();
      final tripsProvider = context.read<TripsProvider>();

      await _vm.clearCache(settings: settings, tripsProvider: tripsProvider);

      if (!mounted) return;
      AdaptiveInformationMessage.show(context, l10n.settingsCacheClearedMessage);
    }
  }

  Future<void> _requestDeleteAccountMail() async {
    final l10n = AppLocalizations.of(context)!;
    final trainlog = context.read<TrainlogProvider>();

    final uri = _vm.buildDeleteAccountMailUri(
      username: trainlog.username ?? "",
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      AdaptiveInformationMessage.show(context, l10n.settingsDeleteAccountError(SettingsVm.deleteAccountEmail));
    }
  }

  Future<void> _showCurrencyPickerCupertino() async {
    final settings = context.read<SettingsProvider>();
    final trainlog = context.read<TrainlogProvider>();

    // Ensure we have currencies; your vm.init likely does it, but keep this safe.
    if (trainlog.availableCurrencies.isEmpty) {
      await trainlog.reloadAvailableCurrencies();
    }
    if (!mounted) return;

    final allowedCodes = trainlog.availableCurrencies;
    final all = CurrencyService().getAll();

    final currencies = allowedCodes.isEmpty
        ? all
        : all.where((c) => allowedCodes.contains(c.code)).toList(growable: false);

    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => _CupertinoCurrencyPickerPage(
          current: settings.currency,
          currencies: currencies,
          onPick: (code) => settings.setCurrency(code),
        ),
      ),
    );
  }

  // ----------------------------
  // Build
  // ----------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mq = MediaQuery.of(context);

    final settings = context.watch<SettingsProvider>();
    final trainlog = context.read<TrainlogProvider>();

    return AnimatedBuilder(
      animation: _vm,
      builder: (ctx, _) {
        final sections = buildSettingsBlueprint(
          context: context,
          settings: settings,
          trainlog: trainlog,
          vm: _vm,
          l10n: l10n,
          showCurrencyPickerMaterialOrCupertino: _showCurrencyPickerCupertino,
          confirmAndClearCache: _confirmAndClearCache,
          requestDeleteAccountMail: _requestDeleteAccountMail,
        );

        return ListView(
          children: [
            const SizedBox(height: 8),
            for (final section in sections) ...[
              CupertinoListSection.insetGrouped(
                header: Text(section.header),
                children: [
                  for (final item in section.items) _buildCupertinoItem(item),
                ],
              ),
            ],
            //const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildCupertinoItem(SettingsItemSpec item) {
    // --- Toggle ---
    if (item is SettingsToggleSpec) {
      final canChange = item.enabled && item.onChanged != null;

      return CupertinoListTile(
        leading: Icon(item.icon),
        title: Text(item.title),
        subtitle: item.subtitle == null ? null : Text(item.subtitle!),
        trailing: CupertinoSwitch(
          value: item.value,
          onChanged: canChange ? item.onChanged : null,
        ),
      );
    }

    // --- Choice (shows action sheet) ---
    if (item is SettingsChoiceSpec) {
      final dyn = item as dynamic;

      final String trailingValue = () {
        // Always display the human label (same one used in the sheet).
        final List opts = dyn.options as List;
        for (final o in opts) {
          final opt = o as dynamic;
          if (opt.value == dyn.value) {
            return opt.label as String;
          }
        }
        // Fallback (shouldn't happen unless options mismatch)
        return dyn.value.toString();
      }();

      return CupertinoListTile(
        leading: Icon(item.icon),
        title: Text(item.title),
        subtitle: item.subtitle == null ? null : Text(item.subtitle!),
        additionalInfo: Text(trailingValue),
        trailing: const CupertinoListTileChevron(),
        onTap: item.enabled ? () => _showChoiceSheet(item) : null,
      );
    }

    // --- Currency (push iOS currency picker page) ---
    if (item is SettingsCurrencySpec) {
      return CupertinoListTile(
        leading: Icon(item.icon),
        title: Text(item.title),
        additionalInfo: Text(item.currencyCode),
        trailing: const CupertinoListTileChevron(),
        onTap: item.enabled ? item.onPick : null,
      );
    }

    // --- Missing palette legend row (horizontal scroll icons) ---
    if (item is SettingsPaletteLegendSpec) {
      final palette = MapColorPaletteHelper.getPalette(item.palette);

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: VehicleType.values.map((type) {
              final color = palette[type] ?? CupertinoColors.systemGrey;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  type.icon().icon,
                  color: color,
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    // --- Danger actions ---
    if (item is SettingsButtonActionSpec) {
      return CupertinoListTile(
        leading: Icon(item.icon),
        title: Text(item.title,),
        trailing: item.button,
      );
    }

    // --- Version ---
    if (item is SettingsVersionSpec) {
      return FutureBuilder<String>(
        future: item.versionFuture(),
        builder: (context, snap) {
          final version = snap.data ?? '';

          return CupertinoListTile(
            leading: Icon(item.icon),
            title: Text(item.title),
            additionalInfo: Text(version),
            onTap: item.onTap,
          );
        },
      );
    }

    if (item is SettingsStringSpec) {
      return CupertinoListTile(
        leading: Icon(item.icon),
        title: Text(item.title),
        additionalInfo: Text(item.value),
        onTap: item.onTap,
      );
    }

    return const SizedBox.shrink();
  }
}

// ---------------------------------------------------------
// Currency Picker (Cupertino style, searchable list of codes)
// ---------------------------------------------------------

class _CupertinoCurrencyPickerPage extends StatefulWidget {
  final String current;
  final List<Currency> currencies;
  final ValueChanged<String> onPick;

  const _CupertinoCurrencyPickerPage({
    required this.current,
    required this.currencies,
    required this.onPick,
  });

  @override
  State<_CupertinoCurrencyPickerPage> createState() => _CupertinoCurrencyPickerPageState();
}

class _CupertinoCurrencyPickerPageState extends State<_CupertinoCurrencyPickerPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final q = _query.trim().toLowerCase();

    final filtered = q.isEmpty
        ? widget.currencies
        : widget.currencies.where((c) {
            final code = c.code.toLowerCase();
            final name = c.name.toLowerCase();
            return code.contains(q) || name.contains(q);
          }).toList(growable: false);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.settingsCurrency),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: CupertinoSearchTextField(
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final c = filtered[i];
                  final selected = c.code == widget.current;

                  return CupertinoListTile(
                    backgroundColor: selected ? CupertinoColors.systemFill.resolveFrom(context) : null,
                    title: Text('${CurrencyUtils.currencyToEmoji(c)} ${c.code} — ${c.name}'),
                    trailing: selected
                        ? const Icon(CupertinoIcons.check_mark, size: 18)
                        : const CupertinoListTileChevron(),
                    onTap: () {
                      widget.onPick(c.code);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
