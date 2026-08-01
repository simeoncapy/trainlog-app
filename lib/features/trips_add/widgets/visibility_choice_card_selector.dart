import 'package:flutter/material.dart';
import 'package:trainlog_app/features/trips_add/widgets/choice_card_selector.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/trip_visibility_selector.dart';

/// Visibility of a trip as a row of [ChoiceCardSelector] cards, one per
/// [TripVisibility].
///
/// The card row is the trip form flavour of the selector — the segmented
/// [TripVisibilitySelector] stays the compact one used outside the forms.
/// Shared by the add-trip ticket step and the edit/duplicate ticket section.
class VisibilityChoiceCardSelector extends StatelessWidget {
  const VisibilityChoiceCardSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final TripVisibility value;
  final ValueChanged<TripVisibility> onChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return ChoiceCardSelector<TripVisibility>(
      options: [
        for (final visibility in TripVisibility.values)
          ChoiceCardOption(
            value: visibility,
            icon: visibility.icon(),
            label: visibility.label(loc),
          ),
      ],
      value: value,
      onChanged: onChanged,
    );
  }
}
