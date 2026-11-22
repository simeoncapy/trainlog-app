import 'package:flutter/material.dart';
import 'package:trainlog_app/features/settings/widgets/cupertino/settings_cupertino.dart';
import 'package:trainlog_app/features/settings/widgets/material/settings_material.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';

// The settings page is one page for both designs, built from the rows below.
// Each row picks its Material 3 rendering (material/settings_material.dart)
// or its iOS 26 one (cupertino/settings_cupertino.dart) with PlatformView.
// Parameters named `apple…` only change the iOS rendering.

/// Section title above a group.
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => PlatformView(
    material: (_) => MaterialSettingsSectionHeader(label),
    cupertino: (_) => CupertinoSettingsSectionHeader(label),
  );
}

/// A card (Android) or an inset grouped cell (iOS) holding rows, with a
/// divider between them unless a row asks for none ([SettingsTile.noDivider],
/// [SettingsPickerTile.noDivider]).
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  static bool hidesDivider(Widget w) =>
      (w is SettingsTile && w.noDivider) ||
      (w is SettingsPickerTile && w.noDivider);

  @override
  Widget build(BuildContext context) => PlatformView(
    material: (_) =>
        MaterialSettingsGroup(hidesDivider: hidesDivider, children: children),
    cupertino: (_) =>
        CupertinoSettingsGroup(hidesDivider: hidesDivider, children: children),
  );
}

/// A settings row: icon, title, optional subtitle and trailing widget.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.appleOnTap,
    this.enabled = true,
    this.noDivider = false,
    this.appleIconColor,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// iOS only, when [onTap] is null: a tap on the row, where Android only
  /// reacts on its trailing control (iOS rows are tapped as a whole).
  final VoidCallback? appleOnTap;
  final bool enabled;

  /// No divider under this row in its [SettingsGroup].
  final bool noDivider;

  /// iOS only: colour of the icon square. Grey when null.
  final Color? appleIconColor;

  /// iOS only: red title, for actions such as "Delete account".
  final bool destructive;

  @override
  Widget build(BuildContext context) => PlatformView(
    material: (_) => MaterialSettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      enabled: enabled,
    ),
    cupertino: (_) => CupertinoSettingsRow(
      icon: icon,
      iconColor: appleIconColor,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap ?? appleOnTap,
      enabled: enabled,
      destructive: destructive,
    ),
  );
}

/// A row whose value is picked from [options]: a bottom sheet on Android,
/// an iOS 26 pop-up menu (Liquid Glass) on iOS. Disabled while [selected]
/// is null (value not loaded yet).
class SettingsPickerTile<T> extends StatelessWidget {
  const SettingsPickerTile({
    super.key,
    required this.icon,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.appleIconColor,
    this.subtitle,
    this.enabled = true,
    this.noDivider = false,
  });

  final IconData icon;
  final Color? appleIconColor;
  final String title;
  final String? subtitle;
  final List<({String label, T value})> options;
  final T? selected;
  final ValueChanged<T> onChanged;
  final bool enabled;
  final bool noDivider;

  @override
  Widget build(BuildContext context) => PlatformView(
    material: (_) => MaterialSettingsPickerTile<T>(
      icon: icon,
      title: title,
      subtitle: subtitle,
      options: options,
      selected: selected,
      onChanged: onChanged,
      enabled: enabled,
    ),
    cupertino: (_) => CupertinoSettingsMenuTile<T>(
      icon: icon,
      iconColor: appleIconColor,
      title: title,
      subtitle: subtitle,
      options: options,
      selected: selected,
      onChanged: onChanged,
      enabled: enabled,
    ),
  );
}

/// Trailing value that opens a picker: an outlined button on Android, a grey
/// value with a chevron on iOS (pair it with [SettingsTile.appleOnTap]).
class SettingsValueButton extends StatelessWidget {
  const SettingsValueButton({
    super.key,
    required this.value,
    required this.onPressed,
  });

  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => PlatformView(
    material: (_) =>
        MaterialSettingsValueButton(value: value, onPressed: onPressed),
    cupertino: (_) => CupertinoSettingsDisclosure(value: value),
  );
}

/// Trailing chevron of a row that opens a page.
class SettingsChevron extends StatelessWidget {
  const SettingsChevron({super.key});

  @override
  Widget build(BuildContext context) => PlatformView(
    material: (_) => const MaterialSettingsChevron(),
    cupertino: (_) => const CupertinoSettingsDisclosure(),
  );
}

/// "Clear cache" row, with the cache size as subtitle. Disabled when there
/// is nothing to clear.
class SettingsClearCacheTile extends StatelessWidget {
  const SettingsClearCacheTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.enabled,
    required this.onClear,
    this.appleIconColor,
  });

  final IconData icon;
  final Color? appleIconColor;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool enabled;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => PlatformView(
    material: (_) => MaterialSettingsClearCacheTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      enabled: enabled,
      onClear: onClear,
    ),
    cupertino: (_) => CupertinoSettingsClearCacheTile(
      icon: icon,
      iconColor: appleIconColor,
      title: title,
      subtitle: subtitle,
      buttonLabel: buttonLabel,
      enabled: enabled,
      onClear: onClear,
    ),
  );
}

/// "Delete account" row.
class SettingsDeleteAccountTile extends StatelessWidget {
  const SettingsDeleteAccountTile({
    super.key,
    required this.icon,
    required this.title,
    required this.buttonLabel,
    required this.onDelete,
    this.appleIconColor,
  });

  final IconData icon;
  final Color? appleIconColor;
  final String title;
  final String buttonLabel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => PlatformView(
    material: (_) => MaterialSettingsDeleteAccountTile(
      icon: icon,
      title: title,
      buttonLabel: buttonLabel,
      onDelete: onDelete,
    ),
    cupertino: (_) => CupertinoSettingsDeleteAccountTile(
      icon: icon,
      iconColor: appleIconColor,
      title: title,
      onDelete: onDelete,
    ),
  );
}

/// Theme row: the title, then a Light / System / Dark segmented control.
class SettingsThemeRow extends StatelessWidget {
  const SettingsThemeRow({
    super.key,
    required this.icon,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.appleIconColor,
  });

  final IconData icon;
  final Color? appleIconColor;
  final String title;
  final List<({String label, ThemeMode value})> options;
  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) => PlatformView(
    material: (_) => MaterialSettingsThemeRow(
      icon: icon,
      title: title,
      options: options,
      selected: selected,
      onChanged: onChanged,
    ),
    cupertino: (_) => CupertinoSettingsThemeRow(
      icon: icon,
      iconColor: appleIconColor,
      title: title,
      options: options,
      selected: selected,
      onChanged: onChanged,
    ),
  );
}

/// The vehicle colours of a map palette, under the palette row.
class SettingsPaletteLegend extends StatelessWidget {
  const SettingsPaletteLegend({super.key, required this.palette});

  final MapColorPalette palette;

  @override
  Widget build(BuildContext context) => PlatformView(
    material: (_) => MaterialSettingsPaletteLegend(palette: palette),
    cupertino: (_) => CupertinoSettingsPaletteLegend(palette: palette),
  );
}
