import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/services/api/trips_api.dart';
import 'package:trainlog_app/services/trip_edit_copy_service.dart';
import 'package:trainlog_app/widgets/error_banner.dart';

/// Page backing both "Edit" and "Duplicate" on a trip.
///
/// The trip is loaded through [TripEditCopyService], which reconciles the
/// locally cached copy with the server's; anything that reconciliation has to
/// report (a cache refreshed from a newer server version, a fallback on local
/// data because the server is unreachable) surfaces as an [ErrorBanner].
class EditCopyPage extends StatefulWidget {
  /// Id of the trip to edit, or of the trip to copy from.
  final int tripId;

  /// Whether the page edits [tripId] in place or seeds a new trip from it.
  final EditCopy mode;

  const EditCopyPage({
    super.key,
    required this.tripId,
    required this.mode,
  });

  @override
  State<EditCopyPage> createState() => _EditCopyPageState();
}

class _EditCopyPageState extends State<EditCopyPage> {
  bool _loading = true;
  TripEditCopyResult? _result;
  bool _warningDismissed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final trainlog = context.read<TrainlogProvider>();
    final service = TripEditCopyService(
      api: trainlog.tripsApi,
      trips: context.read<TripsProvider>(),
    );

    final result = await service.load(
      username: trainlog.username,
      tripId: widget.tripId,
      mode: widget.mode,
    );

    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  /// The banner to show for the current load outcome, or null when the data
  /// came back exactly as cached.
  ({String message, ErrorSeverity severity})? _warning(AppLocalizations loc) {
    final result = _result;
    if (result == null || _warningDismissed) return null;

    switch (result.source) {
      case TripEditCopySource.upToDate:
        return null;
      case TripEditCopySource.refreshedFromServer:
        return (
          message: loc.editCopyTripRefreshedWarning,
          severity: ErrorSeverity.warning,
        );
      case TripEditCopySource.cacheFallback:
        return (
          message: loc.editCopyServerUnreachableWarning,
          severity: ErrorSeverity.warning,
        );
      case TripEditCopySource.unavailable:
        return (
          message: loc.editCopyTripUnavailableError,
          severity: ErrorSeverity.error,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final warning = _warning(loc);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Copy'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (warning != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: ErrorBanner(
                      message: warning.message,
                      severity: warning.severity,
                      onClose: () => setState(() => _warningDismissed = true),
                    ),
                  ),
                const Expanded(
                  child: Center(
                    child: Text('This is a basic stateful widget page.'),
                  ),
                ),
              ],
            ),
    );
  }
}
