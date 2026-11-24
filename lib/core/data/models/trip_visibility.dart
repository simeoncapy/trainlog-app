import 'package:flutter/widgets.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Who can see a trip.
enum TripVisibility {
  public,
  friends,
  private;

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
