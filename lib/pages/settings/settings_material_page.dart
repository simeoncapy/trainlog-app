import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/utils/style_utils.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';

import 'settings_blueprint.dart';
import 'settings_vm.dart';

class SettingsMaterialPage extends StatefulWidget {
  const SettingsMaterialPage({super.key});

  @override
  State<SettingsMaterialPage> createState() => _SettingsMaterialPageState();
}

class _SettingsMaterialPageState extends State<SettingsMaterialPage> {
  final SettingsVm _vm = SettingsVm();

  @override
  void initState() {
    super.initState();
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

  Future<void> _showCurrencyPickerMaterial() async {
    final settings = context.read<SettingsProvider>();
    final trainlog = context.read<TrainlogProvider>();

    showCurrencyPicker(
      context: context,
      showFlag: true,
      currencyFilter: trainlog.availableCurrencies.isEmpty ? null : trainlog.availableCurrencies,
      showCurrencyName: true,
      onSelect: (currency) => settings.setCurrency(currency.code),
    );
  }

  Future<void> _confirmAndClearCache() async {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.read<SettingsProvider>();
    final tripsProvider = context.read<TripsProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.settingsCacheClearConfirmTitle),
        content: Text(l10n.settingsCacheClearConfirmMessage),
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
      await _vm.clearCache(settings: settings, tripsProvider: tripsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsCacheClearedMessage)),
      );
    }
  }

  Future<void> _requestDeleteAccountMail() async {
    final l10n = AppLocalizations.of(context)!;
    final trainlog = context.read<TrainlogProvider>();
    final scaffMsg = ScaffoldMessenger.of(context);

    final uri = _vm.buildDeleteAccountMailUri(
      username: trainlog.username ?? "",
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      scaffMsg.showSnackBar(
        SnackBar(content: Text(l10n.settingsDeleteAccountError(SettingsVm.deleteAccountEmail))),
      );
    }
  }


  void _showCopiedInfo() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.appVersionCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final settings = context.watch<SettingsProvider>();
    final trainlog = context.read<TrainlogProvider>();    

    return Scaffold(
      //appBar: AppBar(title: Text(l10n.menuSettingsTitle)),
      body: AnimatedBuilder(
        animation: _vm,
        builder: (ctx, _) {
          final sections = buildSettingsBlueprint(
            context: ctx,
            settings: settings,
            trainlog: trainlog,
            vm: _vm,
            l10n: l10n,
            showCopiedInfo: _showCopiedInfo,
            showCurrencyPickerMaterialOrCupertino: _showCurrencyPickerMaterial,
            confirmAndClearCache: _confirmAndClearCache,
            requestDeleteAccountMail: _requestDeleteAccountMail,
          );

          return ListView(
            children: [
              for (final s in sections) ...[
                _sectionHeader(ctx, s.header),
                for (final item in s.items) _buildMaterialItem(ctx, item),
              ],
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
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

  Widget _buildMaterialItem(BuildContext context, SettingsItemSpec item) {
    if (item is SettingsToggleSpec) {
      return ListTile(
        leading: Icon(item.icon),
        title: Text(item.title),
        subtitle: item.subtitle == null ? null : Text(item.subtitle!),
        enabled: item.enabled,
        trailing: Switch(
          value: item.value,
          onChanged: item.enabled ? item.onChanged : null,
        ),
      );
    }

    if (item is SettingsCurrencySpec) {
      return ListTile(
        leading: Icon(item.icon),
        title: Text(item.title),
        enabled: item.enabled,
        trailing: OutlinedButton(
          onPressed: item.enabled ? item.onPick : null,
          child: Text(item.currencyCode),
        ),
      );
    }

    if (item is SettingsChoiceSpec) {
      final dyn = item as dynamic;

      final void Function(dynamic)? onChangedDyn =
          (item.enabled && dyn.onChanged != null)
              ? (dynamic v) => dyn.onChanged(v)
              : null;

      if (item.materialLayout == MaterialChoiceLayout.inlineDropdown) {
        return ListTile(
          leading: Icon(item.icon),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: Theme.of(context).textTheme.bodyMedium),
              DropdownButton<dynamic>(
                isExpanded: true,
                value: dyn.value,
                onChanged: onChangedDyn,
                items: (dyn.options as List).map<DropdownMenuItem<dynamic>>((o) {
                  final opt = o as dynamic;
                  return DropdownMenuItem<dynamic>(
                    value: opt.value,
                    child: Text(opt.label),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }

      return ListTile(
        leading: Icon(item.icon),
        title: Text(item.title),
        subtitle: item.subtitle == null ? null : Text(item.subtitle!),
        enabled: item.enabled,
        trailing: DropdownButton<dynamic>(
          value: dyn.value,
          onChanged: onChangedDyn,
          items: (dyn.options as List).map<DropdownMenuItem<dynamic>>((o) {
            final opt = o as dynamic;
            return DropdownMenuItem<dynamic>(
              value: opt.value,
              child: Text(opt.label),
            );
          }).toList(),
        ),
      );
    }

    if (item is SettingsDangerActionSpec) {
      final l10n = AppLocalizations.of(context)!;
      final scheme = Theme.of(context).colorScheme;

      if (item.style == DangerActionStyle.clearCache) {
        return ListTile(
          leading: Icon(item.icon),
          title: Text(
            // same as before: show human cache size string
            l10n.settingsCache(formatNumber(context, _vm.totalCacheSize)),
          ),
          trailing: ElevatedButton.icon(
            onPressed: item.enabled ? item.onPressed : null,
            icon: const Icon(Icons.delete),
            label: Text(l10n.settingsCacheClearButton),
            style: buttonStyleHelper(scheme.error, scheme.onError),
          ),
        );
      }

      // delete account
      return ListTile(
        leading: Icon(item.icon),
        title: Text(item.title),
        trailing: ElevatedButton.icon(
          icon: const Icon(Icons.mail),
          label: Text(l10n.settingsDeleteAccountRequest),
          onPressed: item.onPressed,
        ),
      );
    }

    if (item is SettingsVersionSpec) {
      return ListTile(
        leading: Icon(item.icon),
        title: Text(item.title),
        trailing: FutureBuilder<String>(
          future: item.versionFuture(),
          builder: (context, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            return GestureDetector(
              onTap: item.onTap,
              child: Text(snap.data!),
            );
          },
        ),
      );
    }

    if (item is SettingsPaletteLegendSpec) {
      final palette = MapColorPaletteHelper.getPalette(item.palette);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: VehicleType.values.map((type) {
                final color = palette[type] ?? Colors.grey;

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
          const SizedBox(height: 8),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
