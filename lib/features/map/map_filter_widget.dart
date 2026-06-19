import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_bottom_navbar.dart' show kNavBarClearance;
import 'package:trainlog_app/platform/adaptive_vehicle_type_filter_chips.dart';
import 'package:trainlog_app/providers/polyline_provider.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/widgets/app_steps_tab_bar.dart';

/// Map filter sheet.
///
/// A single, theme-driven implementation shared across platforms — platform
/// differences are delegated to adaptive sub-components (the vehicle chips) and
/// to the bottom anchoring offset. The sheet pins a fixed action footer
/// ("Show {count} trips") to its base while the form contents live inside a
/// [Flexible] scroll area so they never overflow on short screens.
///
/// Renders as a [Positioned] widget inside the map [Stack].
class MapFilterWidget extends StatefulWidget {
  final VoidCallback onClose;

  const MapFilterWidget({super.key, required this.onClose});

  @override
  State<MapFilterWidget> createState() => _MapFilterWidgetState();
}

class _MapFilterWidgetState extends State<MapFilterWidget> {
  /// 4 columns × 3 rows.
  static const int _yearsPerPage = 12;

  /// Current page of the paginated year grid.
  int _yearPage = 0;

  /// Top-index used by [PolylineProvider.updateYearFilter] for the explicit
  /// per-year ("Years") mode.
  static const int _yearsOptionIndex = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final poly = context.watch<PolylineProvider>();
    final mediaQuery = MediaQuery.of(context);

    final maxHeight =
        (mediaQuery.size.height - mediaQuery.padding.top - mediaQuery.padding.bottom) * 0.82;

    // The map page lives inside a Padding(bottom: mq.padding.bottom). On Apple
    // the primary-action FAB / nav bar sits at kNavBarClearance from the screen
    // bottom; on Material the sheet floats just above the safe-area inset.
    final double bottom = AppPlatform.isApple
        ? kNavBarClearance - mediaQuery.padding.bottom + 8
        : 16 + mediaQuery.padding.bottom;

    return Positioned(
      bottom: bottom,
      left: 16,
      right: 16,
      child: Material(
        color: theme.cardColor,
        elevation: 8,
        shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _grabHandle(theme),
              _header(context, l10n, theme),
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(theme, l10n.mapFilterTimeRange),
                      const SizedBox(height: 10),
                      _timeRangeSelector(context, l10n, poly),
                      if (poly.selectedYearFilterOption == _yearsOptionIndex) ...[
                        const SizedBox(height: 16),
                        _yearSection(context, l10n, theme, poly),
                      ],
                      const SizedBox(height: 20),
                      _sectionTitle(
                        theme,
                        l10n.typeTitle,
                        trailing: _allNoneButtons(
                          context,
                          theme,
                          l10n,
                          onAll: () => context
                              .read<PolylineProvider>()
                              .selectAllVehicleTypes(poly.availableTypesWithoutPoi),
                          onNone: () => context
                              .read<PolylineProvider>()
                              .unselectAllVehicleTypes(poly.availableTypesWithoutPoi),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AdaptiveVehicleTypeFilterChips(
                        availableTypes: poly.availableTypesWithoutPoi,
                        selectedTypes: poly.selectedTypes,
                        onTypeToggle: (type, selected) {
                          context.read<PolylineProvider>().toggleType(type, selected);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              _actionFooter(l10n, theme, poly),
            ],
          ),
        ),
      ),
    );
  }

  // ── Chrome ─────────────────────────────────────────────────────────────────

