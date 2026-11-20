import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme, ThemeData, Brightness;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;
import 'package:trainlog_app/app/theme/app_colors.dart';
import 'package:trainlog_app/platform/liquid_glass.dart';

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
            size: 40,
            iconSize: 17,
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
                  letterSpacing: -0.4,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ),
          ),
          GlassIconButton(
            icon: CupertinoIcons.arrow_counterclockwise,
            size: 40,
            iconSize: 18,
            shadow: false,
            tooltip: resetTooltip,
            onPressed: onReset,
          ),
        ],
      ),
    );
  }
}

/// The sheet's main action: a full-width capsule of glass tinted with the
/// Trainlog amber (iOS 26 "prominent" glass), with a leading icon.
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
    const fg = AppColors.navy;
    return LayoutBuilder(
      builder: (context, constraints) => lg.GlassButton.custom(
        onTap: onPressed ?? () {},
        enabled: onPressed != null,
        label: label,
        width: constraints.maxWidth,
        height: height,
        useOwnLayer: true,
        quality: lg.GlassQuality.premium,
        shape: const lg.LiquidRoundedSuperellipse(borderRadius: height / 2),
        settings: lg.LiquidGlassSettings(
          glassColor: AppColors.amber.withValues(alpha: 0.9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
                  letterSpacing: -0.4,
                  color: fg,
                ),
              ),
            ),
          ],
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
                letterSpacing: -0.2,
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

    Widget content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[
          Icon(leading, size: 15, color: iconColor),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: TextStyle(
              fontSize: 15,
              letterSpacing: -0.2,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: fg,
            ),
          ),
        ),
      ],
    );
    if (expand) {
      content = FittedBox(fit: BoxFit.scaleDown, child: content);
    }

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
          padding: const EdgeInsets.symmetric(horizontal: 13),
          alignment: Alignment.center,
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
