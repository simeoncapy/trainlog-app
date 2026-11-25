import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:provider/provider.dart';

import 'package:trainlog_app/core/providers/ranking_provider.dart';
import 'package:trainlog_app/features/ranking/ranking_metrics.dart';
import 'package:trainlog_app/features/ranking/ranking_page_controller.dart';
import 'package:trainlog_app/features/ranking/ranking_type.dart';
import 'package:trainlog_app/features/ranking/user_countries_page.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_list_view.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_medal.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_page_route.dart';
import 'package:trainlog_app/ui/tokens/app_colors.dart';
import 'package:trainlog_app/widgets/monogram.dart';

/// The leaderboard on iOS: one inset grouped card, pull to refresh. The rows
/// hold what the Android rows hold (rank or medal, monogram, username and
/// metrics, value); the user's own row is tinted amber.
class RankingListCupertino extends StatelessWidget {
  const RankingListCupertino({super.key, this.bottomInset = 0});

  /// Space kept free under the last row (search bar, tab bar).
  final double bottomInset;

  /// Corner radius of the grouped card.
  static const double _radius = 26;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<RankingProvider>();
    final page = context.watch<RankingPageController>();
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    Widget message(Widget child) => SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Center(child: child),
      ),
    );

    final rows = page.filter(provider.displayEntries);
    final me = provider.currentUsername?.toLowerCase();

    final Widget body;
    if (provider.isLoading) {
      body = message(const CupertinoActivityIndicator());
    } else if (provider.error != null) {
      body = message(
        Text('Error: ${provider.error}', style: TextStyle(color: secondary)),
      );
    } else if (rows.isEmpty) {
      body = message(Text(loc.noData, style: TextStyle(color: secondary)));
    } else {
      body = SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 12),
        sliver: SliverList.builder(
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final e = rows[i];
            // As on Android: tied rows next to each other show the rank on
            // the first one only.
            final showRank =
                i == 0 || provider.metricOf(rows[i - 1]) != provider.metricOf(e);
            return _RankingRowCupertino(
              entry: e,
              selection: provider.selection,
              sortUnit: provider.sortUnit,
              isCurrentUser: me != null && e.username.toLowerCase() == me,
              showRank: showRank,
              isFirst: i == 0,
              isLast: i == rows.length - 1,
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
        ),
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: provider.load),
        body,
      ],
    );
  }
}

class _RankingRowCupertino extends StatelessWidget {
  const _RankingRowCupertino({
    required this.entry,
    required this.selection,
    required this.sortUnit,
    required this.isCurrentUser,
    required this.showRank,
    required this.isFirst,
    required this.isLast,
    this.onTap,
  });

  final RankingDisplayEntry entry;
  final RankingSelection selection;
  final RankingSortUnit sortUnit;
  final bool isCurrentUser;
  final bool showRank;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final w = this;
    final e = w.entry;
    final text = Theme.of(context).textTheme;
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    final isCarbonPerKm =
        w.selection.type == RankingType.carbon &&
        w.sortUnit == RankingSortUnit.carbonPerKm;

    final Widget value;
    if (isCarbonPerKm) {
      value = RankingCarbonPill(
        gPerKm: e.carbonPerKmG,
        tooltip: RankingMetrics.rawTooltip(
          context,
          e,
          RankingSortUnit.carbonPerKm,
        ),
      );
    } else {
      final primary = RankingMetrics.primary(
        context,
        e,
        w.selection,
        w.sortUnit,
      );
      value = RankingPrimaryValue(
        value: primary.value,
        unit: primary.unit,
        tooltip: RankingMetrics.primaryTooltip(
          context,
          e,
          w.selection,
          w.sortUnit,
        ),
      );
    }

    final row = Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
      child: Row(
        children: [
          RankIndicator(rank: e.rank, showRank: w.showRank),
          const SizedBox(width: 10),
          Monogram(username: e.username, highlight: w.isCurrentUser),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  e.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    color: w.isCurrentUser
                        ? (isDark ? AppColors.amber : AppColors.amberDk)
                        : label,
                  ),
                ),
                ...RankingRow.supportingLines(
                  context,
                  entry: e,
                  selection: w.selection,
                  sortUnit: w.sortUnit,
                  color: secondary,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          value,
          if (w.onTap != null) ...[
            const SizedBox(width: 6),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 16,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
          ],
        ],
      ),
    );

    return RankingGroupedRow(
      isFirst: w.isFirst,
      isLast: w.isLast,
      highlighted: w.isCurrentUser,
      onTap: w.onTap,
      // Under the text, as in iOS lists.
      dividerIndent: 102,
      child: row,
    );
  }
}

/// One row of an inset grouped card drawn row by row (so the list stays lazy):
/// the card surface, rounded at the top of the first row and the bottom of
/// the last, a hairline under the others, an amber tint when [highlighted]
/// (the user's own row) and a grey one while pressed.
class RankingGroupedRow extends StatefulWidget {
  const RankingGroupedRow({
    super.key,
    required this.child,
    required this.isFirst,
    required this.isLast,
    this.highlighted = false,
    this.onTap,
    this.dividerIndent = 16,
  });

  final Widget child;
  final bool isFirst;
  final bool isLast;
  final bool highlighted;
  final VoidCallback? onTap;

  /// Where the hairline under the row starts.
  final double dividerIndent;

  @override
  State<RankingGroupedRow> createState() => _RankingGroupedRowState();
}

class _RankingGroupedRowState extends State<RankingGroupedRow> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    const corner = Radius.circular(RankingListCupertino._radius);

    var background = Theme.of(context).colorScheme.surface;
    if (w.highlighted) {
      background = Color.alphaBlend(
        AppColors.amber.withValues(alpha: isDark ? 0.18 : 0.14),
        background,
      );
    }
    if (_pressed) {
      background = Color.alphaBlend(
        CupertinoColors.systemFill.resolveFrom(context),
        background,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: w.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: ClipRSuperellipse(
        borderRadius: BorderRadius.vertical(
          top: w.isFirst ? corner : Radius.zero,
          bottom: w.isLast ? corner : Radius.zero,
        ),
        child: ColoredBox(
          color: background,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              w.child,
              if (!w.isLast)
                Padding(
                  padding: EdgeInsets.only(left: w.dividerIndent, right: 16),
                  child: Container(
                    height: 0.5,
                    color: CupertinoColors.separator.resolveFrom(context),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
