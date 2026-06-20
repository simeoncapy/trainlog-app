import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:trainlog_app/app/theme/app_colors.dart';
import 'package:trainlog_app/features/ranking/ranking_type.dart';
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
              ? cs.outline.withValues(alpha: 0.25)
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
                if (_secondaryText(context) != null)
                  Text(
                    _secondaryText(context)!,
                    style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _PrimaryValue(value: _primaryValue(context), unit: _primaryUnit(context)),
        ],
      ),
    );
  }

  String _primaryValue(BuildContext context) {
    if (selection.isWorldSquares) {
      return formatNumber(context, entry.percent ?? 0);
    }
    if (sortUnit == RankingSortUnit.trips) {
      return formatCompactNumber(context, entry.trips);
    }
    return formatCompactNumber(context, entry.distanceKm);
  }

  String _primaryUnit(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (selection.isWorldSquares) return '%';
    if (sortUnit == RankingSortUnit.trips) {
      return loc.menuTripCountLabel(entry.trips);
    }
    return 'km';
  }

  String? _secondaryText(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (selection.isWorldSquares) return null;

    final date = entry.lastModified;
    final dateText = date == null
        ? null
        : DateFormat.yMMM(Localizations.localeOf(context).toString())
            .format(date);

    String metric;
    if (sortUnit == RankingSortUnit.trips) {
      metric = '${formatCompactNumber(context, entry.distanceKm)} km';
    } else {
      metric =
          '${formatNumber(context, entry.trips)} ${loc.menuTripCountLabel(entry.trips)}';
    }
    return dateText == null ? metric : '$metric · $dateText';
  }
}

/// Medal for the top three, plain number otherwise.
class _RankIndicator extends StatelessWidget {
  final int rank;

  const _RankIndicator({required this.rank});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const gold = AppColors.amber;
    const silver = Color(0xFFB8BCC4);
    const bronze = Color(0xFFCD7F45);

    if (rank >= 1 && rank <= 3) {
      final color = rank == 1
          ? gold
          : rank == 2
              ? silver
              : bronze;
      // Trophy for the winner, a medal for the runners-up.
      final icon = rank == 1 ? Icons.emoji_events : Icons.military_tech;
      return Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      );
    }

    return SizedBox(
      width: 34,
      child: Text(
        '$rank',
        textAlign: TextAlign.center,
        style: GoogleFonts.spaceMono(
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
          style: GoogleFonts.spaceMono(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        Text(
          unit,
          textAlign: TextAlign.right,
          style: GoogleFonts.spaceMono(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
