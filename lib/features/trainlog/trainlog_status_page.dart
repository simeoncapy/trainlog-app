import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_app_bar.dart';

class TrainlogStatusPage extends StatelessWidget {
  const TrainlogStatusPage({super.key});
  static String pageTitle(BuildContext context) => AppLocalizations.of(context)!.trainglogStatusPageTitle;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SafeArea(
      child: Scaffold(
        appBar: AdaptiveAppBar(
          title: loc.trainglogStatusPageTitle,
          onBack: () => Navigator.pop(context),
        ),
        body: _bodyHelper(),
      ),
    );
  }

  Padding _bodyHelper() {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [              
            Expanded(
              child: Text("I hope it's working well, because this page is really just a placeholder for Trainlog's router status. Stay tuned! 😊",
              ),
            ),
          ],
        ),
      );
  }
}
