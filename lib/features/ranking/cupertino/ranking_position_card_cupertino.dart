import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:provider/provider.dart';

import 'package:trainlog_app/core/providers/ranking_provider.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/features/ranking/ranking_type.dart';
import 'package:trainlog_app/features/ranking/user_countries_page.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_medal.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_position_info.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_user_position_block.dart';
import 'package:trainlog_app/features/ranking/widgets/raw_value_tooltip.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_page_route.dart';
import 'package:trainlog_app/ui/tokens/app_colors.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/text_utils.dart';

/// "Your position" on iOS: the same content as the Android card (category
/// disc, username, complementary metrics, rank over the participant count,
/// primary value), on the grouped list's card surface instead of the
/// inverted one. The carbon note and the visited countries show beneath.
class RankingPositionCardCupertino extends StatelessWidget {
  const RankingPositionCardCupertino({super.key});

  static const double _radius = 26;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<RankingProvider>();
    final info = RankingPositionInfo.of(context, provider);
    final entry = provider.currentUserEntry;
    final selection = provider.selection;
    final palette = MapColorPaletteHelper.getPalette(
      context.watch<SettingsProvider>().mapColorPalette,
    );
    final text = Theme.of(context).textTheme;
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    // The pressed amber reads better on the light card.
    final amber = isDark ? AppColors.amber : AppColors.amberDk;

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox.square(
                  dimension: 48,
                  child: RankingPositionIcon(
                    icon: selection.icon,
                    color: selection.accentColor(palette),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loc.rankingYourPosition,
                        style: AppTheme.displayFont.copyWith(
                          fontSize: text.labelMedium?.fontSize,
                          color: amber,
                        ),
                      ),
                      Text(
                        provider.currentUsername ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: label,
                          letterSpacing: 0,
                        ),
                      ),
                      if (info.subtitle.isNotEmpty)
                        Text(
                          info.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.monoFont.copyWith(
                            fontSize: text.labelSmall?.fontSize,
                            color: secondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _Rank(
                  rank: entry?.rank,
                  participantCount: provider.participantCount,
                  valueText: info.valueText,
                  valueTooltip: info.valueTooltip,
                  amber: amber,
                ),
              ],
            ),
            if (info.explanation != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      CupertinoIcons.info_circle,
                      size: 16,
                      color: secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      info.explanation!,
                      style: text.bodySmall?.copyWith(
                        color: secondary,
                        height: 1.3,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (entry != null && info.countryCodes.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => AdaptivePageRoute.push(
                  context,
                  (_) => UserCountriesPage(
                    username: entry.username,
                    countryCodes: info.countryCodes,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        info.countryCodes.map(countryCodeToEmoji).join(' '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: text.titleMedium?.fontSize,
                          height: 1.5,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      CupertinoIcons.chevron_forward,
                      size: 16,
                      color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The rank, large, over the participant count, with the primary value in
/// amber beneath (an outline trophy when the user is not ranked).
class _Rank extends StatelessWidget {
  const _Rank({
    required this.rank,
    required this.participantCount,
    required this.valueText,
    required this.valueTooltip,
    required this.amber,
  });

  final int? rank;
  final int participantCount;
  final String? valueText;
  final String? valueTooltip;
  final Color amber;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final rank = this.rank;

    if (rank == null) {
      return Icon(
        CupertinoIcons.rosette,
        size: 30,
        color: CupertinoColors.tertiaryLabel.resolveFrom(context),
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
                  fontSize: text.headlineMedium?.fontSize,
                  fontWeight: FontWeight.w700,
                  color: label,
                ),
                children: [
                  if (participantCount > 0)
                    TextSpan(
                      text: '/$participantCount',
                      style: AppTheme.monoFont.copyWith(
                        fontSize: text.bodyMedium?.fontSize,
                        color: secondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (valueText != null)
          RawValueTooltip(
            message: valueTooltip,
            child: Text(
              valueText!,
              style: AppTheme.monoFont.copyWith(
                fontSize: text.bodyMedium?.fontSize,
                fontWeight: FontWeight.w700,
                color: amber,
              ),
            ),
          ),
      ],
    );
  }
}
