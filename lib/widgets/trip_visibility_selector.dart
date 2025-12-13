import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

enum TripVisibility { public, friends, private }

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

    return SegmentedButton<TripVisibility>(
      segments: [
        ButtonSegment(
          value: TripVisibility.public,
          label: Text(loc.visibilityPublic),
          icon: const Icon(Icons.public),
        ),
        ButtonSegment(
          value: TripVisibility.friends,
          label: Text(loc.visibilityFriends),
          icon: const Icon(Icons.people),
        ),
        ButtonSegment(
          value: TripVisibility.private,
          label: Text(loc.visibilityPrivate),
          icon: const Icon(Icons.lock),
        ),
      ],
      selected: {value},
      onSelectionChanged: (newSelection) {
        onChanged(newSelection.first);
      },
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity(horizontal: -2, vertical: -2),
      ),
    );
  }
}
