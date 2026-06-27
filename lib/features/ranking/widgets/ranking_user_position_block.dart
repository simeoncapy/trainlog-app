import 'package:flutter/material.dart';

import 'package:trainlog_app/app/theme/app_colors.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_medal.dart';
import 'package:trainlog_app/features/ranking/widgets/raw_value_tooltip.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

/// Hero "Your position" card. Mirrors [MenuSummaryCard]'s inverted-background
/// styling ([ColorScheme.inverseSurface]) so it reads as a strong branded
/// element that flips with the theme.
///
/// Presentational only — callers supply the already-resolved pieces (leading
/// [icon], [username], [subtitle], [rank]/[participantCount] and the optional
/// amber [valueText]), so the same card serves the main leaderboard and the
/// railway-coverage drill-down page.
class RankingUserPositionBlock extends StatelessWidget {
  /// Leading circular icon (e.g. a [RankingPositionIcon]).
  final Widget icon;

  final String username;

  /// Line beneath the username (the complementary metrics, or an area name).
  final String subtitle;

  /// The user's rank, rendered as "#N". When null an outline trophy is shown.
  final int? rank;

  /// Total participants; rendered as "/N" after the rank when > 0.
  final int participantCount;

  /// Amber value shown under the rank (e.g. the primary metric or "44%").
  final String? valueText;

  /// Optional raw-value tooltip revealed on tapping [valueText].
  final String? valueTooltip;

  /// When set, an info banner with this text is shown beneath the row (used by
  /// the carbon leaderboard to explain that lower g/km ranks better).
  final String? carbonExplanation;

  const RankingUserPositionBlock({
    super.key,
    required this.icon,
    required this.username,
    required this.subtitle,
    required this.rank,
    this.participantCount = 0,
    this.valueText,
    this.valueTooltip,
    this.carbonExplanation,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: cs.inverseSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.rankingYourPosition.toUpperCase(),
                      style: const TextStyle(
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
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTheme.monoFont.copyWith(
                          fontSize: 12,
                          color: cs.onInverseSurface.withValues(alpha: 0.65),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _RankBadge(
                rank: rank,
                participantCount: participantCount,
                valueText: valueText,
                valueTooltip: valueTooltip,
              ),
            ],
          ),
          if (carbonExplanation != null)
            _CarbonExplanation(text: carbonExplanation!),
        ],
      ),
    );
  }
}

/// Info banner explaining that lower CO2e/km ranks better.
class _CarbonExplanation extends StatelessWidget {
  final String text;

  const _CarbonExplanation({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = cs.onInverseSurface.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    height: 1.3,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Right-hand rank + value badge (#1 with a trophy, value beneath in amber).
class _RankBadge extends StatelessWidget {
  final int? rank;
  final int participantCount;
  final String? valueText;
  final String? valueTooltip;

  const _RankBadge({
    required this.rank,
    required this.participantCount,
    required this.valueText,
    required this.valueTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    final rank = this.rank;

    if (rank == null) {
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
            if (RankingMedal.isMedal(rank)) ...[
              RankingMedal(rank: rank, size: 22),
              const SizedBox(width: 4),
            ],
            Text.rich(
              TextSpan(
                text: loc.rankingPositionValue(rank),
                style: AppTheme.monoFont.copyWith(
                  color: cs.onInverseSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
                children: [
                  if (participantCount > 0)
                    TextSpan(
                      text: '/$participantCount',
                      style: AppTheme.monoFont.copyWith(
                        color: cs.onInverseSurface.withValues(alpha: 0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (valueText != null) ...[
          const SizedBox(height: 2),
          RawValueTooltip(
            message: valueTooltip,
            child: Text(
              valueText!,
              style: AppTheme.monoFont.copyWith(
                color: AppColors.amber,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The leading circular icon of [RankingUserPositionBlock]: a coloured disc with
/// a white [icon] centred inside.
class RankingPositionIcon extends StatelessWidget {
  final Widget icon;
  final Color color;

  const RankingPositionIcon({
    super.key,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      padding: const EdgeInsets.all(13),
      child: IconTheme(
        data: const IconThemeData(color: Colors.white),
        child: icon,
      ),
    );
  }
}
