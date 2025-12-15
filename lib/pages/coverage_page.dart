import 'package:flutter/material.dart';
import 'package:trainlog_app/widgets/dismissible_error_banner_block.dart';
import 'package:trainlog_app/widgets/error_banner.dart';
import 'package:trainlog_app/widgets/trainlog_web_page.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

class CoveragePage extends StatelessWidget {
  const CoveragePage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      children: [
        DismissibleErrorBannerBlock(
          message: loc.pageNotImplementedYet,
          severity: ErrorSeverity.warning,
        ),
        Expanded(
          child: TrainlogWebPage(
            trainlogPage: "dashboard",
          ),
        ),
      ],
    );
  }
}
