import 'package:flutter/material.dart';

import 'package:trainlog_app/data/models/country_detail.dart';
import 'package:trainlog_app/features/ranking/widgets/coverage_list_card.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_filter_controls.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_app_bar.dart';

/// Drill-down sub-page for the countries-visited leaderboard: the full list of
/// countries a single user has visited, with their flag and localized name.
/// Pushed onto the stack (hiding the bottom navigation) when a row of the
/// country ranking is tapped; the app-bar title is the user's name.
///
/// The default order is the backend order (by trip count, most visited first);
/// the two sort toggles switch to/from alphabetical order and reverse the
/// direction — display only, the data is never refetched.
class UserCountriesPage extends StatefulWidget {
  /// The user whose countries are listed (shown as the app-bar title).
  final String username;

  /// ISO country codes in the backend order (by trip count per country, most
  /// visited first).
  final List<String> countryCodes;

  const UserCountriesPage({
    super.key,
    required this.username,
    required this.countryCodes,
  });

  @override
  State<UserCountriesPage> createState() => _UserCountriesPageState();
}

class _UserCountriesPageState extends State<UserCountriesPage> {
  bool _alphabetical = false;
  bool _descending = true;

  /// Countries in display order: the backend order by default (the "value"
  /// order), or sorted by localized name when the alphabetical toggle is on;
  /// the direction toggle reverses either order.
  List<CountryDetail> _displayCountries(BuildContext context) {
    final details = [
      for (final code in widget.countryCodes)
        CountryDetail.fromCode(code, context),
    ];
    if (_alphabetical) {
      details.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    }
    return _descending ? details : details.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final countries = _displayCountries(context);

    return Scaffold(
      appBar: AdaptiveAppBar(
        title: widget.username,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  const Spacer(),
                  RankingSortButtons(
                    alphabetical: _alphabetical,
                    descending: _descending,
                    onToggleAlphabetical: () =>
                        setState(() => _alphabetical = !_alphabetical),
                    onToggleDirection: () =>
                        setState(() => _descending = !_descending),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: countries.isEmpty
                  ? Center(child: Text(loc.rankingNoData))
                  : CoverageListCard(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: countries.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          thickness: 1,
                          indent: 16,
                          endIndent: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withValues(alpha: 0.4),
                        ),
                        itemBuilder: (context, i) =>
                            _CountryRow(country: countries[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single visited-country row: flag emoji + localized name.
class _CountryRow extends StatelessWidget {
  final CountryDetail country;

  const _CountryRow({required this.country});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(country.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              country.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
