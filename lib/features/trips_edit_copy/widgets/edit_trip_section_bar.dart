import 'package:flutter/material.dart';
import 'package:trainlog_app/features/trips_edit_copy/widgets/cupertino/section_chip_cupertino.dart';
import 'package:trainlog_app/features/trips_edit_copy/edit_trip_section.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/widgets/selector_pill.dart';

/// Sticky horizontal pill bar anchoring the sections of the edit form, in the
/// style of the ranking category selector.
///
/// Tapping a pill is handled by the host, which animates its scroll view to
/// the matching section; the bar itself only keeps the active pill visible.
class EditTripSectionBar extends StatefulWidget {
  const EditTripSectionBar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.sections = EditTripSection.trip,
  });

  final EditTripSection selected;
  final ValueChanged<EditTripSection> onSelected;
  final List<EditTripSection> sections;

  @override
  State<EditTripSectionBar> createState() => _EditTripSectionBarState();
}

class _EditTripSectionBarState extends State<EditTripSectionBar> {
  final ScrollController _controller = ScrollController();
  late final Map<EditTripSection, GlobalKey> _pillKeys = {
    for (final section in widget.sections) section: GlobalKey(),
  };

  @override
  void didUpdateWidget(covariant EditTripSectionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Following the scroll position must not push the active pill off-screen.
    if (oldWidget.selected != widget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _revealSelected() {
    final context = _pillKeys[widget.selected]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: 0.5,
    );
  }

  /// The strip of chips, built with one design's [chip]; [clip] and [gap]
  /// are that design's.
  Widget _strip(
    BuildContext context, {
    required Clip clip,
    required double gap,
    required Widget Function({
      Key? key,
      required String label,
      required bool selected,
      required VoidCallback onTap,
    })
    chip,
  }) {
    final loc = AppLocalizations.of(context)!;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        clipBehavior: clip,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.sections.length,
        separatorBuilder: (_, __) => SizedBox(width: gap),
        itemBuilder: (context, i) {
          final section = widget.sections[i];
          return chip(
            key: _pillKeys[section],
            label: section.label(loc),
            selected: section == widget.selected,
            onTap: () => widget.onSelected(section),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PlatformView(
    material: (context) =>
        _strip(context, clip: Clip.hardEdge, gap: 10, chip: SelectorPill.new),
    cupertino: (context) => _strip(
      context,
      // Let the active chip's shadow spill out of the strip.
      clip: Clip.none,
      gap: 8,
      chip: CupertinoSectionChip.new,
    ),
  );
}
