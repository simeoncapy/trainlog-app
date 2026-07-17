import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:trainlog_app/data/controllers/trainlog_web_controller.dart';
import 'package:trainlog_app/data/models/polyline_entry.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/features/trips_add/add_trip_wizard_step.dart';
import 'package:trainlog_app/features/trips_add/steps/add_trip_operator_step.dart';
import 'package:trainlog_app/features/trips_add/steps/add_trip_route_step.dart';
import 'package:trainlog_app/features/trips_add/steps/add_trip_vehicle_type_step.dart';
import 'package:trainlog_app/features/trips_add/trip_form_date.dart';
import 'package:trainlog_app/features/trips_add/trip_form_details.dart';
import 'package:trainlog_app/features/trips_add/trip_form_path.dart';
import 'package:trainlog_app/features/trips_add/widgets/wizard_step_indicator.dart';
import 'package:trainlog_app/platform/widget/adaptive_app_bar_square_button.dart';
import 'package:trainlog_app/widgets/primary_action_button.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/services/pre_record_service.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/data/models/trips.dart';

/// Main layout controller of the multi-step "Add Trip" wizard.
///
/// Sub-pages are declared sequentially in [_steps]; the total step count and
/// the progress indicator are derived from that list, so the layout adapts
/// dynamically whenever steps are added or removed.
class AddTripWizardPage extends StatefulWidget {
  final List<int>? preRecorderIdsToDelete;
  const AddTripWizardPage({super.key, this.preRecorderIdsToDelete});

  @override
  State<AddTripWizardPage> createState() => _AddTripWizardPageState();
}

class _AddTripWizardPageState extends State<AddTripWizardPage> {
  int _currentStep = 0;
  bool _isRouterLoading = false;
  bool _hasRoutingError = false;
  bool _isSubmitting = false;

  final PageController _pageController = PageController();
  late final TrainlogWebPageController _routingWebCtrl;

  /// Ordered list of the wizard sub-pages. The step count shown by the
  /// progress indicator always matches the length of this list.
  late final List<AddTripWizardStep> _steps;

  int get _totalSteps => _steps.length;
  bool get _isLastStep => _currentStep == _totalSteps - 1;

