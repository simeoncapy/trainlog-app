import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/core/providers/ranking_provider.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/features/ranking/cupertino/ranking_cupertino_view.dart';
import 'package:trainlog_app/features/ranking/material/ranking_material_view.dart';
import 'package:trainlog_app/features/ranking/ranking_page_controller.dart';
import 'package:trainlog_app/ui/design.dart';

/// The Ranking (leaderboard) page: [RankingProvider] loads and sorts the
/// leaderboard, [RankingPageController] holds the search; each design draws
/// its own view.
class RankingPage extends StatelessWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) =>
              RankingProvider(ctx.read<TrainlogProvider>())..load(),
        ),
        ChangeNotifierProvider(create: (_) => RankingPageController()),
      ],
      child: PlatformView(
        material: (_) => const RankingMaterialView(),
        cupertino: (_) => const RankingCupertinoView(),
      ),
    );
  }
}
