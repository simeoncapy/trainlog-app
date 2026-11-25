import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/core/data/models/country_detail.dart';
import 'package:trainlog_app/features/ranking/user_countries_controller.dart';
import 'package:trainlog_app/features/ranking/widgets/coverage_list_card.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_filter_controls.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_app_bar.dart';

/// A user's visited countries, Material: app bar with the username and the
/// sort buttons, then the countries (flag emoji, localized name) in a card.
class UserCountriesMaterialView extends StatelessWidget {
  const UserCountriesMaterialView({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final page = context.watch<UserCountriesController>();
    final countries = page.arrange(
      [
        for (final code in page.countryCodes)
          CountryDetail.fromCode(code, context),
      ],
      (c) => c.name,
    );

    final sortingButtons = Padding(
      padding: const EdgeInsets.only(right: 16),
      child: RankingSortButtons(
        alphabetical: page.alphabetical,
        descending: page.descending,
        onToggleAlphabetical: page.toggleAlphabetical,
        onToggleDirection: page.toggleDirection,
      ),
    );

    return Scaffold(
      appBar: AdaptiveAppBar(
        title: page.username,
        onBack: () => Navigator.of(context).pop(),
        materialActions: [sortingButtons],
        cupertinoTrailing: sortingButtons,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Expanded(
              child: countries.isEmpty
                  ? Center(child: Text(loc.noData))
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
