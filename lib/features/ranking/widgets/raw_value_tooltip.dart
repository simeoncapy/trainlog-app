import 'package:flutter/material.dart';

/// Wraps [child] so that tapping it reveals [message] — the raw, un-rounded
/// value in its base unit — as a tooltip.
///
/// Ranking values are shown rounded (e.g. CO2e in g/km) or with SI prefixes
/// (e.g. distance as `Mm`/`Gm`); this lets the user tap the number to read the
/// exact base-unit value. The child's appearance is intentionally left
/// untouched (no underline or other affordance) so the layout is unchanged.
///
/// When [message] is null the child is returned as-is (used for metrics that are
/// already shown exactly, such as a plain trip count).
class RawValueTooltip extends StatelessWidget {
  final String? message;
  final Widget child;

  const RawValueTooltip({
    super.key,
    required this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    if (message == null) return child;

    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      preferBelow: false,
      waitDuration: Duration.zero,
      showDuration: const Duration(seconds: 4),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: TextStyle(color: cs.onPrimaryContainer),
      child: child,
    );
  }
}
