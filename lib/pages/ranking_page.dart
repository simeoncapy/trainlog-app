import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/dismissible_error_banner_block.dart';
import 'package:trainlog_app/widgets/error_banner.dart';
import 'package:trainlog_app/widgets/trainlog_web_page.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage>
    with SingleTickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      children: [
        DismissibleErrorBannerBlock(
          message: loc.pageNotImplementedYet,
          severity: ErrorSeverity.warning,
          padding: EdgeInsets.only(
            left: 80,
            top: 12,
            right: 8,
            bottom: 12,
          ),
          collapsedHeight: 80,
        ),
        Expanded(
          child: TrainlogWebPage(
            trainlogPage: "leaderboard",
            publicPage: true,
          ),
        ),
      ],
    );
  }
}
