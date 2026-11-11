import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/app/theme/app_colors.dart';
import 'package:trainlog_app/features/trips_edit_copy/edit_trip_section.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        // Apple: let the active chip's shadow spill out of the strip.
        clipBehavior: AppPlatform.isApple ? Clip.none : Clip.hardEdge,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.sections.length,
        separatorBuilder: (_, __) =>
            SizedBox(width: AppPlatform.isApple ? 8 : 10),
        itemBuilder: (context, i) {
          final section = widget.sections[i];
          if (AppPlatform.isApple) {
            return _AppleSectionChip(
              key: _pillKeys[section],
              label: section.label(loc),
              selected: section == widget.selected,
              onTap: () => widget.onSelected(section),
            );
          }
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

/// Apple flavour of a section chip, matching the segmented controls: the
/// active section sits on the white, amber-rimmed thumb, the others on a
/// quiet system fill.
class _AppleSectionChip extends StatelessWidget {
  const _AppleSectionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const duration = Duration(milliseconds: 200);

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: AnimatedContainer(
            duration: duration,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              shape: StadiumBorder(
                side: BorderSide(
                  color: selected
                      ? AppColors.amber.withValues(alpha: isDark ? 0.45 : 0.40)
                      : Colors.transparent,
                  width: 0.8,
                ),
              ),
              color: selected
                  ? (isDark ? const Color(0xFF3A4255) : CupertinoColors.white)
                  : CupertinoColors.tertiarySystemFill.resolveFrom(context),
              shadows: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : const [],
            ),
            child: AnimatedDefaultTextStyle(
              duration: duration,
              style: TextStyle(
                color: selected
                    ? CupertinoColors.label.resolveFrom(context)
                    : CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 15,
                letterSpacing: -0.2,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
