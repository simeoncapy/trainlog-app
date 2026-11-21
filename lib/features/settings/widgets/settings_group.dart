import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;
import 'package:trainlog_app/utils/platform_utils.dart';

// ── Apple (iOS 26) metrics ────────────────────────────────────────────────────
// Inset grouped list as in the iOS 26 Settings app: big continuous corners,
// coloured 30 pt icon squares with a white glyph, 17 pt titles and hairline
// separators that start under the title.
const double _appleGroupRadius = 26;
const double _appleIconSize = 30;
const double _appleIconGap = 14;
const double _appleRowPadding = 16;
const double _appleSeparatorIndent =
    _appleRowPadding + _appleIconSize + _appleIconGap;

/// Fill of an iOS grouped cell (white / elevated dark).
Color _appleCellColor(BuildContext context) =>
    Theme.of(context).colorScheme.surface;

/// iOS section header, sentence case like iOS 26 (no more ALL CAPS).
class SettingsSectionHeader extends StatelessWidget {
  final String label;
  const SettingsSectionHeader(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_appleRowPadding, 26, 16, 8),
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

/// iOS section footer: small grey explanation under a group.
class SettingsSectionFooter extends StatelessWidget {
  final String text;
  const SettingsSectionFooter(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_appleRowPadding, 8, 16, 0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }
}

/// A rounded card that groups a list of widgets with auto-inserted dividers.
/// The divider indent aligns with the title column (16 + 40 + 12 = 68).
class SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const SettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.isApple) return _buildApple(context);
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            // Only insert a divider if this isn't the last child and the child
            // is not a SettingsTile with noDivider == true.
            if (i < children.length - 1 &&
                !(children[i] is SettingsTile && (children[i] as SettingsTile).noDivider))
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

  static bool _hidesDivider(Widget w) =>
      (w is SettingsTile && w.noDivider) ||
      (w is SettingsAppleMenuTile && w.noDivider);

  Widget _buildApple(BuildContext context) {
    final separator = CupertinoColors.separator.resolveFrom(context);
    const shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.all(Radius.circular(_appleGroupRadius)),
    );
    return ClipRSuperellipse(
      borderRadius: const BorderRadius.all(Radius.circular(_appleGroupRadius)),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: _appleCellColor(context),
          shape: shape,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1 &&
                  !_hidesDivider(children[i]))
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                      start: _appleSeparatorIndent),
                  child: Container(height: 0.5, color: separator),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A single settings row with a neutral icon badge, bold title,
/// optional subtitle, and an optional trailing widget.
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool noDivider;

  /// Apple only: colour of the icon square (iOS Settings style). Grey when
  /// null. Android keeps its neutral badge.
  final Color? appleIconColor;

  /// Apple only: red title, for actions such as "Delete account".
  final bool destructive;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.noDivider = false,
    this.appleIconColor,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.isApple) {
      return _AppleSettingsRow(
        icon: icon,
        iconColor: appleIconColor,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        enabled: enabled,
        destructive: destructive,
      );
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final fgColor = isDark ? const Color(0xFFEEEEF0) : const Color(0xFF3A3A3C);
    final cs = Theme.of(context).colorScheme;
    final disabledColor = cs.onSurface.withValues(alpha: 0.38);

    final effectiveFg = enabled ? fgColor : disabledColor;
    final effectiveBg = enabled ? bgColor : cs.onSurface.withValues(alpha: 0.12);

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
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

// ── Apple widgets ─────────────────────────────────────────────────────────────

/// iOS Settings icon: a coloured continuous square with a white glyph.
class SettingsAppleIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final bool enabled;

  const SettingsAppleIcon({
    super.key,
    required this.icon,
    this.color,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final fill = CupertinoDynamicColor.resolve(
        color ?? CupertinoColors.systemGrey, context);
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
          dimension: _appleIconSize,
          child: Icon(icon, color: CupertinoColors.white, size: 19),
        ),
      ),
    );
  }
}

