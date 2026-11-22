import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/ui/cupertino/glass_pop_up_button.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/widgets/app_steps_tab_bar.dart';

// iOS 26 renderings of the settings rows: an inset grouped list as in the
// Settings app (big continuous corners, coloured 30 pt icon squares with a
// white glyph, 17 pt titles, hairline separators starting under the title).
// The page uses the facades in settings_group.dart, which pick these or the
// Material ones.

const double _groupRadius = 26;
const double _iconSize = 30;
const double _iconGap = 14;
const double _rowPadding = 16;
const double _separatorIndent = _rowPadding + _iconSize + _iconGap;

/// iOS section header, sentence case like iOS 26 (no more ALL CAPS).
class CupertinoSettingsSectionHeader extends StatelessWidget {
  const CupertinoSettingsSectionHeader(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_rowPadding, 26, 16, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }
}

/// iOS grouped cell: white / elevated dark, hairline separators under the
/// titles, except after a child for which [hidesDivider] is true.
class CupertinoSettingsGroup extends StatelessWidget {
  const CupertinoSettingsGroup({
    super.key,
    required this.children,
    required this.hidesDivider,
  });

  final List<Widget> children;
  final bool Function(Widget child) hidesDivider;

  @override
  Widget build(BuildContext context) {
    final separator = CupertinoColors.separator.resolveFrom(context);
    const shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.all(Radius.circular(_groupRadius)),
    );
    return ClipRSuperellipse(
      borderRadius: const BorderRadius.all(Radius.circular(_groupRadius)),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: shape,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1 && !hidesDivider(children[i]))
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: _separatorIndent,
                  ),
                  child: Container(height: 0.5, color: separator),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// iOS Settings icon: a coloured continuous square with a white glyph.
class CupertinoSettingsIcon extends StatelessWidget {
  const CupertinoSettingsIcon({
    super.key,
    required this.icon,
    this.color,
    this.enabled = true,
  });

  final IconData icon;
  final Color? color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final fill = CupertinoDynamicColor.resolve(
      color ?? CupertinoColors.systemGrey,
      context,
    );
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: fill,
          shape: const RoundedSuperellipseBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        child: SizedBox.square(
          dimension: _iconSize,
          child: Icon(icon, color: CupertinoColors.white, size: 19),
        ),
      ),
    );
  }
}

/// One iOS grouped-list row: icon, 17 pt title (+ subtitle), trailing.
/// Highlights grey while pressed, like a UITableViewCell.
class CupertinoSettingsRow extends StatefulWidget {
  const CupertinoSettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.destructive = false,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool destructive;

  @override
  State<CupertinoSettingsRow> createState() => _CupertinoSettingsRowState();
}

class _CupertinoSettingsRowState extends State<CupertinoSettingsRow> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final tappable = widget.enabled && widget.onTap != null;
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final disabled = CupertinoColors.tertiaryLabel.resolveFrom(context);
    final titleColor = !widget.enabled
        ? disabled
        : widget.destructive
        ? CupertinoColors.destructiveRed.resolveFrom(context)
        : label;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: tappable ? (_) => _setPressed(true) : null,
      onTapUp: tappable ? (_) => _setPressed(false) : null,
      onTapCancel: tappable ? () => _setPressed(false) : null,
      onTap: tappable ? widget.onTap : null,
      child: AnimatedContainer(
        duration: Duration(milliseconds: _pressed ? 0 : 250),
        color: _pressed
            ? CupertinoColors.systemGrey4.resolveFrom(context)
            : CupertinoColors.systemGrey4.resolveFrom(context).withAlpha(0),
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(
          horizontal: _rowPadding,
          vertical: 10,
        ),
        child: Row(
          children: [
            CupertinoSettingsIcon(
              icon: widget.icon,
              color: widget.iconColor,
              enabled: widget.enabled,
            ),
            const SizedBox(width: _iconGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(fontSize: 17, color: titleColor),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.enabled ? secondary : disabled,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.trailing != null) ...[
              const SizedBox(width: 8),
              DefaultTextStyle.merge(
                style: TextStyle(
                  fontSize: 17,
                  color: widget.enabled ? secondary : disabled,
                ),
                child: widget.trailing!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// iOS disclosure: optional grey value, then a small chevron.
class CupertinoSettingsDisclosure extends StatelessWidget {
  const CupertinoSettingsDisclosure({super.key, this.value});

  final String? value;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.45,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Flexible(
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 17, color: secondary),
              ),
            ),
          const SizedBox(width: 6),
          Icon(
            CupertinoIcons.chevron_forward,
            size: 15,
            color: CupertinoColors.tertiaryLabel.resolveFrom(context),
          ),
        ],
      ),
    );
  }
}

