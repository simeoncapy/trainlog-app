import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/core/data/models/ranking_model.dart';
import 'package:trainlog_app/features/ranking/cupertino/rail_area_ranking_cupertino_view.dart';
import 'package:trainlog_app/features/ranking/material/rail_area_ranking_material_view.dart';
import 'package:trainlog_app/features/ranking/rail_area_ranking_controller.dart';
import 'package:trainlog_app/ui/design.dart';

/// Drill-down page for a single country or region's rail-coverage
/// leaderboard, pushed from the railway coverage list: the contenders ranked
/// by the share of the network they covered. The state lives in
/// [RailAreaRankingController]; each design has its own view.
class RailAreaRankingPage extends StatelessWidget {
  /// The area's coverage data (a country or a subdivision entry).
  final RailPercentageEntry entry;

  /// Localized area name shown as the title.
  final String displayName;

  /// Flag code (country or ISO 3166-2 subdivision) shown by the title.
  final String flagCode;

  /// The current user's login name, used to highlight their row.
  final String? currentUsername;

  const RailAreaRankingPage({
    super.key,
    required this.entry,
    required this.displayName,
    required this.flagCode,
    required this.currentUsername,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RailAreaRankingController(
        entry: entry,
        currentUsername: currentUsername,
      ),
      child: PlatformView(
        material: (_) => RailAreaRankingMaterialView(
          displayName: displayName,
          flagCode: flagCode,
        ),
        cupertino: (_) => RailAreaRankingCupertinoView(
          displayName: displayName,
          flagCode: flagCode,
        ),
      ),
    );
  }
}
