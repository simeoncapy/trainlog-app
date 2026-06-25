import 'package:flutter/material.dart';

import 'package:trainlog_app/app/theme/app_colors.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/features/ranking/widgets/flag_image.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_medal.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

/// Hero "Your position" card for the Railway Coverage feature.
///
/// Mirrors [RankingUserPositionBlock]'s inverted-background styling so it reads
/// as a strong branded element that flips with the theme. Two contexts share it:
///
///  * the country/region list, where it highlights the user's overall standing
///    and shows up to three flags of areas they lead (with a trailing ellipsis
///    when they lead more than three);
///  * the drill-down sub-page, where it shows the user's rank within that single
///    area's pool of contenders.
class RailUserPositionBlock extends StatelessWidget {
  final String username;

  /// Small line beneath the username (e.g. "Railway coverage" or
  /// "Japan railway coverage"). No subtitle is rendered when null/empty.
  final String? subtitle;

  /// The user's rank, rendered as "#N". When null an outline trophy is shown.
  final int? rank;

  /// Total contenders; rendered as "/N" after the rank when > 0.
  final int? contenders;

  /// Optional amber value shown under the rank (e.g. the user's coverage "44%").
  final String? valueText;

  /// Up to three flag codes of areas the user leads, shown under the rank.
  final List<String> ledFlagCodes;

  /// Whether the user leads more areas than [ledFlagCodes] holds (renders "…").
  final bool ledMore;

  /// Optional info line at the bottom (e.g. "You lead 3 countries · …").
  final String? infoLine;

  const RailUserPositionBlock({
    super.key,
    required this.username,
    this.subtitle,
    this.rank,
    this.contenders,
    this.valueText,
    this.ledFlagCodes = const [],
    this.ledMore = false,
    this.infoLine,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Icon(color: AppColors.amber),
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
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
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
                contenders: contenders,
                valueText: valueText,
                ledFlagCodes: ledFlagCodes,
                ledMore: ledMore,
              ),
            ],
          ),
          if (infoLine != null && infoLine!.isNotEmpty)
            _InfoLine(text: infoLine!),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int? rank;
  final int? contenders;
  final String? valueText;
  final List<String> ledFlagCodes;
  final bool ledMore;

  const _RankBadge({
    required this.rank,
    required this.contenders,
    required this.valueText,
    required this.ledFlagCodes,
    required this.ledMore,
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
                  if ((contenders ?? 0) > 0)
                    TextSpan(
                      text: '/${contenders!}',
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
          Text(
            valueText!,
            style: AppTheme.monoFont.copyWith(
              color: AppColors.amber,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (ledFlagCodes.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final code in ledFlagCodes) ...[
                FlagImage(code: code, size: 22),
                const SizedBox(width: 4),
              ],
              if (ledMore)
                Text(
                  '…',
                  style: TextStyle(
                    color: cs.onInverseSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String text;

  const _InfoLine({required this.text});

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
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: color, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _Icon extends StatelessWidget {
  final Color color;

  const _Icon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      padding: const EdgeInsets.all(13),
      child: const IconTheme(
        data: IconThemeData(color: Colors.white),
        child: Icon(Icons.percent),
      ),
    );
  }
}
