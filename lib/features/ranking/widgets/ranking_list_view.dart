import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:trainlog_app/app/theme/app_colors.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/features/ranking/ranking_metrics.dart';
import 'package:trainlog_app/features/ranking/ranking_type.dart';
import 'package:trainlog_app/features/ranking/user_countries_page.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_medal.dart';
import 'package:trainlog_app/features/ranking/widgets/raw_value_tooltip.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_page_route.dart';
import 'package:trainlog_app/providers/ranking_provider.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/widgets/monogram.dart';

/// Scrollable leaderboard list. Renders the provider's display-ordered rows,
/// highlighting the current user inline, and applies the optional [searchQuery]
/// username filter (display only — ranks are untouched).
class RankingListView extends StatelessWidget {
  final RankingProvider provider;
  final String searchQuery;

  const RankingListView({
    super.key,
    required this.provider,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? cs.surface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.transparent//cs.outline.withValues(alpha: 0.25)
              : cs.outline.withValues(alpha: 0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (provider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (provider.error != null) {
      return Center(child: Text('Error: ${provider.error}'));
    }

    final query = searchQuery.trim().toLowerCase();
    final rows = query.isEmpty
        ? provider.displayEntries
        : provider.displayEntries
            .where((e) => e.username.toLowerCase().contains(query))
            .toList();

    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Text(loc.rankingNoData),
        ),
      );
    }

    final me = provider.currentUsername?.toLowerCase();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, i) {
        final e = rows[i];
        // A tie shows its rank only on the first of the equal-valued rows that
        // are displayed next to each other; the rest leave the rank blank. This
        // works for every order (value/reversed/alphabetical) and unit because
        // it compares the raw ranking value of adjacent displayed rows — rows
        // are tied only when that value is exactly equal, not merely rounded
        // to the same displayed number.
        final showRank = i == 0 ||
            provider.metricOf(rows[i - 1]) != provider.metricOf(e);
        return RankingRow(
          entry: e,
          selection: provider.selection,
          sortUnit: provider.sortUnit,
          isCurrentUser: me != null && e.username.toLowerCase() == me,
          showRank: showRank,
          // Country rows drill into the user's full visited-country list.
          onTap: provider.selection.isCountry
              ? () => AdaptivePageRoute.push(
                    context,
                    (_) => UserCountriesPage(
                      username: e.username,
                      countryCodes: e.countriesVisited,
                    ),
                  )
              : null,
        );
      },
    );
  }
}

/// A single leaderboard row.
class RankingRow extends StatelessWidget {
  final RankingDisplayEntry entry;
  final RankingSelection selection;
  final RankingSortUnit sortUnit;
  final bool isCurrentUser;

  /// Whether to show the rank indicator. Tied rows displayed next to each other
  /// only show the rank on the first one (see [RankingListView]).
  final bool showRank;

  /// When set, the row is tappable and shows a trailing navigation chevron
  /// (used by the country ranking to drill into the visited-country list).
  final VoidCallback? onTap;

  const RankingRow({
    super.key,
    required this.entry,
    required this.selection,
    required this.sortUnit,
    required this.isCurrentUser,
    this.showRank = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? cs.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isCurrentUser
            ? Border.all(color: cs.primary.withValues(alpha: 0.6), width: 1.4)
            : null,
      ),
      child: Row(
        children: [
          RankIndicator(rank: entry.rank, showRank: showRank),
          const SizedBox(width: 10),
          Monogram(username: entry.username, highlight: isCurrentUser),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.username,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isCurrentUser ? cs.primary : cs.onSurface,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                ..._supportingLines(context, cs),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // CO2e/km is rendered as a coloured threshold pill; everything else
          // as the large value + stacked unit. Both reveal the raw base-unit
          // value on tap (see [RawValueTooltip]).
          if (_isCarbon && sortUnit == RankingSortUnit.carbonPerKm)
            _CarbonPill(
              gPerKm: entry.carbonPerKmG,
              tooltip: RankingMetrics.rawTooltip(
                  context, entry, RankingSortUnit.carbonPerKm),
            )
          else
            Builder(builder: (context) {
              final primary = _primary(context);
              return _PrimaryValue(
                value: primary.value,
                unit: primary.unit,
                tooltip: RankingMetrics.primaryTooltip(
                    context, entry, selection, sortUnit),
              );
            }),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: row,
    );
  }

  bool get _isCarbon => selection.type == RankingType.carbon;

  /// Primary value + unit (CO2e/km handled by [_CarbonPill] in the row).
  CompactNumber _primary(BuildContext context) =>
      RankingMetrics.primary(context, entry, selection, sortUnit);

  /// The supporting lines beneath the username: the first non-primary metric,
  /// then either the second metric (carbon has two secondaries) or the last
  /// activity date. Metric lines reveal their raw base-unit value on tap; the
  /// date does not.
  List<Widget> _supportingLines(BuildContext context, ColorScheme cs) {
    final secondaries =
        RankingMetrics.secondaryMetrics(context, entry, selection, sortUnit);
    final lines = <Widget>[];

    if (secondaries.isNotEmpty) {
      final m = secondaries.first;
      lines.add(RawValueTooltip(
        message: m.tooltip,
        child: Text(
          m.inline,
          style: AppTheme.monoFont.copyWith(
            fontSize: 12,
            color: cs.onSurfaceVariant,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ));
    }

    final lineStyle = AppTheme.monoFont.copyWith(
      fontSize: 11,
      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
    );
    if (secondaries.length >= 2) {
      final m = secondaries.last;
      lines.add(RawValueTooltip(
        message: m.tooltip,
        child: Text(m.inline, style: lineStyle, overflow: TextOverflow.ellipsis),
      ));
    } else {
      final date = entry.lastModified;
      if (date != null) {
        lines.add(Text(
          DateFormat.yMMM(Localizations.localeOf(context).toString())
              .format(date),
          style: lineStyle,
          overflow: TextOverflow.ellipsis,
        ));
      }
    }

    return lines;
  }
}

/// CO2e/km value shown as a coloured threshold pill (green / amber / red),
/// matching the design. Colour comes from [CarbonThreshold].
class _CarbonPill extends StatelessWidget {
  final double gPerKm;

  /// Raw, full-precision `g/km` value revealed on tap (the pill itself rounds).
  final String? tooltip;

  const _CarbonPill({required this.gPerKm, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final color = CarbonThreshold.colorOf(gPerKm);
    final value = NumberFormatter.decimal(
      gPerKm,
      locale: Localizations.localeOf(context),
      noDecimal: true,
    );

    return RawValueTooltip(
      message: tooltip,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTheme.monoFont.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            'g/km',
            style: AppTheme.monoFont.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// Large monospace primary metric with the unit stacked beneath it.
class _PrimaryValue extends StatelessWidget {
  final String value;
  final String unit;

  /// Raw, full-precision base-unit value revealed on tap (null when the value
  /// is shown exactly, e.g. a plain trip count).
  final String? tooltip;

  const _PrimaryValue({required this.value, required this.unit, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RawValueTooltip(
      message: tooltip,
      child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          textAlign: TextAlign.right,
          style: AppTheme.monoFont.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        Text(
          unit,
          textAlign: TextAlign.right,
          style: AppTheme.monoFont.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
      ),
    );
  }
}
