import 'package:flutter/material.dart';

/// Rounded grouped card of the trip forms: card colour, 16 px radius, hairline
/// outline and, by default, hairline dividers between the children.
///
/// Shared by the add-trip wizard steps and the edit/duplicate form so every
/// grouped block of the app looks the same.
class TripFormCard extends StatelessWidget {
  const TripFormCard({
    super.key,
    required this.children,
    this.padding,
    this.separated = true,
    this.borderColor,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;

  /// Inner padding. Null keeps the children flush with the card edges, which
  /// is what line-item children (already padded) expect.
  final EdgeInsetsGeometry? padding;

  /// Inserts a hairline divider between consecutive children.
  final bool separated;

  /// Overrides the outline colour (e.g. to flag an invalid block).
  final Color? borderColor;

  /// Horizontal alignment of the children. Stretching suits line items;
  /// blocks with intrinsically sized content pass [CrossAxisAlignment.start].
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (separated && i > 0) Divider(height: 1, color: theme.dividerColor),
          children[i],
        ],
      ],
    );

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? theme.colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}

/// Small uppercase section label ("SELECTED OPERATORS", "TICKET", "ROUTE"…)
/// introducing a [TripFormCard].
class TripFormSectionLabel extends StatelessWidget {
  const TripFormSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}
