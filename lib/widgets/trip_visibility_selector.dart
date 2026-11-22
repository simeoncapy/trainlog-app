import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_segmented_button.dart';
import 'package:trainlog_app/core/data/models/trip_visibility.dart';

export 'package:trainlog_app/core/data/models/trip_visibility.dart';

class TripVisibilitySelector extends StatelessWidget {
  final TripVisibility value;
  final ValueChanged<TripVisibility> onChanged;

  const TripVisibilitySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AdaptiveSegmentedButton.build<TripVisibility>(
      context: context,
      segments: [
        AdaptiveSegmentedButtonSegment(
          value: TripVisibility.public,
          label: Text(loc.visibilityPublic),
          icon: Icon(TripVisibility.public.icon()),
        ),
        AdaptiveSegmentedButtonSegment(
          value: TripVisibility.friends,
          label: Text(loc.visibilityFriends),
          icon: Icon(TripVisibility.friends.icon()),
        ),
        AdaptiveSegmentedButtonSegment(
          value: TripVisibility.private,
          label: Text(loc.visibilityPrivate),
          icon: Icon(TripVisibility.private.icon()),
        ),
      ],
      selectedValue: value,
      onChanged: onChanged,
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity(horizontal: -2, vertical: -2),
      ),
    );
  }
}
