import 'package:flutter/material.dart';
import 'package:trainlog_app/features/trips_edit_copy/edit_trip_section.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
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
    this.sections = EditTripSection.values,
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.sections.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final section = widget.sections[i];
          return SelectorPill(
            key: _pillKeys[section],
            label: section.label(loc),
            selected: section == widget.selected,
            onTap: () => widget.onSelected(section),
          );
        },
      ),
    );
  }
}
