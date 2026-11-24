import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassSegment, GlassSegmentedControl;
import 'package:trainlog_app/ui/tokens/app_colors.dart';
import 'package:trainlog_app/ui/tokens/app_tab_theme.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

class AppStepsTab {
  final String label;

  /// Optional step/item count rendered as a trailing badge. When null the chip
  /// shows the label only — used for plain text-only segmented tabs.
  final int? count;

  /// Optional icon rendered before the label.
  final Widget? leadingIcon;

  /// When true, only [leadingIcon] is rendered (the label is hidden but still
  /// used as the accessibility tooltip). Requires [leadingIcon] to be set.
  final bool iconOnly;

  const AppStepsTab({
    required this.label,
    this.count,
    this.leadingIcon,
    this.iconOnly = false,
  }) : assert(!iconOnly || leadingIcon != null,
            'iconOnly requires a leadingIcon');
}

/// Segmented-control-style horizontally-scrollable tab bar with a smooth
/// sliding indicator animation when the selected tab changes.
///
/// A grey rounded track contains all chips. The selected tab's position is
/// highlighted by a white elevated card that slides from chip to chip via
/// [AnimatedPositioned]. Unselected tabs show muted label + count text with
/// no background — the sliding card provides the visual emphasis.
class AppStepsTabBar extends StatefulWidget {
  final List<AppStepsTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  /// When true, chips divide the full container width equally instead of
  /// sizing to their content. Use this for a fixed two-tab selector.
  final bool fullWidth;

  const AppStepsTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
    this.fullWidth = false,
  });

  @override
  State<AppStepsTabBar> createState() => _AppStepsTabBarState();
}

class _AppStepsTabBarState extends State<AppStepsTabBar> {
  static const _trackPadding = 4.0;

  /// Height of the Material track. Apple uses liquid_glass_widgets'
  /// segmented control instead (see [_buildGlass]).
  static const double _height = 46;
  static const _slideDuration = Duration(milliseconds: 250);
  static const Curve _slideCurve = Curves.easeInOut;

  final List<GlobalKey> _keys = [];
  List<double> _widths = [];

