import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

class TrainlogStatusPage extends StatelessWidget {
  const TrainlogStatusPage({super.key});
  static String pageTitle(BuildContext context) => AppLocalizations.of(context)!.trainglogStatusPageTitle;

  @override
  Widget build(BuildContext context) {
    // The surrounding app bar (and back button) is provided by the shell, the
    // same way it is for the other pages — see material/cupertino shell.
    return _bodyHelper();
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
