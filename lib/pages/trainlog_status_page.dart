import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

class TrainlogStatusPage extends StatelessWidget {
  const TrainlogStatusPage({super.key});
  static String pageTitle(BuildContext context) => AppLocalizations.of(context)!.trainglogStatusPageTitle;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if(AppPlatform.isApple) {
      return _bodyHelper();
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.trainglogStatusPageTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
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
              child: Text("status"),
            ),
          ],
        ),
      );
  }
}