  @override
  void initState() {
    super.initState();
    _routingWebCtrl = TrainlogWebPageController();

    _steps = [
      AddTripWizardStep(
        builder: (_) => const AddTripVehicleTypeStep(),
        validate: (model) => model.vehicleType != null,
      ),
      AddTripWizardStep(
        builder: (_) => const AddTripRouteStep(),
        validate: (model) => model.validateBasics(),
      ),
      AddTripWizardStep(
        builder: (_) => const AddTripOperatorStep(),
        // Operators are optional — the step never blocks progression.
        canSkip: true,
      ),
      AddTripWizardStep(
        builder: (_) => const TripFormDate(),
        validate: (model) => model.validateDate(),
      ),
      AddTripWizardStep(
        builder: (_) => const TripFormDetails(),
        validate: (model) => model.validateDetails(),
      ),
      AddTripWizardStep(
        builder: (_) => TripFormPath(
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
      ),
    ];
  }

  @override
  void dispose() {
    _routingWebCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _showSnackBarMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.fillRequiredFields)),
    );
  }

  void _nextStep() {
    final model = context.read<TripFormModel>();

    final isValid = _steps[_currentStep].validate?.call(model) ?? true;
    if (!isValid) {
      _showSnackBarMessage();
      return;
    }

    if (!_isLastStep) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _validateTrip();
    }
  }

  void _previousStepOrExit() async {
    final model = context.read<TripFormModel>();
    if (_currentStep == 0) {
      if (!model.hasBeenChanged) {
        Navigator.pop(context);
        return;
      }
      final bool? confirmed = await _showExitConfirmationDialog(context);
      if (context.mounted) {
        if (confirmed == true) Navigator.pop(context);
      }
    } else {
      setState(() {
        _currentStep--;
        _hasRoutingError = false; // Reset routing error when going back
        _isRouterLoading = false; // Reset loading state when going back
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _cancelWizard() async {
    final model = context.read<TripFormModel>();
    if (!model.hasBeenChanged) {
      Navigator.pop(context);
      return;
    }
    final bool? confirmed = await _showExitConfirmationDialog(context);
    if (context.mounted) {
      if (confirmed == true) Navigator.pop(context);
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
    final Map<String, dynamic>? newTrip = payload['newTrip'] as Map<String, dynamic>?;
    if (newTrip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.addTripFinishFeedbackWarning)),
      );
      if(widget.preRecorderIdsToDelete != null) await const PreRecordService().deleteByIds(widget.preRecorderIdsToDelete!);
      setState(() {
        _isSubmitting = false;
      });
      Navigator.of(context).pop(true);
      return;
    }

    // TODO: if trip is future change Trip display page to show future trips
    newTrip["uid"] = newTrip["trip_id"]; // Trips model expects "uid" field
    final model = context.read<TripFormModel>();
    if(model.dateType == DateType.unknown){
       // For unknown date, set start/end_datetime to -1 for past trips and 1 for future trips (Trips.fromJson will interpret this correctly)
      newTrip["start_datetime"] = model.isPast ? "-1" : "1";
      newTrip["end_datetime"] = model.isPast ? "-1" : "1";
    }

    final path = PolylineTools.toLatLngList(newTrip["path"]);
    newTrip["path"] = PolylineTools.encodePath(path); // Store encoded path
    final trip = Trips.fromJson(newTrip);

    // Insert new trip into providers
    tripsProvider.insertTrip(trip);

    debugPrint("✅ TRIP VALIDATED");
    setState(() {
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.addTripFinishMsg)),
    );

    if(widget.preRecorderIdsToDelete != null) await const PreRecordService().deleteByIds(widget.preRecorderIdsToDelete!);

    if(!context.mounted) return;
    if(continueTrip) {
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, __, ___) => ChangeNotifierProvider(
          create: (_) => _createTripFormModel(model: model),
          child: const AddTripWizardPage(),
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ));
    }
    else {
      Navigator.of(context).pop(true);
    }
  }

  TripFormModel _createTripFormModel({required TripFormModel model}) {
    /// Continuing the trip by using the arrival as a new departure
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

    newModel.initState(); // Toggle hasBeenModified
    return newModel;
  }

  Widget _stickyFooter() {
    final loc = AppLocalizations.of(context)!;

    if (_isLastStep) {
      return Column(
        children: [
          PrimaryActionButton(
            icon: Icons.check,
            label: loc.validateButton,
            onPressed:
                (_isRouterLoading || _hasRoutingError) ? null : _validateTrip,
          ),
          const SizedBox(height: 8),
          PrimaryActionButton(
            icon: Icons.subdirectory_arrow_right,
            label: loc.continueTripButton,
            variant: PrimaryActionButtonVariant.outlined,
            onPressed: (_isRouterLoading || _hasRoutingError)
                ? null
                : () => _validateTrip(continueTrip: true),
          ),
        ],
      );
    }

    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Optional-step hint: skipping is redundant with Continue (which
        // already progresses without input) but makes it explicit.
        if (_steps[_currentStep].canSkip) ...[
          TextButton(
            onPressed: _skipStep,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              loc.addTripSkipButton,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
        PrimaryActionButton(
          label: loc.continueButton,
          onPressed: _nextStep,
        ),
      ],
    );
  }

  /// Advances to the next step without validating the current one.
  void _skipStep() {
    if (_isLastStep) return;
    setState(() => _currentStep++);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<bool?> _showExitConfirmationDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(loc.addTripExitConfirmationDialogueTitle),
          content: Text(loc.addTripExitConfirmationDialogueContent),
          actions: <Widget>[
            // The "Cancel" button
            TextButton(
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            // The "CONFIRM" button
            TextButton(
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: WizardStepIndicator(
                    currentStep: _currentStep,
                    totalSteps: _totalSteps,
                    leading: AdaptiveAppBarSquareButton(
                      icon: Icons.chevron_left,
                      iconSize: 24,
                      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                      onPressed: () {
                        if (_isSubmitting) return;
                        _previousStepOrExit();
                      },
                    ),
                    trailing: AdaptiveAppBarSquareButton(
                      icon: Icons.close,
                      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                      onPressed: () {
                        if (_isSubmitting) return;
                        _cancelWizard();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final step in _steps) step.builder(context),
                    ],
                  ),
                ),

                // Sticky footer with the page progression button(s)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: _stickyFooter(),
                ),
              ],
            ),

            // Overlay shown on top while submitting
            if (_isSubmitting) ...[
              ModalBarrier(
                dismissible: false,
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
                      Expanded(child: Lottie.asset('assets/animations/new_trip_cropped.json')),
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
