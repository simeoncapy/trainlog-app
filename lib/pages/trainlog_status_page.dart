import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

class TrainlogStatusPage extends StatelessWidget {
  const TrainlogStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

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
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [              
              Expanded(
                child: Text("status"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
