import 'package:flutter/material.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_button.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_widget.dart';
import 'package:trainlog_app/ui/tokens/app_tab_theme.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/widgets/bottom_sheet_picker.dart';

// Material 3 (Android) renderings of the settings rows. The page uses the
// facades in settings_group.dart, which pick these or the iOS ones.

/// Section title: small, bold, upper case, in the primary colour.
class MaterialSettingsSectionHeader extends StatelessWidget {
  const MaterialSettingsSectionHeader(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
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
}

/// A rounded card that groups a list of widgets with auto-inserted dividers.
/// The divider indent aligns with the title column (16 + 40 + 12 = 68).
class MaterialSettingsGroup extends StatelessWidget {
  const MaterialSettingsGroup({
    super.key,
    required this.children,
    required this.hidesDivider,
  });

  final List<Widget> children;
  final bool Function(Widget child) hidesDivider;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1 && !hidesDivider(children[i]))
              Divider(
                height: 1,
                thickness: 1,
                indent: 68,
                endIndent: 0,
                color: cs.outline,
              ),
          ],
        ],
      ),
    );
  }
}

/// A settings row with a neutral icon badge, bold title, optional subtitle
/// and an optional trailing widget.
class MaterialSettingsTile extends StatelessWidget {
  const MaterialSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final fgColor = isDark ? const Color(0xFFEEEEF0) : const Color(0xFF3A3A3C);
    final cs = Theme.of(context).colorScheme;
    final disabledColor = cs.onSurface.withValues(alpha: 0.38);

    final effectiveFg = enabled ? fgColor : disabledColor;
    final effectiveBg = enabled
        ? bgColor
        : cs.onSurface.withValues(alpha: 0.12);

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: effectiveBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: effectiveFg, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: enabled ? null : disabledColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: enabled ? cs.onSurfaceVariant : disabledColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

/// A row whose value is picked from [options] in a bottom sheet; the current
/// value shows on the trailing side with a chevron.
class MaterialSettingsPickerTile<T> extends StatelessWidget {
  const MaterialSettingsPickerTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final List<({String label, T value})> options;
  final T? selected;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ctx = context;
    final current = selected;
    final name = current == null
        ? '—'
        : options
              .firstWhere(
                (o) => o.value == current,
                orElse: () => options.first,
              )
              .label;
    return MaterialSettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      enabled: enabled,
      trailing: _chevronTrailing(ctx, name),
      onTap: !enabled || current == null
          ? null
          : () => _showPicker(
              context: ctx,
              title: title,
              options: options,
              selected: current,
              onChanged: onChanged,
            ),
    );
  }

  Widget _chevronTrailing(BuildContext context, String label) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.35,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
            ),
          ),
          const SizedBox(width: 2),
          Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
        ],
      ),
    );
  }

  Future<void> _showPicker({
    required BuildContext context,
    required String title,
    required List<({String label, T value})> options,
    required T selected,
    required ValueChanged<T> onChanged,
  }) {
    return showBottomSheetPicker<T>(
      context: context,
      title: title,
      selected: selected,
      onChanged: onChanged,
      options: [
        for (final o in options)
          BottomSheetPickerOption<T>(value: o.value, label: o.label),
      ],
    );
  }
}

/// Trailing outlined button showing a value (e.g. the currency).
class MaterialSettingsValueButton extends StatelessWidget {
  const MaterialSettingsValueButton({
    super.key,
    required this.value,
    required this.onPressed,
  });

  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    child: Text(value),
  );
}

/// Trailing chevron of a row that opens a page.
class MaterialSettingsChevron extends StatelessWidget {
  const MaterialSettingsChevron({super.key});

  @override
  Widget build(BuildContext context) => Icon(
    Icons.chevron_right,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
    size: 20,
  );
}

/// "Clear cache" row: the size as subtitle, a destructive icon button.
class MaterialSettingsClearCacheTile extends StatelessWidget {
  const MaterialSettingsClearCacheTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onClear,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => MaterialSettingsTile(
    icon: icon,
    title: title,
    subtitle: subtitle,
    enabled: enabled,
    trailing: AdaptiveDestructiveButton(
      onPressed: () => enabled ? onClear() : null,
    ),
  );
}

/// "Delete account" row with a small destructive button.
class MaterialSettingsDeleteAccountTile extends StatelessWidget {
  const MaterialSettingsDeleteAccountTile({
    super.key,
    required this.icon,
    required this.title,
    required this.buttonLabel,
    required this.onDelete,
  });

  final IconData icon;
  final String title;
  final String buttonLabel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => MaterialSettingsTile(
    icon: icon,
    title: title,
    trailing: AdaptiveButton.build(
      context: context,
      type: AdaptiveButtonType.destructive,
      size: AdaptiveButton.small,
      label: Text(buttonLabel),
      onPressed: onDelete,
    ),
  );
}

/// Theme row: icon badge and title, the Light / System / Dark segmented
/// track under them.
class MaterialSettingsThemeRow extends StatelessWidget {
  const MaterialSettingsThemeRow({
    super.key,
    required this.icon,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final List<({String label, ThemeMode value})> options;
  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final fgColor = isDark ? const Color(0xFFEEEEF0) : const Color(0xFF3A3A3C);
    final tabColors = Theme.of(context).extension<AppTabColors>()!;

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
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Segmented control, centred within the tile
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Container(
              decoration: BoxDecoration(
                color: tabColors.tabBackground,
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
                        color: selectedItem
                            ? tabColors.selectedBackground
                            : Colors.transparent,
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
                              color: selectedItem
                                  ? tabColors.onSelected
                                  : cs.onSurface,
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

/// The palette's vehicle colours, in a horizontally scrolling row.
class MaterialSettingsPaletteLegend extends StatelessWidget {
  const MaterialSettingsPaletteLegend({super.key, required this.palette});

  final MapColorPalette palette;

  @override
  Widget build(BuildContext context) {
    final colors = MapColorPaletteHelper.getPalette(palette);
    return Padding(
      // Apple: start under the row titles, like the separators.
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