/// One iOS grouped-list row: icon, 17 pt title (+ subtitle), trailing.
/// Highlights grey while pressed, like a UITableViewCell.
class _AppleSettingsRow extends StatefulWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool destructive;

  const _AppleSettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    required this.enabled,
    required this.destructive,
  });

  @override
  State<_AppleSettingsRow> createState() => _AppleSettingsRowState();
}

class _AppleSettingsRowState extends State<_AppleSettingsRow> {
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
            : const Color(0x00000000),
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(
            horizontal: _appleRowPadding, vertical: 10),
        child: Row(
          children: [
            SettingsAppleIcon(
              icon: widget.icon,
              color: widget.iconColor,
              enabled: widget.enabled,
            ),
            const SizedBox(width: _appleIconGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 17,
                      color: titleColor,
                    ),
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
class SettingsAppleDisclosure extends StatelessWidget {
  final String? value;
  const SettingsAppleDisclosure({super.key, this.value});

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.45),
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

/// iOS 26 "pop-up button" row: shows the current value with up/down
/// chevrons and opens a Liquid Glass menu morphing out of it. The whole row
/// is tappable; the selected option carries a check mark.
class SettingsAppleMenuTile<T> extends StatefulWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final List<({String label, T value})> options;
  final T? selected;
  final ValueChanged<T> onChanged;
  final bool enabled;
  final bool noDivider;
  final double menuWidth;

  const SettingsAppleMenuTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    this.noDivider = false,
    this.menuWidth = 250,
  });

  @override
  State<SettingsAppleMenuTile<T>> createState() =>
      _SettingsAppleMenuTileState<T>();
}

class _SettingsAppleMenuTileState<T> extends State<SettingsAppleMenuTile<T>> {
  final lg.GlassMenuController _menu = lg.GlassMenuController();

  @override
  Widget build(BuildContext context) {
    final current = widget.options
        .where((o) => o.value == widget.selected)
        .map((o) => o.label)
        .firstOrNull;
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);

    final trigger = ConstrainedBox(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.34),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                current ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 17, color: secondary),
              ),
            ),
            const SizedBox(width: 4),
            Icon(CupertinoIcons.chevron_up_chevron_down,
                size: 14, color: secondary),
          ],
        ),
      ),
    );

    return SettingsTile(
      icon: widget.icon,
      appleIconColor: widget.iconColor,
      title: widget.title,
      subtitle: widget.subtitle,
      enabled: widget.enabled,
      noDivider: widget.noDivider,
      onTap: widget.enabled ? _menu.open : null,
      trailing: !widget.enabled
          ? trigger
          : lg.GlassMenu(
              controller: _menu,
              trigger: trigger,
              // Wider for long labels (e.g. path display order).
              menuWidth: widget.options.any((o) => o.label.length > 24)
                  ? MediaQuery.sizeOf(context).width - 48
                  : widget.menuWidth,
              menuAlignment: lg.GlassMenuAlignment.topRight,
              autoAdjustToScreen: true,
              menuPadding: const EdgeInsets.all(12),
              menuSemanticLabel: widget.title,
              items: [
                for (final o in widget.options)
                  lg.GlassMenuItem(
                    title: o.label,
                    // The menu sizes each item from maxLines, so only long
                    // labels get a second line (else an empty band shows
                    // under the last item).
                    maxLines: o.label.length > 30 ? 2 : 1,
                    titleStyle: TextStyle(fontSize: 17, color: label),
                    // Same slot width with or without the check, so the
                    // labels line up.
                    icon: SizedBox(
                      width: 20,
                      child: o.value == widget.selected
                          ? const Icon(CupertinoIcons.checkmark, size: 17)
                          : null,
                    ),
                    iconSize: 17,
                    semanticsChecked: o.value == widget.selected,
                    onTap: () => widget.onChanged(o.value),
                  ),
              ],
            ),
    );
  }
}
