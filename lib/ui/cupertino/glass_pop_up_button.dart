import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

/// iOS 26 "pop-up button": the current value with up/down chevrons, opening
/// a Liquid Glass menu that morphs out of it. The selected option carries a
/// check mark.
///
/// [builder] places the button: it receives the button and the callback
/// that opens the menu (null when disabled), so a whole row can open it.
class GlassPopUpButton<T> extends StatefulWidget {
  const GlassPopUpButton({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.semanticLabel,
    required this.builder,
    this.enabled = true,
    this.menuWidth = 250,
  });

  final List<({String label, T value})> options;
  final T? selected;
  final ValueChanged<T> onChanged;
  final String semanticLabel;
  final bool enabled;
  final double menuWidth;
  final Widget Function(BuildContext context, Widget button, VoidCallback? open)
  builder;

  @override
  State<GlassPopUpButton<T>> createState() => _GlassPopUpButtonState<T>();
}

class _GlassPopUpButtonState<T> extends State<GlassPopUpButton<T>> {
  final lg.GlassMenuController _menu = lg.GlassMenuController();

  @override
  Widget build(BuildContext context) {
    final current = widget.options
        .where((o) => o.value == widget.selected)
        .map((o) => o.label)
        .firstOrNull;
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);

    final trigger = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.34,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                current ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 17, color: secondary),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_up_chevron_down,
              size: 14,
              color: secondary,
            ),
          ],
        ),
      ),
    );

    if (!widget.enabled) return widget.builder(context, trigger, null);

    final button = lg.GlassMenu(
      controller: _menu,
      trigger: trigger,
      // Wider for long labels (e.g. path display order).
      menuWidth: widget.options.any((o) => o.label.length > 24)
          ? MediaQuery.sizeOf(context).width - 48
          : widget.menuWidth,
      menuAlignment: lg.GlassMenuAlignment.topRight,
      autoAdjustToScreen: true,
      menuPadding: const EdgeInsets.all(12),
      menuSemanticLabel: widget.semanticLabel,
      items: [
        for (final o in widget.options)
          lg.GlassMenuItem(
            title: o.label,
            // The menu sizes each item from maxLines, so only long labels
            // get a second line (else an empty band shows under the last
            // item).
            maxLines: o.label.length > 30 ? 2 : 1,
            titleStyle: TextStyle(fontSize: 17, color: label),
            // Same slot width with or without the check, so the labels
            // line up.
            icon: SizedBox(
              width: 20,
              child: o.value == widget.selected
                  ? const Icon(CupertinoIcons.checkmark, size: 17)
                  : null,
            ),
            iconSize: 17,
            semanticsChecked: o.value == widget.selected,
            onTap: () => widget.onChanged(o.value),
          ),
      ],
    );
    return widget.builder(context, button, _menu.open);
  }
}
