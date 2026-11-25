import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialLocalizations, Theme;
import 'package:provider/provider.dart';

import 'package:trainlog_app/core/data/models/country_detail.dart';
import 'package:trainlog_app/features/ranking/cupertino/ranking_header_cupertino.dart';
import 'package:trainlog_app/features/ranking/cupertino/ranking_list_cupertino.dart';
import 'package:trainlog_app/features/ranking/user_countries_controller.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/cupertino/glass_menu_parts.dart';
import 'package:trainlog_app/ui/cupertino/liquid_glass.dart';

/// A user's visited countries on iOS, laid out like the other ranking
/// pages: a glass back button and the sort (↕ menu) as round glass buttons,
/// the username as the large title with the country count beneath, then the
/// countries (flag, localized name) in an inset grouped list.
class UserCountriesCupertinoView extends StatelessWidget {
  const UserCountriesCupertinoView({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final page = context.watch<UserCountriesController>();
    final media = MediaQuery.of(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final countries = page.arrange([
      for (final code in page.countryCodes)
        CountryDetail.fromCode(code, context),
    ], (c) => c.name);
    final count = countries.length;

    return ColoredBox(
      color: CupertinoDynamicColor.resolve(
        CupertinoTheme.of(context).scaffoldBackgroundColor,
        context,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: media.padding.top),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                GlassIconButton(
                  icon: CupertinoIcons.chevron_back,
                  shadow: false,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const Spacer(),
                GlassMenuIconButton(
                  icon: CupertinoIcons.arrow_up_arrow_down,
                  semanticLabel: loc.rankingSortMenu,
                  sections: rankingSortSections(
                    loc,
                    alphabetical: page.alphabetical,
                    descending: page.descending,
                    toggleAlphabetical: page.toggleAlphabetical,
                    toggleDirection: page.toggleDirection,
                  ),
                ),
              ],
            ),
          ),
          RankingTitleBar(title: page.username),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              '$count ${loc.rankingCountryCountLabel(count)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: secondary,
                letterSpacing: 0,
              ),
            ),
          ),
          Expanded(
            child: countries.isEmpty
                ? Padding(
                    padding: EdgeInsets.only(bottom: media.padding.bottom),
                    child: Center(
                      child: Text(
                        loc.noData,
                        style: TextStyle(color: secondary),
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      media.padding.bottom + 12,
                    ),
                    itemCount: count,
                    itemBuilder: (context, i) => RankingGroupedRow(
                      isFirst: i == 0,
                      isLast: i == count - 1,
                      // Under the name, as in iOS lists.
                      dividerIndent: 58,
                      child: _CountryRowCupertino(country: countries[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Flag emoji and localized name.
class _CountryRowCupertino extends StatelessWidget {
  const _CountryRowCupertino({required this.country});

  final CountryDetail country;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              country.emoji,
              style: TextStyle(fontSize: text.headlineSmall?.fontSize),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              country.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyLarge?.copyWith(
                color: CupertinoColors.label.resolveFrom(context),
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