  Widget _grabHandle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.outline,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.filter_alt_rounded, size: 20, color: cs.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.mapFilterTitle,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () => context.read<PolylineProvider>().resetFilters(),
            style: TextButton.styleFrom(
              foregroundColor: cs.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l10n.mapFilterReset),
          ),
          const SizedBox(width: 4),
          _CircleIconButton(
            icon: Icons.close,
            onTap: widget.onClose,
            background: cs.onSurface.withValues(alpha: 0.08),
            foreground: cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _actionFooter(
    AppLocalizations l10n,
    ThemeData theme,
    PolylineProvider poly,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: widget.onClose,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          icon: const Icon(Icons.map_outlined, size: 20),
          label: Text(l10n.mapFilterShowTrips(poly.visibleTripCount)),
        ),
      ),
    );
  }

  // ── Time range ───────────────────────────────────────────────────────────

  Widget _timeRangeSelector(
    BuildContext context,
    AppLocalizations l10n,
    PolylineProvider poly,
  ) {
    return AppStepsTabBar(
      fullWidth: true,
      selectedIndex: poly.selectedYearFilterOption,
      tabs: [
        AppStepsTab(label: l10n.yearAllList),
        AppStepsTab(label: l10n.yearPastList),
        AppStepsTab(label: l10n.yearFutureList),
        AppStepsTab(label: l10n.yearTitle),
      ],
      onTabChanged: (index) {
        final years = poly.availableYears;
        context.read<PolylineProvider>().updateYearFilter(
              topIndex: index,
              years: years,
              subSelection: index == _yearsOptionIndex
                  ? years.map((y) => poly.selectedYears.contains(y)).toList()
                  : const [],
            );
        if (index == _yearsOptionIndex) {
          setState(() => _yearPage = 0);
        }
      },
    );
  }

  // ── Year grid ──────────────────────────────────────────────────────────────

  Widget _yearSection(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    PolylineProvider poly,
  ) {
    final years = poly.availableYears; // already sorted descending
    final pageCount = math.max(1, (years.length / _yearsPerPage).ceil());
    final page = _yearPage.clamp(0, pageCount - 1);
    final start = page * _yearsPerPage;
    final end = math.min(start + _yearsPerPage, years.length);
    final pageYears = years.sublist(start, end);

    final grid = _yearGrid(context, poly, pageYears);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          theme,
          l10n.mapFilterSelectYears,
          dense: true,
          trailing: _allNoneButtons(
            context,
            theme,
            l10n,
            onAll: () => context.read<PolylineProvider>().selectAllYears(years),
            onNone: () => context.read<PolylineProvider>().unselectAllYears(),
          ),
        ),
        const SizedBox(height: 10),
        if (pageCount > 1)
          Row(
            children: [
              _PagerButton(
                icon: Icons.chevron_left,
                enabled: page > 0,
                onTap: () => setState(() => _yearPage = page - 1),
              ),
              const SizedBox(width: 4),
              Expanded(child: grid),
              const SizedBox(width: 4),
              _PagerButton(
                icon: Icons.chevron_right,
                enabled: page < pageCount - 1,
                onTap: () => setState(() => _yearPage = page + 1),
              ),
            ],
          )
        else
          grid,
      ],
    );
  }

  Widget _yearGrid(BuildContext context, PolylineProvider poly, List<int> years) {
    final currentYear = DateTime.now().year;
    final rows = <Widget>[];
    for (int rowStart = 0; rowStart < years.length; rowStart += 4) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
      final cells = <Widget>[];
      for (int col = 0; col < 4; col++) {
        if (col > 0) cells.add(const SizedBox(width: 8));
        final idx = rowStart + col;
        if (idx >= years.length) {
          cells.add(const Expanded(child: SizedBox.shrink()));
          continue;
        }
        final year = years[idx];
        cells.add(
          Expanded(
            child: _YearChip(
              year: year,
              selected: poly.selectedYears.contains(year),
              isFuture: year > currentYear,
              onTap: () {
                final allYears = poly.availableYears;
                final newSub = allYears
                    .map((y) =>
                        y == year ? !poly.selectedYears.contains(y) : poly.selectedYears.contains(y))
                    .toList();
                context.read<PolylineProvider>().updateYearFilter(
                      topIndex: _yearsOptionIndex,
                      years: allYears,
                      subSelection: newSub,
                    );
              },
            ),
          ),
        );
      }
      rows.add(Row(children: cells));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  // ── Shared bits ──────────────────────────────────────────────────────────

  Widget _sectionTitle(
    ThemeData theme,
    String text, {
    Widget? trailing,
    bool dense = false,
  }) {
    final style = (dense ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)
        ?.copyWith(fontWeight: FontWeight.w700);
    return Row(
      children: [
        Expanded(child: Text(text, style: style)),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _allNoneButtons(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n, {
    required VoidCallback onAll,
    required VoidCallback onNone,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _miniButton(theme, l10n.mapFilterYearsAllBtn, onAll, emphasized: true),
        const SizedBox(width: 4),
        _miniButton(theme, l10n.mapFilterYearsNoneBtn, onNone),
      ],
    );
  }

  Widget _miniButton(
    ThemeData theme,
    String text,
    VoidCallback onTap, {
    bool emphasized = false,
  }) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor:
            emphasized ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      child: Text(text),
    );
  }
}

// ─── Year chip ────────────────────────────────────────────────────────────────

/// A single year cell. Past/current years get a solid border; future years a
/// dashed border to distinguish planned excursions from completed trips.
class _YearChip extends StatelessWidget {
  final int year;
  final bool selected;
  final bool isFuture;
  final VoidCallback onTap;

  const _YearChip({
    required this.year,
    required this.selected,
    required this.isFuture,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const radius = 10.0;

    final bg = selected ? cs.primary : Colors.transparent;
    final fg = selected ? cs.onPrimary : cs.onSurface;
    final borderColor = selected ? cs.primary : cs.outline;

    Widget content = Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        // Future years draw their (dashed) border via the painter below.
        border: isFuture ? null : Border.all(color: borderColor, width: 1.2),
      ),
      child: Text(
        year.toString(),
        style: TextStyle(color: fg, fontWeight: FontWeight.w600),
      ),
    );

    if (isFuture) {
      content = CustomPaint(
        foregroundPainter: _DashedBorderPainter(
          color: selected ? cs.onPrimary : cs.outline,
          radius: radius,
          strokeWidth: 1.4,
        ),
        child: content,
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}

/// Paints a dashed rounded-rectangle border, used to mark future years.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  _DashedBorderPainter({
    required this.color,
    required this.radius,
    this.strokeWidth = 1.4,
    this.dashLength = 5,
    this.gapLength = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final inset = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, math.min(next, metric.length)),
          paint,
        );
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength;
}

// ─── Small buttons ──────────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 18, color: foreground),
        ),
      ),
    );
  }
}

/// Chevron pager button for the year grid. Greys out at the page bounds.
class _PagerButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PagerButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 32,
      child: IconButton(
        onPressed: enabled ? onTap : null,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        iconSize: 24,
        color: cs.onSurface,
        disabledColor: cs.outline,
        icon: Icon(icon),
      ),
    );
  }
}
