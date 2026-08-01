import 'package:flutter/material.dart';

/// One selectable entry of a [ChoiceCardSelector].
class ChoiceCardOption<T> {
  const ChoiceCardOption({
    required this.value,
    required this.icon,
    required this.label,
  });

  final T value;
  final IconData icon;
  final String label;
}

/// Row of equally sized selectable cards (icon above label) following the
/// vehicle type cards of the wizard's first step: the selected card is
/// filled with the theme primary colour, unselected cards stay on the card
/// colour with an outline border and keep the default icon colour.
class ChoiceCardSelector<T> extends StatelessWidget {
  const ChoiceCardSelector({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<ChoiceCardOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: _ChoiceCard(
              icon: options[i].icon,
              label: options[i].label,
              selected: options[i].value == value,
              onTap: () => onChanged(options[i].value),
            ),
          ),
        ],
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const radius = 16.0;

    final contentColor = selected ? cs.onPrimary : cs.onSurface;

    return Material(
      color: selected ? cs.primary : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: selected ? BorderSide.none : BorderSide(color: cs.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: contentColor),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: contentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