/// A row whose value is picked from a Liquid Glass pop-up menu; the whole
/// row opens it.
class CupertinoSettingsMenuTile<T> extends StatelessWidget {
  const CupertinoSettingsMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.iconColor,
    this.subtitle,
    this.enabled = true,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final List<({String label, T value})> options;
  final T? selected;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final active = enabled && selected != null;
    return GlassPopUpButton<T>(
      options: options,
      selected: selected,
      onChanged: onChanged,
      enabled: active,
      semanticLabel: title,
      builder: (context, button, open) => CupertinoSettingsRow(
        icon: icon,
        iconColor: iconColor,
        title: title,
        subtitle: subtitle,
        enabled: active,
        onTap: open,
        trailing: button,
      ),
    );
  }
}

/// "Clear cache" row: the size reads as the subtitle and the action is
/// plain red text, like "Clear History" in iOS Settings. The row clears.
class CupertinoSettingsClearCacheTile extends StatelessWidget {
  const CupertinoSettingsClearCacheTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.enabled,
    required this.onClear,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool enabled;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => CupertinoSettingsRow(
    icon: icon,
    iconColor: iconColor,
    title: title,
    subtitle: subtitle,
    enabled: enabled,
    onTap: enabled ? onClear : null,
    trailing: Text(
      buttonLabel,
      style: TextStyle(
        color: enabled
            ? CupertinoColors.destructiveRed.resolveFrom(context)
            : CupertinoColors.tertiaryLabel.resolveFrom(context),
      ),
    ),
  );
}

/// "Delete account" row: a red title, the row is the button.
class CupertinoSettingsDeleteAccountTile extends StatelessWidget {
  const CupertinoSettingsDeleteAccountTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onDelete,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => CupertinoSettingsRow(
    icon: icon,
    iconColor: iconColor,
    title: title,
    destructive: true,
    onTap: onDelete,
  );
}

/// Theme row: iOS row header (coloured icon + 17 pt title) with the iOS
/// segmented control under it, aligned with the title, text only (iOS
/// segments show an icon or text, not both).
class CupertinoSettingsThemeRow extends StatelessWidget {
  const CupertinoSettingsThemeRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final List<({String label, ThemeMode value})> options;
  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final index = options.indexWhere((o) => o.value == selected);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CupertinoSettingsIcon(icon: icon, color: iconColor),
              const SizedBox(width: _iconGap),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: _iconSize + _iconGap),
            child: AppStepsTabBar(
              fullWidth: true,
              tabs: [for (final o in options) AppStepsTab(label: o.label)],
              selectedIndex: index < 0 ? 0 : index,
              onTabChanged: (i) => onChanged(options[i].value),
            ),
          ),
        ],
      ),
    );
  }
}

/// The palette's vehicle colours, wrapping under the row titles instead of
/// scrolling, so none is cut at the cell edge.
class CupertinoSettingsPaletteLegend extends StatelessWidget {
  const CupertinoSettingsPaletteLegend({super.key, required this.palette});

  final MapColorPalette palette;

  @override
  Widget build(BuildContext context) {
    final colors = MapColorPaletteHelper.getPalette(palette);
    return Padding(
      padding: const EdgeInsets.fromLTRB(60, 0, 16, 12),
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        children: [
          for (final type in VehicleType.values)
            Icon(
              type.icon().icon,
              color: colors[type] ?? Colors.grey,
              size: 22,
            ),
        ],
      ),
    );
  }
}
