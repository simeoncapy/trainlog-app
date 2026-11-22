import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme, ThemeData, Brightness;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;
import 'package:trainlog_app/ui/tokens/app_colors.dart';
import 'package:trainlog_app/ui/cupertino/liquid_glass.dart';

// Apple-only building blocks of the iOS 26 filter sheets (map filter, trips
// search & filter). Android keeps its own Material widgets.

/// iOS 26 sheet bar: a glass close button (✕) on the leading side, the title
/// centred, a glass reset button (↺, `arrow.counterclockwise`) on the
/// trailing side.
class GlassSheetHeader extends StatelessWidget {
  const GlassSheetHeader({
    super.key,
    required this.title,
    required this.onClose,
    required this.onReset,
    required this.closeTooltip,
    required this.resetTooltip,
  });

  final String title;
  final VoidCallback onClose;
  final VoidCallback? onReset;
  final String closeTooltip;
  final String resetTooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
      child: Row(
        children: [
          GlassIconButton(
            icon: CupertinoIcons.xmark,
            shadow: false,
            tooltip: closeTooltip,
            onPressed: onClose,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ),
          ),
          GlassIconButton(
            icon: CupertinoIcons.arrow_counterclockwise,
            shadow: false,
            tooltip: resetTooltip,
            onPressed: onReset,
          ),
        ],
      ),
    );
  }
}

/// The sheet's main action: a full-width amber capsule with a leading icon
/// and the liquid press response.
class GlassPrimaryButton extends StatelessWidget {
  const GlassPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  static const double height = 50;

