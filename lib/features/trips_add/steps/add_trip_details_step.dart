import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

/// Step 5 of the "Add Trip" wizard: optional trip details.
///
/// A bold headline with an "all optional" subtitle, then a grouped card of
/// free-text line items (line name, material, registration number, seat)
/// and a standalone note card whose field grows with its content. All
/// values are written straight into [TripFormModel]; the step is skippable
/// and never blocks progression.
class AddTripDetailsStep extends StatefulWidget {
  const AddTripDetailsStep({super.key});

  @override
  State<AddTripDetailsStep> createState() => _AddTripDetailsStepState();
}

class _AddTripDetailsStepState extends State<AddTripDetailsStep> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final model = context.watch<TripFormModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.addTripDetailsTitle,
            style: AppTheme.displayFont.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            loc.addTripDetailsSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Column(
              children: [
                _DetailFieldTile(
                  icon: Icons.route,
                  label: loc.addTripLineName,
                  initialValue: model.line,
                  onChanged: (value) {
                    setState(() => model.line = value);
                  },
                ),
                Divider(height: 1, color: theme.dividerColor),
                _DetailFieldTile(
                  icon: Icons.sell_outlined,
                  label: loc.addTripMaterial,
                  initialValue: model.material,
                  onChanged: (value) {
                    setState(() => model.material = value);
                  },
                ),
                Divider(height: 1, color: theme.dividerColor),
                _DetailFieldTile(
                  icon: Icons.tag,
                  label: loc.addTripRegistrationNumber,
                  hint: loc.addTripRegistrationHint,
                  initialValue: model.registration,
                  onChanged: (value) {
                    setState(() => model.registration = value);
                  },
                ),
                Divider(height: 1, color: theme.dividerColor),
                _DetailFieldTile(
                  icon: Icons.event_seat_outlined,
                  label: loc.addTripSeat,
                  initialValue: model.seat,
                  onChanged: (value) {
                    setState(() => model.seat = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            loc.addTripNotes.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.sticky_note_2_outlined,
                  size: 18,
                  color: (model.notes?.isNotEmpty ?? false)
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: model.notes,
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
                    onChanged: (value) {
                      setState(() => model.notes = value);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One line item of the details card: leading icon (tinted with the primary
/// colour once the field has a value), uppercase label and a borderless
/// free-text input underneath.
class _DetailFieldTile extends StatelessWidget {
  const _DetailFieldTile({
    required this.icon,
    required this.label,
    required this.onChanged,
    this.initialValue,
    this.hint,
  });

  final IconData icon;
  final String label;
  final ValueChanged<String> onChanged;
  final String? initialValue;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = initialValue?.isNotEmpty ?? false;

    return Padding(
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
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  initialValue: initialValue,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: hint,
                    hintStyle: AppTheme.monoFont.copyWith(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.7),
                    ),
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
