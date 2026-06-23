import 'dart:ui' show ImageFilter;

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
/// single "Vehicle ▾" pill that, on tap, opens a floating dropdown anchored
/// under it (over the page content, without reflowing it). Picking one closes
/// the dropdown and relabels the pill to the chosen vehicle; selecting any other
/// category resets it back to "Vehicle ▾". With [isCompact] false the behaviour
/// is unchanged (every pill shown inline).
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

class _RankingSelectorBarState extends State<RankingSelectorBar>
    with SingleTickerProviderStateMixin {
  final _overlayController = OverlayPortalController();
  final _triggerLink = LayerLink();
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  bool get _isOpen => _overlayController.isShowing;

  void _openDropdown() {
    _overlayController.show();
    _anim.forward();
    setState(() {});
  }

  Future<void> _closeDropdown() async {
    if (!_isOpen) return;
    await _anim.reverse();
    if (!mounted) return;
    _overlayController.hide();
    setState(() {});
  }

  void _toggleDropdown() => _isOpen ? _closeDropdown() : _openDropdown();

  void _select(RankingSelection selection) {
    _closeDropdown();
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

  // ── Compact mode: vehicles folded behind a floating dropdown ───────────────

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
          rowChildren.add(_vehicleTrigger(vehiclePills, palette));
          triggerAdded = true;
        }
        continue;
      }
      rowChildren.add(_pillFor(pill, palette));
    }

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Allow the floating dropdown to paint outside the row bounds.
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: rowChildren.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) => rowChildren[i],
      ),
    );
  }

  Widget _vehicleTrigger(
    List<RankingSelection> vehiclePills,
    Map<VehicleType, Color> palette,
  ) {
    final isVehicleSelected = widget.selected.isVehicle;
    // Show the chosen vehicle once one is selected, otherwise the generic group.
    final triggerSelection = isVehicleSelected
        ? widget.selected
        : const RankingSelection.category(RankingType.vehicles);

    return CompositedTransformTarget(
      link: _triggerLink,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (context) =>
            _buildDropdownOverlay(vehiclePills, palette),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) => _Pill(
            selection: triggerSelection,
            selected: isVehicleSelected,
            enabled: true,
            accentColor: triggerSelection.accentColor(palette),
            onTap: _toggleDropdown,
            trailing: Transform.rotate(
              angle: _anim.value * 3.14159,
              child: const Icon(Icons.keyboard_arrow_down, size: 18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownOverlay(
    List<RankingSelection> vehiclePills,
    Map<VehicleType, Color> palette,
  ) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // Tap-outside barrier.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _closeDropdown,
          ),
        ),
        // Dropdown anchored just under the trigger pill.
        CompositedTransformFollower(
          link: _triggerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 8),
          child: FadeTransition(
            opacity: _anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(
                CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
              ),
              alignment: Alignment.topLeft,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(18),
                      // border: Border.all(
                      //   color: cs.outline.withValues(alpha: 0.25),
                      // ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.shadow.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < vehiclePills.length; i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            SizedBox(
                              height: 44,
                              child: _pillFor(vehiclePills[i], palette),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