  @override
  Widget build(BuildContext context) {
    // A solid amber capsule: the tinted glass of the package rendered too
    // yellow in light mode and red-orange in dark, with poor contrast.
    const fg = AppColors.navy;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GlassPressable(
        onPressed: onPressed,
        pressedScale: 1.03,
        child: Container(
            height: height,
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: ShapeDecoration(
              color: AppColors.amber,
              shape: const StadiumBorder(),
              shadows: [
                BoxShadow(
                  color: AppColors.amber.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 19, color: fg),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}

/// Section label of a filter sheet with an optional trailing text action
/// (e.g. "Select All").
class GlassFilterSectionHeader extends StatelessWidget {
  const GlassFilterSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
          if (actionLabel != null)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              minimumSize: const Size(0, 30),
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: TextStyle(
                  fontSize: 15,
                  color: CupertinoTheme.of(context).primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One iOS filter capsule: fully rounded, no border, grey when off and filled
/// when on (as in Maps, Photos or the App Store).
///
/// [selectedColor] fills it when selected (its text turns white or navy for
/// contrast). [leadingColor] tints the leading icon while unselected, so a
/// vehicle keeps its map colour. [outlined] draws a thin solid outline when
/// unselected (used for future years). [expand] centres the content and lets
/// the capsule fill its cell (aligned grids).
class FilterCapsule extends StatelessWidget {
  const FilterCapsule({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.leadingColor,
    this.selectedColor,
    this.outlined = false,
    this.expand = false,
    this.semanticLabel,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? leading;
  final Color? leadingColor;
  final Color? selectedColor;
  final bool outlined;
  final bool expand;
  final String? semanticLabel;

  static const double height = 34;

  @override
  Widget build(BuildContext context) {
    final fill = selectedColor ?? AppColors.amber;
    final onFill = ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
        ? CupertinoColors.white
        : AppColors.navy;
    final label_ = CupertinoColors.label.resolveFrom(context);
    final bg = selected
        ? fill
        : CupertinoColors.tertiarySystemFill.resolveFrom(context);
    final fg = selected ? onFill : label_;
    final iconColor = selected ? onFill : (leadingColor ?? label_);

    final text = Text(
      label,
      maxLines: 1,
      softWrap: false,
      style: TextStyle(
        fontSize: 15,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        color: fg,
      ),
    );
    final icon = leading == null
        ? null
        : [Icon(leading, size: 15, color: iconColor), const SizedBox(width: 5)];

    // Expanded (grid cell): natural-size row scaled down to fit the cell.
    // Otherwise (Wrap): the capsule hugs its content.
    final Widget content = expand
        ? FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [...?icon, text],
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [...?icon, Flexible(child: text)],
          );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: height,
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: expand ? 6 : 13),
          alignment: expand ? Alignment.center : null,
          decoration: ShapeDecoration(
            color: bg,
            shape: StadiumBorder(
              side: outlined && !selected
                  ? BorderSide(
                      color: isDark
                          ? const Color(0x55FFFFFF)
                          : const Color(0x403C3C43),
                    )
                  : BorderSide.none,
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// iOS page dots (UIPageControl without the capsule), tappable.
class FilterPageDots extends StatelessWidget {
  const FilterPageDots({
    super.key,
    required this.count,
    required this.current,
    required this.onSelect,
  });

  final int count;
  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final on = CupertinoColors.label.resolveFrom(context).withValues(alpha: 0.75);
    final off = CupertinoColors.label.resolveFrom(context).withValues(alpha: 0.22);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelect(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == current ? on : off,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Grouped form (trips search & filter) ─────────────────────────────────────

/// iOS inset grouped section without icons: rounded card, hairline
/// separators starting under the text.
class GlassFormGroup extends StatelessWidget {
  const GlassFormGroup({super.key, required this.children});

  final List<Widget> children;

  static const double radius = 26;

  @override
  Widget build(BuildContext context) {
    final separator = CupertinoColors.separator.resolveFrom(context);
    return ClipRSuperellipse(
      borderRadius: const BorderRadius.all(Radius.circular(radius)),
      child: ColoredBox(
        // Cells take the app surface over the sheet's page colour, like the
        // iOS Settings page (white on beige / navy on dark navy).
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16),
                  child: Container(height: 0.5, color: separator),
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// One row of a [GlassFormGroup]: 17 pt title, trailing widget, grey
/// highlight while pressed when [onTap] is set.
class GlassFormRow extends StatefulWidget {
  const GlassFormRow({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  State<GlassFormRow> createState() => _GlassFormRowState();
}

class _GlassFormRowState extends State<GlassFormRow> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final tappable = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: tappable ? (_) => _set(true) : null,
      onTapUp: tappable ? (_) => _set(false) : null,
      onTapCancel: tappable ? () => _set(false) : null,
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: _pressed ? 0 : 250),
        color: _pressed
            ? CupertinoColors.systemGrey4.resolveFrom(context)
            : const Color(0x00000000),
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            if (widget.leading != null) ...[
              widget.leading!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 17,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ),
            if (widget.trailing != null) ...[
              const SizedBox(width: 8),
              widget.trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Trailing of a row that opens another view: grey value, then a chevron.
class GlassDisclosure extends StatelessWidget {
  const GlassDisclosure({super.key, this.value});

  final String? value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.55),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Flexible(
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
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

/// One choice of a [GlassFormMenuRow]. [dividerBefore] separates it from the
/// choices above (e.g. "Custom…").
class GlassMenuChoice<T> {
  const GlassMenuChoice({
    required this.value,
    required this.label,
    this.menuLabel,
    this.menuIcon,
    this.dividerBefore = false,
  });

  /// Optional icon on the trailing side of the menu item (iOS style).
  final IconData? menuIcon;

  final T value;

  /// Shown as the row's value.
  final String label;

  /// Shown in the menu when it differs (e.g. "Custom…" vs "Custom").
  final String? menuLabel;
  final bool dividerBefore;
}

/// iOS 26 pop-up button row: the current value with up/down chevrons opens
/// a Liquid Glass menu morphing out of it; the selected choice is checked.
class GlassFormMenuRow<T> extends StatefulWidget {
  const GlassFormMenuRow({
    super.key,
    required this.title,
    required this.choices,
    required this.selected,
    required this.onChanged,
    this.menuWidth = 250,
  });

  final String title;
  final List<GlassMenuChoice<T>> choices;
  final T selected;
  final ValueChanged<T> onChanged;
  final double menuWidth;

  @override
  State<GlassFormMenuRow<T>> createState() => _GlassFormMenuRowState<T>();
}

class _GlassFormMenuRowState<T> extends State<GlassFormMenuRow<T>> {
  final lg.GlassMenuController _menu = lg.GlassMenuController();

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    final current = widget.choices
        .where((c) => c.value == widget.selected)
        .map((c) => c.label)
        .firstOrNull;

    final trigger = ConstrainedBox(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.55),
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
                style: TextStyle(
                    fontSize: 17, color: secondary),
              ),
            ),
            const SizedBox(width: 4),
            Icon(CupertinoIcons.chevron_up_chevron_down,
                size: 14, color: secondary),
          ],
        ),
      ),
    );

    return GlassFormRow(
      title: widget.title,
      onTap: _menu.open,
      trailing: lg.GlassMenu(
        controller: _menu,
        trigger: trigger,
        menuWidth: widget.menuWidth,
        menuAlignment: lg.GlassMenuAlignment.topRight,
        autoAdjustToScreen: true,
        menuPadding: const EdgeInsets.all(12),
        menuSemanticLabel: widget.title,
        items: [
          for (final c in widget.choices) ...[
            if (c.dividerBefore) const lg.GlassMenuDivider(),
            lg.GlassMenuItem(
              title: c.menuLabel ?? c.label,
              maxLines: 1,
              titleStyle: TextStyle(fontSize: 17, color: label),
              icon: SizedBox(
                width: 20,
                child: c.value == widget.selected
                    ? const Icon(CupertinoIcons.checkmark, size: 17)
                    : null,
              ),
              iconSize: 17,
              trailing: c.menuIcon == null
                  ? null
                  : Icon(c.menuIcon, size: 18, color: label),
              semanticsChecked: c.value == widget.selected,
              onTap: () => widget.onChanged(c.value),
            ),
          ],
        ],
      ),
    );
  }
}

/// iOS compact date button (as in Calendar): grey rounded rectangle holding
/// the date, tinted when set. [onClear] adds a small clear button after it.
class GlassDateButton extends StatelessWidget {
  const GlassDateButton({
    super.key,
    required this.text,
    required this.isSet,
    required this.onTap,
    this.onClear,
  });

  final String text;
  final bool isSet;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final tint = CupertinoTheme.of(context).primaryColor;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: ShapeDecoration(
              color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
              shape: const RoundedSuperellipseBorder(
                borderRadius: BorderRadius.all(Radius.circular(9)),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 17,
                color: isSet
                    ? tint
                    : CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
        ),
        if (onClear != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClear,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                CupertinoIcons.xmark_circle_fill,
                size: 20,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ),
          ),
      ],
    );
  }
}
