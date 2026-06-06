import 'package:flutter/material.dart';

class AppStepsTab {
  final String label;

  /// Optional step/item count rendered as a trailing badge. When null the chip
  /// shows the label only — used for plain text-only segmented tabs.
  final int? count;

  const AppStepsTab({required this.label, this.count});
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

  const AppStepsTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  State<AppStepsTabBar> createState() => _AppStepsTabBarState();
}

class _AppStepsTabBarState extends State<AppStepsTabBar> {
  static const _trackPadding = 4.0;

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final trackColor = isDark
        ? cs.surfaceContainerHighest
        : const Color(0xFFEEEEF2);

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(_trackPadding),
        child: Stack(
          // Row (non-positioned) determines Stack size; indicator overlaps it.
          clipBehavior: Clip.none,
          children: [
            // ── Sliding white indicator card (behind chips) ──────────────
            if (_widths.isNotEmpty)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: _indicatorLeft,
                top: 0,
                bottom: 0,
                width: _indicatorWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? cs.surface : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.25 : 0.10),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Tab chips (on top of indicator) ─────────────────────────
            Row(
              children: [
                for (int i = 0; i < widget.tabs.length; i++)
                  _AppStepsTabChip(
                    key: _keys[i],
                    label: widget.tabs[i].label,
                    count: widget.tabs[i].count,
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
  final bool isSelected;
  final VoidCallback onTap;

  const _AppStepsTabChip({
    super.key,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Keep the same layout/sizing for selected and unselected so that
    // _widths stays stable and the indicator slides correctly.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected
                    ? cs.onSurface
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
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected
                        ? cs.onPrimary
                        : cs.onSurface.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
