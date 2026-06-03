import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
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
            child: Text(l10n.settingsCacheClearButton),
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
          final sections = buildSettingsBlueprint(
            context: ctx,
            settings: settings,
            trainlog: trainlog,
            tripsProvider: tripsProvider,
            vm: _vm,
            l10n: l10n,
            showCurrencyPickerMaterialOrCupertino: _showCurrencyPickerMaterial,
            confirmAndClearCache: _confirmAndClearCache,
            requestDeleteAccountMail: _requestDeleteAccountMail,
          );

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 8),
              for (final s in sections) ...[
                _sectionHeader(ctx, s.header),
                _sectionCard(ctx, s.items),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 6),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
      ),
    );
  }

  Widget _sectionCard(BuildContext context, List<SettingsItemSpec> items) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 1),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              _buildMaterialItem(context, items[i]),
              if (i < items.length - 1)
                const Divider(height: 1, indent: 56),
            ],
          ],
        ),
      ),
    );
  }

  // Neutral rounded-square icon badge that adapts to light/dark mode.
  Widget _iconSquare(BuildContext context, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final fg = isDark ? const Color(0xFFEEEEF0) : const Color(0xFF3A3A3C);

    // final cs = Theme.of(context).colorScheme;
    // final bg = cs.secondaryContainer;
    // final fg = cs.onSecondaryContainer;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, color: fg, size: 18),
    );
  }

  // Bordered pill showing the selected value; contains the real DropdownButton.
  Widget _styledDropdown(
    BuildContext context, {
    required dynamic value,
    required List<dynamic> options,
    required void Function(dynamic)? onChanged,
    bool expanded = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final dropdown = DropdownButtonHideUnderline(
      child: DropdownButton<dynamic>(
        isDense: true,
        isExpanded: expanded,
        value: value,
        onChanged: onChanged,
        items: options.map<DropdownMenuItem<dynamic>>((o) {
          final opt = o as dynamic;
          return DropdownMenuItem<dynamic>(
            value: opt.value,
            child: Text(opt.label as String),
          );
        }).toList(),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outline.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: expanded ? dropdown : IntrinsicWidth(child: dropdown),
    );
  }

  Widget _buildMaterialItem(BuildContext context, SettingsItemSpec item) {
    if (item is SettingsToggleSpec) {
      return ListTile(
        leading: _iconSquare(context, item.icon),
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
      final cs = Theme.of(context).colorScheme;
      return ListTile(
        leading: _iconSquare(context, item.icon),
        title: Text(item.title),
        enabled: item.enabled,
        trailing: OutlinedButton(
          onPressed: item.enabled ? item.onPick : null,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            side: BorderSide(color: cs.outline.withOpacity(0.5)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
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
          leading: _iconSquare(context, item.icon),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: Theme.of(context).textTheme.bodyMedium),
              _styledDropdown(
                context,
                value: dyn.value,
                options: dyn.options as List,
                onChanged: onChangedDyn,
                expanded: true,
              ),
            ],
          ),
        );
      }

      return ListTile(
        leading: _iconSquare(context, item.icon),
        title: Text(item.title),
        subtitle: item.subtitle == null ? null : Text(item.subtitle!),
        enabled: item.enabled,
        trailing: _styledDropdown(
          context,
          value: dyn.value,
          options: dyn.options as List,
          onChanged: onChangedDyn,
        ),
      );
    }

    if (item is SettingsButtonActionSpec) {
      return ListTile(
        leading: _iconSquare(context, item.icon),
        title: Text(item.title),
        trailing: item.button,
      );
    }

    if (item is SettingsVersionSpec) {
      return ListTile(
        leading: _iconSquare(context, item.icon),
        title: Text(item.title),
        trailing: FutureBuilder<String>(
          future: item.versionFuture(),
          builder: (context, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            return GestureDetector(
              onTap: item.onTap,
              child: Text(
                snap.data!,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            );
          },
        ),
      );
    }

    if (item is SettingsStringSpec) {
      return ListTile(
        leading: _iconSquare(context, item.icon),
        title: Text(item.title),
        trailing: GestureDetector(
          onTap: item.onTap,
          child: Text(
            item.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'monospace',
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    if (item is SettingsPaletteLegendSpec) {
      final palette = MapColorPaletteHelper.getPalette(item.palette);

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: VehicleType.values.map((type) {
              final color = palette[type] ?? Colors.grey;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(type.icon().icon, color: color),
              );
            }).toList(),
          ),
        ),
      );
    }

    if (item is SettingsTextSpec) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text(
          item.title,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
