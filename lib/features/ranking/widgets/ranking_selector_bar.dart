import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/features/ranking/ranking_type.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';

/// Horizontally scrollable category selector ("pills").
///
/// Implemented categories are tappable; the rest are shown disabled (greyed
/// out, non-interactive) so users can see what is coming.
///
/// When [isCompact] is true the individual vehicle pills are collapsed behind a
/// single "Vehicle ▾" pill that expands them in a column on tap; picking one
/// collapses the column and relabels the pill to the chosen vehicle. Selecting
/// any other category resets it back to "Vehicle ▾". With [isCompact] false the
/// behaviour is unchanged (every pill shown inline).
class RankingSelectorBar extends StatefulWidget {
  final RankingSelection selected;
  final ValueChanged<RankingSelection> onSelected;
  final bool isCompact;

  const RankingSelectorBar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.isCompact = false,
  });

  @override
  State<RankingSelectorBar> createState() => _RankingSelectorBarState();
}

class _RankingSelectorBarState extends State<RankingSelectorBar> {
  bool _vehiclesExpanded = false;

  void _collapse() {
    if (_vehiclesExpanded) setState(() => _vehiclesExpanded = false);
  }

  void _select(RankingSelection selection) {
    _collapse();
    widget.onSelected(selection);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
    final pills = buildRankingPills();

    return widget.isCompact
        ? _buildCompact(context, pills, palette)
        : _buildFull(context, pills, palette);
  }

  // ── Full mode: every pill inline, horizontally scrollable ──────────────────

  Widget _buildFull(
    BuildContext context,
    List<RankingSelection> pills,
    Map<VehicleType, Color> palette,
  ) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: pills.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) => _pillFor(pills[i], palette),
      ),
    );
  }

  // ── Compact mode: vehicles folded behind a dropdown pill ───────────────────

  Widget _buildCompact(
    BuildContext context,
    List<RankingSelection> pills,
    Map<VehicleType, Color> palette,
  ) {
    final vehiclePills = pills.where((p) => p.isVehicle).toList();

    // Top row: non-vehicle pills, with a single trigger standing in for the
    // vehicle group (inserted at the group's original position).
    final rowChildren = <Widget>[];
    var triggerAdded = false;
    for (final pill in pills) {
      if (pill.isVehicle) {
        if (!triggerAdded) {
          rowChildren.add(_vehicleTrigger(palette));
          triggerAdded = true;
        }
        continue;
      }
      rowChildren.add(_pillFor(pill, palette));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: rowChildren.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) => rowChildren[i],
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _vehiclesExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final v in vehiclePills)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _pillFor(v, palette),
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ),
      ],
    );
  }

  Widget _vehicleTrigger(Map<VehicleType, Color> palette) {
    final isVehicleSelected = widget.selected.isVehicle;
    // Show the chosen vehicle once one is selected, otherwise the generic group.
    final triggerSelection = isVehicleSelected
        ? widget.selected
        : const RankingSelection.category(RankingType.vehicles);

    return _Pill(
      selection: triggerSelection,
      selected: isVehicleSelected,
      enabled: true,
      accentColor: triggerSelection.accentColor(palette),
      onTap: () => setState(() => _vehiclesExpanded = !_vehiclesExpanded),
      trailing: AnimatedRotation(
        turns: _vehiclesExpanded ? 0.5 : 0,
        duration: const Duration(milliseconds: 200),
        child: const Icon(Icons.keyboard_arrow_down, size: 18),
      ),
    );
  }

  Widget _pillFor(RankingSelection pill, Map<VehicleType, Color> palette) {
    return _Pill(
      selection: pill,
      selected: pill == widget.selected,
      enabled: pill.type.isImplemented,
      accentColor: pill.accentColor(palette),
      onTap: () => _select(pill),
    );
  }
}

class _Pill extends StatelessWidget {
  final RankingSelection selection;
  final bool selected;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onTap;

  /// Optional trailing widget (e.g. a chevron); tinted with the pill foreground.
  final Widget? trailing;

  const _Pill({
    required this.selection,
    required this.selected,
    required this.enabled,
    required this.accentColor,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Color bg;
    final Color fg;
    final Color accent;
    if (selected) {
      bg = cs.inverseSurface;
      fg = cs.onInverseSurface;
      accent = accentColor;
    } else if (enabled) {
      bg = cs.surface;
      fg = cs.onSurface;
      accent = accentColor;
    } else {
      bg = cs.surface.withValues(alpha: 0.5);
      fg = cs.onSurfaceVariant.withValues(alpha: 0.5);
      accent = cs.onSurfaceVariant.withValues(alpha: 0.4);
    }

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : cs.outline.withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconTheme(
                  data: IconThemeData(size: 16, color: accent),
                  child: selection.icon,
                ),
                const SizedBox(width: 8),
                Text(
                  selection.label(context),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 6),
                  IconTheme(
                    data: IconThemeData(size: 18, color: fg),
                    child: trailing!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
