import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/controllers/trainlog_web_controller.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/widgets/error_banner.dart';
import 'package:trainlog_app/widgets/shimmer_box.dart';
import 'package:trainlog_app/widgets/trainlog_router_page.dart';
import 'package:trainlog_app/widgets/trainlog_web_page.dart';


class TripFormPath extends StatefulWidget {
  final TrainlogWebPageController routingController;
  final ValueChanged<bool>? onLoading;
  final ValueChanged<bool>? onRoutingError;

  const TripFormPath({
    super.key,
    required this.routingController,
    this.onLoading,
    this.onRoutingError,
  });

  @override
  State<TripFormPath> createState() => _TripFormPathState();
}

class _TripFormPathState extends State<TripFormPath> {
  bool _isNewRouter = false;
  String _routeInfo = "";
  static const _nbsp = '\u00A0'; // non-breaking space
  bool _isLoading = false;
  bool _hasRoutingError = false;

  @override
  void initState() {
    super.initState();

    //final model = context.read<TripFormModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  void _showHelpDialog(BuildContext context) {
  final loc = AppLocalizations.of(context)!;

  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.helpTitle),
          content: SingleChildScrollView(
            child: Text(
              loc.addTripPathHelp,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(MaterialLocalizations.of(context).closeButtonLabel),
            ),
          ],
        );
      },
    );
  }

  String _distanceAndTimeFormatHelper(double distanceM, double durationS, {String? locale}) {
    final distanceFormatted =
      NumberFormat('#,##0.0', locale).format(distanceM / 1000);
    final durationFormatted = formatDurationFixed(Duration(seconds: durationS.toInt()));

    return '$distanceFormatted${_nbsp}km, $durationFormatted';
  }

  List<Widget> _mapCommandHelper(VehicleType vehicleType, bool disabled, AppLocalizations loc) {
    switch (vehicleType) {
      case VehicleType.train:        
      case VehicleType.metro:
      case VehicleType.tram:
        return [
          Opacity(
            opacity: disabled ? 0.2 : 1.0,
            child: Checkbox(
              value: _isNewRouter,
              onChanged: disabled
                  ? null
                  : (value) => setState(() => _isNewRouter = value ?? false),
            ),
          ),
          Expanded(
            child: Opacity(
              opacity: disabled ? 0.2 : 1.0,
              child: Text(
                loc.addTripPathUseNewRouter
              ),
            )
          ),
          IconButton(
            onPressed: () {
              _showHelpDialog(context);
            },
            icon: const Icon(Icons.help_outline),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
              shape: const CircleBorder(),
            ),
          ),
        ];
      case VehicleType.plane:
      case VehicleType.helicopter:
        return [SizedBox.shrink()]; // TODO: Put FR24 options here
      default:
        return [SizedBox.shrink()];
    }

  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final model = context.watch<TripFormModel>();
    final tripData = model.toJson();
    final locale = Localizations.localeOf(context);
    final disabled = _isLoading || _hasRoutingError;

    return Padding(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Row(
              children: [
                ..._mapCommandHelper(model.vehicleType ?? VehicleType.train, disabled, loc),
              ],
            ),
          ),
          SizedBox(height: 8,),
          Padding(
            padding: EdgeInsets.only(left: 8.0, right: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    loc.addTripNameEnd(model.departureStationName!, model.arrivalStationName!),
                    maxLines: 2,
                  )
                ),
                _routeInfo.isEmpty ? ShimmerBox(width: 50, height: 18) 
                  : Text("($_routeInfo)")
              ],
            ),
          ),
          SizedBox(height: 8,),
          Expanded(
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned.fill(
                  child: TrainlogRouterPage (
                    tripData: tripData,
                    vehicleType: model.vehicleType ?? VehicleType.train,
                    isNewRouter: _isNewRouter,
                    controller: widget.routingController,
                    onRouteInfoChanged: (tripData) {
                      if (!mounted) return;
                      setState(() {
                        debugPrint("${tripData.distanceM} m, ${tripData.durationS} s");
                        _routeInfo = _distanceAndTimeFormatHelper(
                          tripData.distanceM ?? 0,
                          tripData.durationS ?? 0,
                          locale: locale.toLanguageTag(),
                        );                        
                      });
                    },
                    onLoading: (value) {
                      if (!mounted) return;
                      setState(() {
                        _isLoading = value;
                      });
                      widget.onLoading?.call(_isLoading);
                    },
                    onRoutingError: (value) {
                      setState(() {
                        _hasRoutingError = value;
                      });
                      widget.onRoutingError?.call(_hasRoutingError);
                    },
                  ),
                ),

                if(_hasRoutingError)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ErrorBanner(
                      message:  loc.addTripPathRoutingErrorBannerMessage,
                      severity: ErrorSeverity.error,
                      compact: false,
                    ),
                  ),

                // Overlay spinner above the web page
                if (_isLoading)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true, // allow interaction with the web page while spinner shows
                      child: Container(
                        color: Colors.black26, // optional dim background; remove if you don't want it
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
