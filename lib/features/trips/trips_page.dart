import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/features/trips/cupertino/trips_page_cupertino_view.dart';
import 'package:trainlog_app/features/trips/material/trips_page_material_view.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/trips_search_filter_sheet.dart';
import 'package:trainlog_app/features/trips/trips_page_controller.dart';
import 'package:trainlog_app/features/trips_add/open_add_trip_wizard.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/core/providers/trips_provider.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_information_message.dart';

/// What the trips page views can ask the page for.
class TripsPageActions {
  const TripsPageActions({
    required this.onPrimaryActionsReady,
    required this.openFilter,
    required this.refreshKey,
    required this.onRefresh,
    required this.addTripAction,
  });

  /// Hands the shell the actions of its bar.
  final SetPrimaryActions onPrimaryActionsReady;

  /// Opens the search & filter sheet.
  final VoidCallback openFilter;

  /// Key of the pull-to-refresh indicator (F5 on desktop shows it).
  final GlobalKey<RefreshIndicatorState> refreshKey;

  /// Pull to refresh: syncs the trips.
  final Future<void> Function() onRefresh;

  /// The "New trip" action, first in the shell's bar on both designs.
  final AppPrimaryAction Function() addTripAction;
}

/// Trips page entry: holds the [TripsPageController], opens the filter
/// sheet and the add-trip wizard, then picks the Material or iOS view.
class TripsPage extends StatefulWidget {
  final SetPrimaryActions onPrimaryActionsReady;
  const TripsPage({super.key, required this.onPrimaryActionsReady});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  final _controller = TripsPageController();

  // F5 refresh on desktop, where the pull-to-refresh gesture isn't available.
  static final bool _isDesktop =
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  // Whether this page is what the user sees: the shells keep hidden tabs
  // alive, and another page may be pushed on top.
  bool _isShown = true;
  int _seenRevision = -1;

  @override
  void initState() {
    super.initState();
    _controller.loadPrefs();
    if (_isDesktop) HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    if (_isDesktop) HardwareKeyboard.instance.removeHandler(_onKey);
    _controller.dispose();
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.f5) {
      return false;
    }
    if (!mounted || !_isShown) return false;
    // Same as pulling down: shows the spinner and runs onRefresh.
    _refreshKey.currentState?.show();
    return true;
  }

  Future<void> _openFilter() async {
    final tripsProvider = context.read<TripsProvider>();
    final repo = tripsProvider.repository;
    if (repo == null) return;
    final locale = Localizations.localeOf(context);
    final countries = await tripsProvider.getMapCountryCodesSafe(
      locale: locale,
    );
    final types = tripsProvider.vehicleTypes;

    if (!mounted) return;
    final result = await showTripsSearchFilterSheet(
      context,
      repo: repo,
      countryOptions: countries,
      typeOptions: types,
      showFutureTrips: _controller.showsFutureTrips,
      initialFilter: _controller.activeFilter,
    );
    if (result != null) _controller.applyFilter(result);
  }

  Future<void> _onRefresh() async {
    final loc = AppLocalizations.of(context)!;
    final tripsProvider = context.read<TripsProvider>();
    final locale = Localizations.localeOf(context);
    final result = await tripsProvider.loadNecessaryTripsData(
      locale: locale,
      hardRefresh: false,
    );
    if (!mounted) return;
    await _controller.refreshSummaryCount();
    if (!mounted) return;
    final message = switch (result) {
      TripsSyncResult.success => '✅ ${loc.refreshCompleted}',
      TripsSyncResult.offline => loc.refreshFailedOffline,
      TripsSyncResult.failed => loc.refreshFailed,
      // The log-in-again sheet opens instead.
      TripsSyncResult.sessionExpired => null,
    };
    if (message != null) {
      AdaptiveInformationMessage.showInfo(message);
    }
  }

  AppPrimaryAction _addTripAction() {
    final loc = AppLocalizations.of(context)!;
    return AppPrimaryAction(
      onPressed: () async {
        final didSave = await openAddTripWizard(context);
        if (!mounted) return;
        if (didSave) _controller.tripsChanged();
      },
      icon: AdaptiveIcons.add,
      label: loc.tripsAddButton,
    );
  }

  @override
  Widget build(BuildContext context) {
    _isShown =
        Visibility.of(context) && (ModalRoute.of(context)?.isCurrent ?? true);
    final repo = context.select((TripsProvider p) => p.repository);
    final isLoading = context.select((TripsProvider p) => p.isLoading);
    final revision = context.select((TripsProvider p) => p.revision);

    _controller.repository = repo;
    if (revision != _seenRevision) {
      _seenRevision = revision;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _controller.refreshSummaryCount(),
      );
    }

    final actions = TripsPageActions(
      onPrimaryActionsReady: widget.onPrimaryActionsReady,
      openFilter: _openFilter,
      refreshKey: _refreshKey,
      onRefresh: _onRefresh,
      addTripAction: _addTripAction,
    );

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<TripsPageController>(
        builder: (context, controller, _) {
          if (repo == null || isLoading || !controller.prefsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return PlatformView(
            material: (_) => TripsPageMaterialView(actions: actions),
            cupertino: (_) => TripsPageCupertinoView(actions: actions),
          );
        },
      ),
    );
  }
}
