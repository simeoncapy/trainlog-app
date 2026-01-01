import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:step_progress/step_progress.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/pages/trip_form_basics.dart';
import 'package:trainlog_app/pages/trip_form_date.dart';
import 'package:trainlog_app/pages/trip_form_details.dart';
import 'package:trainlog_app/pages/trip_form_path.dart';

class AddTripPage extends StatefulWidget {
  final List<int>? preRecorderIdsToDelete;
  const AddTripPage({super.key, this.preRecorderIdsToDelete});

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

  void _showSnackBarMessage()
  {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.fillRequiredFields)),
      );
      return;
  }

  void _nextStep() {
    final model = context.read<TripFormModel>();

    bool isValid = false;

    if (currentStep == 0) isValid = model.validateBasics();
    if (currentStep == 1) isValid = model.validateDate();
    if (currentStep == 2) isValid = model.validateDetails();
    if (currentStep == 3) isValid = true; // Final step

    if (!isValid) {
      _showSnackBarMessage();
      return;
    }

    // Move to next page
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

  Widget _bottomButtonHelper(bool isLastStep)
  {
    final loc = AppLocalizations.of(context)!;

    if(isLastStep)
    {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.check, size: 24,),
              label: Text(
                loc.validateButton,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onPressed: _validateTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 3,
              ),
            ),
          ),
          SizedBox(height: 8,),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _validateTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 3,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.subdirectory_arrow_right, size: 24),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      loc.continueTripButton,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      );
    }
    else{
      return ElevatedButton.icon(
        icon: Icon(Icons.arrow_forward, size: 24,),
        label: Text(
          loc.nextButton,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        onPressed: _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 3,
        ),
      );
    }    
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isLastStep = currentStep == stepList!.length - 1;

    return SafeArea(
      child: Scaffold(
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
                  TripFormPath(),
                ],
              ),
            ),
      
            // Bottom button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: isLastStep ? _bottomButtonHelper(isLastStep) 
                    : SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: _bottomButtonHelper(isLastStep),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
