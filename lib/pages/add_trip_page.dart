import 'package:flutter/material.dart';
import 'package:step_progress/step_progress.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

class AddTripPage extends StatefulWidget {
  const AddTripPage({super.key});

  @override
  State<AddTripPage> createState() => _AddTripPageState();
}

class _AddTripPageState extends State<AddTripPage> {
  late final StepProgressController stepProgressController;
  int currentStep = 0;
  List<String>? stepList;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialise only once when localisation and context are ready
    if (stepList == null) {
      final loc = AppLocalizations.of(context)!;
      stepList = [
        loc.addTripStepDetails,
        loc.addTripStepPath,
        loc.addTripStepValidate,
      ];

      stepProgressController = StepProgressController(
        initialStep: currentStep,
        totalSteps: stepList!.length,
      );
    }
  }

  @override
  void dispose() {
    stepProgressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.addTripPageTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          StepProgress(
            totalSteps: stepList!.length,
            currentStep: currentStep,
            controller: stepProgressController,
            nodeTitles: stepList,
            nodeIconBuilder: (index, completedStepIndex) {
              switch (index) {
                case 0:
                  return const Icon(Icons.subject);
                case 1:
                  return const Icon(Icons.route);
                case 2:
                  return const Icon(Icons.check);
                default:
                  return const Icon(Icons.help);
              }
            },
            theme: StepProgressThemeData(
              nodeLabelAlignment: StepLabelAlignment.top,
              stepLineSpacing: 2,
              stepLineStyle: const StepLineStyle(lineThickness: 2),
              defaultForegroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              activeForegroundColor: Theme.of(context).colorScheme.primary,
              stepNodeStyle: StepNodeStyle(
                iconColor: Theme.of(context).colorScheme.onSurface,
                activeIconColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('Add Trip Page'),
          ),
        ],
      ),
    );
  }
}
