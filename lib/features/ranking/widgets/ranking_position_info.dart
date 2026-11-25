import 'package:flutter/widgets.dart';

import 'package:trainlog_app/core/providers/ranking_provider.dart';
import 'package:trainlog_app/features/ranking/ranking_metrics.dart';
import 'package:trainlog_app/features/ranking/ranking_type.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

/// What the "Your position" card shows for the current leaderboard, the same
/// on both designs: the line under the username, the primary value, and the
/// extra content beneath (the carbon note, or the visited countries).
class RankingPositionInfo {
  const RankingPositionInfo._({
    required this.subtitle,
    required this.valueText,
    required this.valueTooltip,
    required this.explanation,
    required this.countryCodes,
  });

  /// The complementary metrics, or a caption ("Not ranked", "Countries
  /// visited"…).
  final String subtitle;

  /// The primary metric, null when the user is not ranked.
  final String? valueText;

  /// Its raw value, revealed on tap.
  final String? valueTooltip;

  /// The carbon leaderboard's note (lower g/km ranks better).
  final String? explanation;

  /// The countries the user visited (country leaderboard), most visited
  /// first; empty otherwise.
  final List<String> countryCodes;

  factory RankingPositionInfo.of(
    BuildContext context,
    RankingProvider provider,
  ) {
    final loc = AppLocalizations.of(context)!;
    final selection = provider.selection;
    final entry = provider.currentUserEntry;

    final String subtitle;
    if (entry == null) {
      subtitle = loc.rankingNotRanked;
    } else if (selection.isWorldSquares) {
      subtitle = loc.rankingWorldCovered;
    } else if (selection.isCountry) {
      subtitle = loc.rankingCountriesVisited;
    } else {
      // The complementary metric(s) not used as the primary value.
      subtitle = RankingMetrics.secondaries(
        context,
        entry,
        selection,
        provider.sortUnit,
      ).join(' · ');
    }

    return RankingPositionInfo._(
      subtitle: subtitle,
      valueText: entry == null
          ? null
          : RankingMetrics.primaryInline(
              context, entry, selection, provider.sortUnit),
      valueTooltip: entry == null
          ? null
          : RankingMetrics.primaryTooltip(
              context, entry, selection, provider.sortUnit),
      explanation: selection.type == RankingType.carbon
          ? loc.rankingCarbonExplanation
          : null,
      countryCodes: selection.isCountry && entry != null
          ? entry.countriesVisited
          : const [],
    );
  }
}
