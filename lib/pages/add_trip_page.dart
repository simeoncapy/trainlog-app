import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:step_progress/step_progress.dart';
import 'package:trainlog_app/data/controllers/trainlog_web_controller.dart';
import 'package:trainlog_app/data/models/polyline_entry.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/pages/trip_form_basics.dart';
import 'package:trainlog_app/pages/trip_form_date.dart';
import 'package:trainlog_app/pages/trip_form_details.dart';
import 'package:trainlog_app/pages/trip_form_path.dart';
import 'package:trainlog_app/providers/polyline_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/data/models/trips.dart';

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
  bool _isRouterLoading = false;
  bool _hasRoutingError = false;
  bool _isSubmitting = false;

  final PageController _pageController = PageController();
  late final TrainlogWebPageController _routingWebCtrl;

  @override
  void initState() {
    super.initState();
    _routingWebCtrl = TrainlogWebPageController();
  }

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
     _routingWebCtrl.dispose();
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

  Future<void> _validateTrip({bool continueTrip = false}) async {
    if (_isSubmitting) return; // Prevent multiple submissions
    setState(() {
      _isSubmitting = true;
    });
    final tripsProvider = Provider.of<TripsProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    debugPrint("⏳ REQUEST VALIDATION");
    // Ask the WebView to submit
    final res = await _routingWebCtrl.submitTrip(timeout: const Duration(seconds: 25));

    if (!mounted) return;
    final re = RegExp(r'\bstatus\s*:\s*(\d{3})\s*,');
    final m = re.firstMatch(res.error ?? "");
    final errorCode = m == null ? null : int.parse(m.group(1)!);

    debugPrint('submitTrip ok=${res.ok} error=$errorCode');
    debugPrint('payload runtimeType=${res.payload.runtimeType}');

    if (!res.ok) {
      final error = errorCode?.toString() ?? 'unknown'; 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.addTripFinishErrorMsg(error))),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    final Map<String, dynamic> payload = res.payload as Map<String, dynamic>;
    final Map<String, dynamic>? newTrip =
        (payload['response'] as Map<String, dynamic>?)?['newTrip']
            as Map<String, dynamic>?;
    if (newTrip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.addTripFinishFeedbackWarning)),
      );
      setState(() {
        _isSubmitting = false;
      });
      Navigator.of(context).pop(true);
      return;
    }

    // Pretty print if it's a Map/List
    // Caution: for long trips this can be very large!
    // try {
    //   final pretty = const JsonEncoder.withIndent('  ').convert(res.payload);
    //   debugPrint('payload:\n$pretty');
    // } catch (_) {
    //   // fallback (string or something non-JSON-encodable)
    //   debugPrint('Error payload:\n${res.payload}');
    // }

    // TODO: if trip is future change Trip display page to show future trips
    newTrip["uid"] = newTrip["trip_id"]; // Trips model expects "uid" field
    final path = PolylineTools.toLatLngList(newTrip["path"]);
    newTrip["path"] = PolylineTools.encodePath(path); // Store encoded path
    final trip = Trips.fromJson(newTrip);
    final isFuture = trip.utcStartDate != null && trip.utcStartDate!.isAfter(DateTime.now().toUtc());

    // Insert new trip into providers
    tripsProvider.insertTrip(trip);

    debugPrint("✅ TRIP VALIDATED"); 
    setState(() {
      _isSubmitting = false;
    });

    // Placeholder for submission logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.addTripFinishMsg)),
    );

    if(continueTrip) {
      Navigator.of(context).push(PageRouteBuilder(
        pageBuilder: (_, __, ___) => ChangeNotifierProvider(
          create: (_) => _createTripFormModel(),
          child: AddTripPage(),
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      )); // Check if the previous works
    }
    else {      
      Navigator.of(context).pop(true);
    }
  }

  TripFormModel _createTripFormModel() {
    /// Continuing the trip by using the arrivl as a new departure
    final model = context.read<TripFormModel>();
    final newModel = TripFormModel();

    newModel.vehicleType = model.vehicleType;

    newModel.departureAddress     = model.arrivalAddress;
    newModel.departureGeoMode     = model.arrivalGeoMode;
    newModel.departureLat         = model.arrivalLat;
    newModel.departureLong        = model.arrivalLong;
    newModel.departureStationName = model.arrivalStationName;

    newModel.dateType = model.dateType;
    switch(newModel.dateType) {
      case DateType.precise:
        newModel.departureDate = model.arrivalDate;
        newModel.departureDateLocal = model.arrivalDateLocal;
        break;
      case DateType.date:
        newModel.departureDayDateOnly = model.departureDayDateOnly;
        break;
      case DateType.unknown:
        newModel.isPast = model.isPast;
        break;
    }

    return newModel;
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
              onPressed: (_isRouterLoading || _hasRoutingError) ? null : _validateTrip,
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
              onPressed: (_isRouterLoading || _hasRoutingError)
                ? null
                : () => _validateTrip(continueTrip: true),
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
    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.addTripPageTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _isSubmitting ? null : _previousStepOrExit,
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.cancel),              
              onPressed: _isSubmitting
                  ? null
                  : () {
                      Navigator.pop(context);
                    },
            ),
          ],
        ),
        body: Stack(
          children: [
            // Adding trip UI
            Column(
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

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      TripFormBasics(),
                      TripFormDate(),
                      TripFormDetails(),
                      TripFormPath(
                        routingController: _routingWebCtrl,
                        onLoading: (value) {
                          if (!mounted) return;
                          setState(() => _isRouterLoading = value);
                        },
                        onRoutingError: (value) {
                          if (!mounted) return;
                          setState(() => _hasRoutingError = value);
                        },
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: _bottomButtonHelper(isLastStep),
                  ),
                ),
              ],
            ),

            // Overlay shown on top while submitting
            if (_isSubmitting) ...[
              ModalBarrier(
                dismissible: false,
                //color: Colors.black54,
                color: theme.colorScheme.surfaceContainer,
              ),
              Center(
                child: Container( // Useless container now but could be useful later
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text(
                        loc.addTripRecordingMsg,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
