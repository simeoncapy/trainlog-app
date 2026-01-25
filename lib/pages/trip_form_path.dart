import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/controllers/trainlog_web_controller.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/error_banner.dart';
import 'package:trainlog_app/widgets/shimmer_box.dart';
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

  void _showHelpBottomSheet(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.helpTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text("Bla bla bla"),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  String _distanceAndTimeFormatHelper(String input, {String? locale}) {
    final parts = input.split(', ');
    if (parts.length < 2) return input;

    // ---- distance ----
    final distanceRaw =
        parts[0].replaceAll(RegExp(r'[^\d.,]'), '').trim();

    final distance =
        NumberFormat.decimalPattern(locale).parse(distanceRaw);

    final distanceFormatted =
        NumberFormat.decimalPattern(locale).format(distance);

    // ---- duration (string-only) ----
    final durationRaw = parts.sublist(1).join(',').trim();
    final durationFormatted = _normalizeDuration(durationRaw);

    return '$distanceFormatted km, $durationFormatted';
  }

  String _normalizeDuration(String input) {
    return input
        // normalize minute unit
        .replaceAllMapped(
          RegExp(r'(\d+)\s*m\b'),
          (m) => '${m[1]}${_nbsp}min',
        )
        // day / hour / second
        .replaceAllMapped(
          RegExp(r'(\d+)\s*([dhs])\b'),
          (m) => '${m[1]}$_nbsp${m[2]}',
        );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final model = context.watch<TripFormModel>();
    final tripData = model.toJson();
    final locale = Localizations.localeOf(context);

    return Padding(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Row(
              children: [
                Checkbox(
                value: _isNewRouter,
                onChanged: (_isLoading || _hasRoutingError) ? null : (value) {
                  setState(() {
                    _isNewRouter = value ?? false;
                  });
                },
                ),
                Expanded(
                  child: Text(
                    loc.addTripPathUseNewRouter
                  )
                ),
                IconButton(
                  onPressed: () {
                    _showHelpDialog(context);
                    //_showHelpBottomSheet(context); TODO Choose the best option
                  },
                  icon: const Icon(Icons.help_outline),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                    shape: const CircleBorder(),
                  ),
                ),
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
                  child: TrainlogWebPage(
                    trainlogPage: 'routing',
                    query: {'type': model.vehicleType?.toShortString() ?? "train"},
                    initialPostForm: {'trip_data': tripData},
                    controller: widget.routingController,
                    routerToggleValue: _isNewRouter,
                    onRouteInfoChanged: (text) {
                      if (!mounted) return;
                      setState(() {
                        _routeInfo = _distanceAndTimeFormatHelper(
                          text,
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
