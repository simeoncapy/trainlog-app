import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_segmented_button.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

enum TripVisibility {
  public, friends, private;

  static TripVisibility fromString(String? s) {
    final v = s?.toLowerCase();
    return TripVisibility.values.firstWhere(
      (e) => e.name == v,
      orElse: () => TripVisibility.private,
    );
  }

  String label(AppLocalizations loc) {
    switch (this) {
      case TripVisibility.public:
        return loc.visibilityPublic;
      case TripVisibility.friends:
        return loc.visibilityFriends;
      case TripVisibility.private:
        return loc.visibilityPrivate;
    }
  }

  String longLabel(AppLocalizations loc) {
    switch (this) {
      case TripVisibility.public:
        return loc.visibilityPublicLong;
      case TripVisibility.friends:
        return loc.visibilityFriendsLong;
      case TripVisibility.private:
        return loc.visibilityPrivateLong;
    }
  }

  IconData icon() {
    switch (this) {
      case TripVisibility.public:
        return AdaptiveIcons.visibilityPublic;
      case TripVisibility.friends:
        return AdaptiveIcons.visibilityFriends;
      case TripVisibility.private:
        return AdaptiveIcons.visibilityPrivate;
    }
  }
}


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