  @override
  void initState() {
    super.initState();
    _initKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureWidths());
  }

  @override
  void didUpdateWidget(AppStepsTabBar old) {
    super.didUpdateWidget(old);
    final labelsChanged = old.tabs.length != widget.tabs.length ||
        Iterable.generate(widget.tabs.length)
            .any((i) => old.tabs[i].label != widget.tabs[i].label);
    if (old.tabs.length != widget.tabs.length) {
      _initKeys();
    }
    if (labelsChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureWidths());
    }
  }

  void _initKeys() {
    _keys.clear();
    for (int i = 0; i < widget.tabs.length; i++) {
      _keys.add(GlobalKey());
    }
    _widths = [];
  }

  void _measureWidths() {
    if (!mounted) return;
    final widths = <double>[];
    for (final key in _keys) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      widths.add(box?.size.width ?? 0);
    }
    if (widths.any((w) => w > 0)) {
      setState(() => _widths = widths);
    }
  }

  /// Left offset of the indicator relative to the Stack's origin (= content
  /// origin inside the track padding).
  double get _indicatorLeft {
    if (_widths.isEmpty) return 0;
    double left = 0;
    for (int i = 0; i < widget.selectedIndex && i < _widths.length; i++) {
      left += _widths[i];
    }
    return left;
  }

  double get _indicatorWidth {
    if (_widths.isEmpty || widget.selectedIndex >= _widths.length) return 0;
    return _widths[widget.selectedIndex];
  }

  Widget _buildIndicator(bool isDark, ColorScheme cs) {
    final tabColors = Theme.of(context).extension<AppTabColors>()!;
    if (_widths.isEmpty) return const SizedBox.shrink();
    return AnimatedPositioned(
      duration: _slideDuration,
      curve: _slideCurve,
      left: _indicatorLeft,
      top: 0,
      bottom: 0,
      width: _indicatorWidth,
      child: Container(
        decoration: BoxDecoration(
          color: tabColors.selectedBackground,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.10),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }

  /// Track behind the chips: a rounded grey well.
  BoxDecoration _trackDecoration(AppTabColors tabColors) => BoxDecoration(
        color: tabColors.tabBackground,
        borderRadius: BorderRadius.circular(14),
      );

  /// Apple: liquid_glass_widgets' iOS 26 segmented control, whose glass
  /// lens follows the finger and refracts the labels under it.
  Widget _buildGlass(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.amber : AppColors.amberDk;
    final segments = [
      for (final t in widget.tabs)
        GlassSegment(
          // iOS guideline: a segment shows an icon OR text, never both. A
          // labelled tab drops its icon here (Android keeps it).
          icon: t.iconOnly ? t.leadingIcon : null,
          label: t.iconOnly
              ? null
              : (t.count == null ? t.label : '${t.label}  ${t.count}'),
          tooltip: t.iconOnly ? t.label : null,
          semanticLabel: t.label,
        ),
    ];

    if (widget.fullWidth) {
      return GlassSegmentedControl(
        segments: segments,
        selectedIndex: widget.selectedIndex,
        onSegmentSelected: widget.onTabChanged,
        height: _height,
        iconSize: 18,
        selectedIconColor: accent,
      );
    }
    return GlassSegmentedControl.scrollable(
      segments: segments,
      selectedIndex: widget.selectedIndex,
      onSegmentSelected: widget.onTabChanged,
      height: _height,
      iconSize: 16,
      selectedIconColor: accent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final tabColors = Theme.of(context).extension<AppTabColors>()!;

    if (AppPlatform.isApple) return _buildGlass(context);

    if (widget.fullWidth) {
      return Container(
        height: _height,
        decoration: _trackDecoration(tabColors),
        child: Padding(
          padding: EdgeInsets.all(_trackPadding),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final chipWidth = constraints.maxWidth / widget.tabs.length;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Indicator derived purely from layout — always correct on resize.
                  AnimatedPositioned(
                    duration: _slideDuration,
                    curve: _slideCurve,
                    left: widget.selectedIndex * chipWidth,
                    top: 0,
                    bottom: 0,
                    width: chipWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: tabColors.selectedBackground,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.10),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      for (int i = 0; i < widget.tabs.length; i++)
                        Expanded(
                          child: _AppStepsTabChip(
                            label: widget.tabs[i].label,
                            count: widget.tabs[i].count,
                            leadingIcon: widget.tabs[i].leadingIcon,
                            iconOnly: widget.tabs[i].iconOnly,
                            isSelected: i == widget.selectedIndex,
                            onTap: () => widget.onTabChanged(i),
                            centerContent: true,
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    return Container(
      height: _height,
      decoration: _trackDecoration(tabColors),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.all(_trackPadding),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildIndicator(isDark, cs),
            Row(
              children: [
                for (int i = 0; i < widget.tabs.length; i++)
                  _AppStepsTabChip(
                    key: _keys[i],
                    label: widget.tabs[i].label,
                    count: widget.tabs[i].count,
                    leadingIcon: widget.tabs[i].leadingIcon,
                    iconOnly: widget.tabs[i].iconOnly,
                    isSelected: i == widget.selectedIndex,
                    onTap: () => widget.onTabChanged(i),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppStepsTabChip extends StatelessWidget {
  final String label;
  final int? count;
  final Widget? leadingIcon;
  final bool iconOnly;
  final bool isSelected;
  final VoidCallback onTap;
  /// When true the chip content is centered both horizontally and vertically
  /// (used in fullWidth mode where the chip fills an Expanded cell).
  final bool centerContent;

  const _AppStepsTabChip({
    super.key,
    required this.label,
    required this.count,
    this.leadingIcon,
    this.iconOnly = false,
    required this.isSelected,
    required this.onTap,
    this.centerContent = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tabColors = Theme.of(context).extension<AppTabColors>()!;

    // Icon-only chip: render just the icon (label used as tooltip).
    if (iconOnly && leadingIcon != null) {
      final iconContent = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isSelected ? 1.0 : 0.5,
          child: IconTheme(
            data: IconThemeData(
              color: isSelected ? tabColors.onSelected : cs.onSurface,
              size: 18,
            ),
            child: leadingIcon!,
          ),
        ),
      );
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Tooltip(
          message: label,
          child: centerContent ? Center(child: iconContent) : iconContent,
        ),
      );
    }

    // Keep the same layout/sizing for selected and unselected so that
    // _widths stays stable and the indicator slides correctly.
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
            if (leadingIcon != null) ...[
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.5,
                child: IconTheme(
                  data: IconThemeData(color: cs.onSurface, size: 16),
                  child: leadingIcon!,
                ),
              ),
              const SizedBox(width: 6),
            ],
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected
                    ? tabColors.onSelected
                    : cs.onSurface.withValues(alpha: 0.50),
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label),
            ),
            // Badge — only rendered when a count is supplied. Text-only tabs
            // (count == null) omit both the gap and the badge entirely.
            if (count != null) ...[
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? tabColors.selectedBackground
                      : tabColors.tabBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected
                        ? tabColors.onSelected
                        : cs.onSurface.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: centerContent ? Center(child: content) : content,
    );
  }
}
