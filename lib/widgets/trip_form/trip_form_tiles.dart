import 'package:flutter/material.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_card.dart';

/// One free-text line item of a [TripFormCard]: leading icon (or any custom
/// [leading] widget), uppercase label and a borderless input underneath.
///
/// The icon is tinted with the primary colour once the field has a value.
class TripFormFieldTile extends StatelessWidget {
  const TripFormFieldTile({
    super.key,
    this.icon,
    this.leading,
    required this.label,
    required this.onChanged,
    this.initialValue,
    this.hintText,
    this.readOnly = false,
  }) : assert(icon != null || leading != null,
            'A tile needs either an icon or a leading widget');

  final IconData? icon;

  /// Replaces the leading icon entirely (e.g. a route endpoint marker).
  final Widget? leading;

  final String label;
  final ValueChanged<String> onChanged;
  final String? initialValue;
  final String? hintText;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = initialValue?.isNotEmpty ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          leading ??
              Icon(
                icon,
                size: 18,
                color: hasValue
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TripFormSectionLabel(label),
                const SizedBox(height: 4),
                TextFormField(
                  initialValue: initialValue,
                  readOnly: readOnly,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    hintText: hintText,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One value line item of a [TripFormCard]: leading icon (tinted with the
/// primary colour once the item has a value), uppercase label, the value
/// widget underneath and an optional trailing widget.
class TripFormValueTile extends StatelessWidget {
  const TripFormValueTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.hasValue = false,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget value;
  final bool hasValue;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: hasValue
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TripFormSectionLabel(label),
                const SizedBox(height: 4),
                value,
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: content,
    );
  }
}

/// Standalone note card: a sticky-note icon and a borderless italic input
/// growing with its content.
class TripFormNotesCard extends StatelessWidget {
  const TripFormNotesCard({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final String? initialValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TripFormCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.sticky_note_2_outlined,
              size: 18,
              color: (initialValue?.isNotEmpty ?? false)
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: initialValue,
                // Grows with its content.
                minLines: 1,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Trip route endpoint marker: hollow rounded square for the departure,
/// filled with the vehicle colour for the arrival.
class RouteEndpointMarker extends StatelessWidget {
  const RouteEndpointMarker({
    super.key,
    required this.colour,
    required this.filled,
    this.size = 14,
  });

  final Color colour;

  /// True for the arrival marker.
  final bool filled;

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? colour : Colors.transparent,
        borderRadius: BorderRadius.circular(size / 3.5),
        border: Border.all(color: colour, width: 2.5),
      ),
    );
  }
}
