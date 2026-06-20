import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:trainlog_app/app/theme/app_colors.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/features/ranking/ranking_type.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/ranking_provider.dart';
import 'package:trainlog_app/utils/number_formatter.dart';

/// Hero "Your position" card. Mirrors [MenuSummaryCard]'s inverted-background
/// styling ([ColorScheme.inverseSurface]) so it reads as a strong branded
/// element that flips with the theme.
class RankingUserPositionBlock extends StatelessWidget {
  final RankingProvider provider;

  const RankingUserPositionBlock({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    final entry = provider.currentUserEntry;
    final username = provider.currentUsername ?? '';

    return Container(
      decoration: BoxDecoration(
        color: cs.inverseSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _TrainlogIcon(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.rankingYourPosition.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  username.isEmpty ? '—' : username,
                  style: TextStyle(
                    color: cs.onInverseSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitle(context, loc, entry),
                  style: AppTheme.monoFont.copyWith(
                    fontSize: 12,
                    color: cs.onInverseSurface.withValues(alpha: 0.65),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _RankBadge(provider: provider, entry: entry),
        ],
      ),
    );
  }

  String _subtitle(
    BuildContext context,
    AppLocalizations loc,
    RankingDisplayEntry? entry,
  ) {
    final selection = provider.selection;
    if (entry == null) return loc.rankingNotRanked;

    if (selection.isWorldSquares) {
      return loc.rankingWorldCovered;
    }

    // The subtitle shows the metric NOT used as the primary value, so the two
    // complement each other as the selected unit changes.
    final locale = Localizations.localeOf(context);
    if (provider.sortUnit == RankingSortUnit.trips) {
      return NumberFormatter.compact(
        entry.distanceKm,
        locale: locale,
        unitsByFactor: MeasurementUnit.distance.unitsByFactor(loc),
      );
    }
    return '${NumberFormatter.decimal(entry.trips, locale: locale)} ${loc.menuTripCountLabel(entry.trips)}';
  }
}

/// Right-hand rank + value badge (#1 with a trophy, value beneath in amber).
class _RankBadge extends StatelessWidget {
  final RankingProvider provider;
  final RankingDisplayEntry? entry;

  const _RankBadge({required this.provider, required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final entry = this.entry;
    final loc = AppLocalizations.of(context)!;
    if (entry == null) {
      return Icon(
        Icons.emoji_events_outlined,
        color: cs.onInverseSurface.withValues(alpha: 0.4),
        size: 32,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.rank >= 1 && entry.rank <= 3) ...[
              Icon(
                // Trophy for the winner, a medal for the runners-up.
                entry.rank == 1 ? Icons.emoji_events : Icons.military_tech,
                color: entry.rank == 1
                    ? AppColors.amber
                    : entry.rank == 2
                        ? const Color(0xFFB8BCC4)
                        : const Color(0xFFCD7F45),
                size: 22,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              loc.rankingPositionValue(entry.rank),
              style: AppTheme.monoFont.copyWith(
                color: cs.onInverseSurface,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          _value(context),
          style: AppTheme.monoFont.copyWith(
            color: AppColors.amber,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _value(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final selection = provider.selection;
    if (selection.isWorldSquares) {
      return NumberFormatter.percent(entry!.percent ?? 0, locale: locale);
    }
    if (provider.sortUnit == RankingSortUnit.trips) {
      return '${NumberFormatter.decimal(entry!.trips, locale: locale)} ${loc.menuTripCountLabel(entry!.trips)}';
    }
    return NumberFormatter.compact(
      entry!.distanceKm,
      locale: locale,
      unitsByFactor: MeasurementUnit.distance.unitsByFactor(loc),
    );
  }
}

/// Branded amber→navy→amber icon, identical to the one used by
/// [MenuSummaryCard].
class _TrainlogIcon extends StatelessWidget {
  const _TrainlogIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.amber,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(5),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.navy,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(8),
        child: SvgPicture.asset(
          'assets/icon/trainlog_icon_foreground_only.svg',
          colorFilter:
              const ColorFilter.mode(AppColors.amber, BlendMode.srcIn),
        ),
      ),
    );
  }
}
