import 'package:flutter/material.dart';
import 'package:step_progress/step_progress.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/trip_form_basics.dart';
import 'package:trainlog_app/widgets/trip_form_date.dart';
import 'package:trainlog_app/widgets/trip_form_details.dart';

class AddTripPage extends StatefulWidget {
  const AddTripPage({super.key});

  @override
  State<AddTripPage> createState() => _AddTripPageState();
}

class _AddTripPageState extends State<AddTripPage> {
  late final StepProgressController stepProgressController;
  int currentStep = 0;
  List<String>? stepList;

  final PageController _pageController = PageController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialise only once when localisation and context are ready
    if (stepList == null) {
      final loc = AppLocalizations.of(context)!;
      stepList = [
        loc.addTripStepBasics,
        loc.addTripStepDate,
        loc.addTripStepDetails,
        loc.addTripStepPath,
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
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (currentStep < stepList!.length - 1) {
      setState(() => currentStep++);
      stepProgressController.nextStep();
      _pageController.animateToPage(
        currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _validateTrip();
    }
  }

  void _previousStepOrExit() {
    if (currentStep == 0) {
      Navigator.pop(context);
    } else {
      setState(() => currentStep--);
      stepProgressController.previousStep();
      _pageController.animateToPage(
        currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _validateTrip() {
    // Placeholder for submission logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip validated! (not implemented yet)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isLastStep = currentStep == stepList!.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.addTripPageTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousStepOrExit,
        ),
      ),
      body: Column(
        children: [
          StepProgress(
            totalSteps: stepList!.length,
            currentStep: currentStep,
            controller: stepProgressController,
            nodeTitles: stepList,
            nodeIconBuilder: (index, _) {
              switch (index) {
                case 0:
                  return const Icon(Icons.info);
                case 1:
                  return const Icon(Icons.date_range);
                case 2:
                  return const Icon(Icons.subject);
                case 3:
                  return const Icon(Icons.route);
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

          // Step content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                TripFormBasics(),
                TripFormDate(),
                TripFormDetails(),
                Center(child: Text("Path placeholder page")),
              ],
            ),
          ),

          // Bottom button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              height: 40, // makes it taller
              child: ElevatedButton.icon(
                icon: Icon(
                  isLastStep ? Icons.check : Icons.arrow_forward,
                  size: 24,
                ),
                label: Text(
                  isLastStep ? loc.validateButton : loc.nextButton,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLastStep
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondaryContainer,
                  foregroundColor: isLastStep
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSecondaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
