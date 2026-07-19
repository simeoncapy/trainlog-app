import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_vehicle_type_filter_chips.dart';
import 'package:trainlog_app/providers/polyline_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/widgets/app_steps_tab_bar.dart';
import 'package:trainlog_app/widgets/primary_action_button.dart';

/// Map filter bottom sheet.
///
/// A single, theme-driven implementation shared across platforms — platform
/// differences are delegated to adaptive sub-components (the vehicle chips).
/// The sheet pins a fixed action footer ("Show {count} trips") to its base
/// while the form contents live inside a [Flexible] scroll area so they never
/// overflow on short screens.
///
/// Designed to be hosted by `showModalBottomSheet`; [onClose] should dismiss
/// the sheet (e.g. `Navigator.pop`).
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
        (mediaQuery.size.height - mediaQuery.padding.top) * 0.9;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
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
                        theme,
                        allLabel: l10n.mapFilterVehicleTypeAllBtn,
                        noneLabel: l10n.mapFilterVehicleTypeNoneBtn,
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
            _actionFooter(l10n, poly),
          ],
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
          // _CircleIconButton(
          //   icon: Icons.close,
          //   onTap: widget.onClose,
          //   background: cs.onSurface.withValues(alpha: 0.08),
          //   foreground: cs.onSurfaceVariant,
          // ),
        ],
      ),
    );
  }

  Widget _actionFooter(
    AppLocalizations l10n,
    PolylineProvider poly,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: PrimaryActionButton(
        onPressed: widget.onClose,
        icon: Icons.map_outlined,
        label: l10n.mapFilterShowTrips(poly.visibleTripCount),
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

    // The grid lays out a single ordered list of "slots": the unknown-future
    // button first (rendered in the future/dashed style), then the real years
    // (descending), then the unknown-past button last. The unknown buttons only
    // appear when the user actually has such trips.
    final items = <int>[
      if (poly.hasUnknownFuture) unknownFuture.year,
      ...years,
      if (poly.hasUnknownPast) unknownPast.year,
    ];

    final pageCount = math.max(1, (items.length / _yearsPerPage).ceil());
    final page = _yearPage.clamp(0, pageCount - 1);
    final start = page * _yearsPerPage;
    final end = math.min(start + _yearsPerPage, items.length);
    final pageItems = items.sublist(start, end);

    // When paginated, every page reserves the full 4×3 footprint so the sheet
    // height stays constant when flipping to a shorter last page.
    final grid = _yearGrid(context, l10n, poly, pageItems, fill: pageCount > 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          theme,
          l10n.mapFilterSelectYears,
          dense: true,
          trailing: _allNoneButtons(
            theme,
            allLabel: l10n.mapFilterYearsAllBtn,
            noneLabel: l10n.mapFilterYearsNoneBtn,
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

  Widget _yearGrid(
    BuildContext context,
    AppLocalizations l10n,
    PolylineProvider poly,
    List<int> items, {
    required bool fill,
  }) {
    final currentYear = DateTime.now().year;
    // When [fill] is set, always lay out a full 4×3 grid (12 slots); otherwise
    // size to the available items only.
    final slotCount = fill ? _yearsPerPage : items.length;
    final rows = <Widget>[];
    for (int rowStart = 0; rowStart < slotCount; rowStart += 4) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
      final cells = <Widget>[];
      for (int col = 0; col < 4; col++) {
        if (col > 0) cells.add(const SizedBox(width: 8));
        final idx = rowStart + col;
        if (idx >= items.length) {
          // Empty placeholder keeps the 4×3 footprint (and row height) stable.
          cells.add(const Expanded(child: SizedBox(height: _kYearChipHeight)));
          continue;
        }
        final year = items[idx];
        final isUnknownFuture = year == unknownFuture.year;
        final isUnknownPast = year == unknownPast.year;
        final isUnknown = isUnknownFuture || isUnknownPast;
        cells.add(
          Expanded(
            child: _YearChip(
              label: isUnknownFuture
                  ? l10n.mapFilterUnknownFuture
                  : isUnknownPast
                      ? l10n.mapFilterUnknownPast
                      : year.toString(),
              // Unknown labels are longer than a year number, so let them
              // shrink/wrap to keep the shared year-chip footprint.
              fitLabel: isUnknown,
              selected: poly.selectedYears.contains(year),
              isFuture: isUnknownFuture || (!isUnknown && year > currentYear),
              onTap: () => context.read<PolylineProvider>().toggleYear(year),
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
    ThemeData theme, {
    required String allLabel,
    required String noneLabel,
    required VoidCallback onAll,
    required VoidCallback onNone,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _miniButton(theme, allLabel, onAll, emphasized: true),
        const SizedBox(width: 4),
        _miniButton(theme, noneLabel, onNone),
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

/// Height of a single year chip, shared with the empty grid placeholders so a
/// padded (filled) page keeps the exact same height as a full one.
const double _kYearChipHeight = 44;

// ─── Year chip ────────────────────────────────────────────────────────────────

/// A single year cell. Past/current years get a solid border; future years a
/// dashed border to distinguish planned excursions from completed trips. The
/// same chip renders the "unknown past/future" buttons — with [fitLabel] set so
/// their longer text shrinks/wraps into the shared footprint.
class _YearChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isFuture;
  final bool fitLabel;
  final VoidCallback onTap;

  const _YearChip({
    required this.label,
    required this.selected,
    required this.isFuture,
    required this.onTap,
    this.fitLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const radius = 10.0;

    final bg = selected ? cs.primary : Colors.transparent;
    final fg = selected ? cs.onPrimary : cs.onSurface;
    final borderColor = selected ? cs.primary : cs.outline;

    Widget child = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: fitLabel ? 2 : 1,
      style: TextStyle(
        color: fg,
        fontWeight: FontWeight.w600,
        fontSize: fitLabel ? 12 : null,
        height: fitLabel ? 1.05 : null,
      ),
    );
    if (fitLabel) {
      // Wrap to (at most) two lines within the cell, then scale down if the
      // word itself is still too wide — guarantees the text always fits.
      child = FittedBox(
        fit: BoxFit.scaleDown,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 76),
          child: child,
        ),
      );
    }

    Widget content = Container(
      height: _kYearChipHeight,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        // Future years draw their (dashed) border via the painter below.
        border: isFuture ? null : Border.all(color: borderColor, width: 1.2),
      ),
      child: child,
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
