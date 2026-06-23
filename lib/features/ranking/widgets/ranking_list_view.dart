import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:trainlog_app/app/theme/app_colors.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/features/ranking/ranking_metrics.dart';
import 'package:trainlog_app/features/ranking/ranking_type.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_medal.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/ranking_provider.dart';
import 'package:trainlog_app/utils/number_formatter.dart';

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
        return RankingRow(
          entry: e,
          selection: provider.selection,
          sortUnit: provider.sortUnit,
          isCurrentUser: me != null && e.username.toLowerCase() == me,
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

  const RankingRow({
    super.key,
    required this.entry,
    required this.selection,
    required this.sortUnit,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
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
          _RankIndicator(rank: entry.rank),
          const SizedBox(width: 10),
          _Monogram(username: entry.username, highlight: isCurrentUser),
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
                if (_secondaryMetric(context) != null)
                  Text(
                    _secondaryMetric(context)!,
                    style: AppTheme.monoFont.copyWith(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                if (_lastConnection(context) != null)
                  Text(
                    _lastConnection(context)!,
                    style: AppTheme.monoFont.copyWith(
                      fontSize: 11,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // CO2e/km is rendered as a coloured threshold pill; everything else
          // as the large value + stacked unit.
          if (_isCarbon && sortUnit == RankingSortUnit.carbonPerKm)
            _CarbonPill(gPerKm: entry.carbonPerKmG)
          else
            Builder(builder: (context) {
              final primary = _primary(context);
              return _PrimaryValue(value: primary.value, unit: primary.unit);
            }),
        ],
      ),
    );
  }

  bool get _isCarbon => selection.type == RankingType.carbon;

  /// Primary value + unit (CO2e/km handled by [_CarbonPill] in the row).
  CompactNumber _primary(BuildContext context) =>
      RankingMetrics.primary(context, entry, selection, sortUnit);

  /// Secondary supporting metric (first non-primary value).
  String? _secondaryMetric(BuildContext context) {
    final secondaries =
        RankingMetrics.secondaries(context, entry, selection, sortUnit);
    return secondaries.isEmpty ? null : secondaries.first;
  }

  /// Third line: the second carbon metric for carbon (two secondaries),
  /// otherwise the last connection (last activity).
  String? _lastConnection(BuildContext context) {
    final secondaries =
        RankingMetrics.secondaries(context, entry, selection, sortUnit);
    if (secondaries.length >= 2) return secondaries.last;
    final date = entry.lastModified;
    if (date == null) return null;
    return DateFormat.yMMM(Localizations.localeOf(context).toString())
        .format(date);
  }
}

/// Medal for the top three, plain number otherwise.
class _RankIndicator extends StatelessWidget {
  final int rank;

  const _RankIndicator({required this.rank});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (RankingMedal.isMedal(rank)) {
      return Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: RankingMedal.colorOf(rank).withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: RankingMedal(rank: rank, size: 18),
      );
    }

    return SizedBox(
      width: 34,
      child: Text(
        '$rank',
        textAlign: TextAlign.center,
        style: AppTheme.monoFont.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Text-monogram avatar placeholder (first letter, colour derived from name).
class _Monogram extends StatelessWidget {
  final String username;
  final bool highlight;

  const _Monogram({required this.username, required this.highlight});

  static const _palette = <Color>[
    AppColors.blue,
    AppColors.modeBus,
    AppColors.modeTram,
    AppColors.modeAir,
    AppColors.modeFerry,
    AppColors.violet,
    AppColors.amberDk,
  ];

  @override
  Widget build(BuildContext context) {
    final letter =
        username.isEmpty ? '?' : username.substring(0, 1).toUpperCase();
    final color = _palette[username.hashCode.abs() % _palette.length];

    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: highlight
            ? Border.all(color: AppColors.amber, width: 2)
            : null,
      ),
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// CO2e/km value shown as a coloured threshold pill (green / amber / red),
/// matching the design. Colour comes from [CarbonThreshold].
class _CarbonPill extends StatelessWidget {
  final double gPerKm;

  const _CarbonPill({required this.gPerKm});

  @override
  Widget build(BuildContext context) {
    final color = CarbonThreshold.colorOf(gPerKm);
    final value = NumberFormatter.decimal(
      gPerKm,
      locale: Localizations.localeOf(context),
      noDecimal: true,
    );

    return Container(
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
    );
  }
}

/// Large monospace primary metric with the unit stacked beneath it.
class _PrimaryValue extends StatelessWidget {
  final String value;
  final String unit;

  const _PrimaryValue({required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
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
    );
  }
}
