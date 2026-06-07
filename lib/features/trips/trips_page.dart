import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/features/menu/menu_summary_card.dart';
import 'package:trainlog_app/features/trips/add_trip_page.dart';
import 'package:trainlog_app/features/trips/widgets/trip_card_view.dart';
import 'package:trainlog_app/features/trips/widgets/trip_table_view.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/widgets/app_steps_tab_bar.dart';
import 'package:trainlog_app/widgets/past_future_selector.dart';
import 'package:trainlog_app/platform/adaptive_widget.dart';
import 'package:trainlog_app/widgets/trips_filter_dialog.dart';

const _kViewPrefKey = 'trips_view_mode'; // 'card' or 'table'

class TripsPage extends StatefulWidget {
  final SetPrimaryActions onPrimaryActionsReady;
  const TripsPage({super.key, required this.onPrimaryActionsReady});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  late TrainlogProvider trainlog;
  TripsFilterResult? _activeFilter;
  TimeMoment _timeMoment = TimeMoment.past;

  bool _isCardView = true; // default; overridden by SharedPreferences
  bool _prefsLoaded = false;

  int _summaryCount = 0;
  int _seenRevision = -1;

  @override
  void initState() {
    super.initState();
    trainlog = Provider.of<TrainlogProvider>(context, listen: false);
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kViewPrefKey);
    if (mounted) {
      setState(() {
        _isCardView = saved != 'table';
        _prefsLoaded = true;
      });
    }
  }

  Future<void> _setCardView(bool isCard) async {
    setState(() => _isCardView = isCard);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kViewPrefKey, isCard ? 'card' : 'table');
  }

  Future<void> _refreshSummaryCount(TripsProvider tripsProvider) async {
    final repo = tripsProvider.repository;
    if (repo == null) return;
    final count = await repo.countFilteredTrips(
      showFutureTrips: _timeMoment == TimeMoment.future,
      filter: _activeFilter,
    );
    if (mounted) setState(() => _summaryCount = count);
  }

  @override
  Widget build(BuildContext context) {
    final tripsProvider = Provider.of<TripsProvider>(context);
    final loc = AppLocalizations.of(context)!;
    final repo = context.select((TripsProvider p) => p.repository);
    final isLoading = context.select((TripsProvider p) => p.isLoading);
    final revision = context.select((TripsProvider p) => p.revision);

    if (revision != _seenRevision) {
      _seenRevision = revision;
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshSummaryCount(tripsProvider));
    }

    if (repo == null || isLoading || !_prefsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onPrimaryActionsReady([_buildPrimaryAction(context)]);
    });

    return SafeArea(
      top: false,
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          final locale = Localizations.localeOf(context);
          await tripsProvider.loadNecessaryTripsData(locale: locale, hardRefresh: false);
          if (!mounted) return;
          await _refreshSummaryCount(tripsProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('✅ ${loc.refreshCompleted}')),
            );
          }
        },
        child: Column(
          children: [
            // ── Page header ─────────────────────────────────────────────
            _PageHeader(
              isCardView: _isCardView,
              activeFilter: _activeFilter,
              onToggleView: () => _setCardView(!_isCardView),
              onFilterTap: () async {
                final locale = Localizations.localeOf(context);
                final operators = tripsProvider.operators;
                final countries = await tripsProvider.getMapCountryCodesSafe(locale: locale);
                final types = tripsProvider.vehicleTypes;

                if (!context.mounted) return;
                final result = await showAdaptiveTripsFilterDialog(
                  context,
                  operatorOptions: operators,
                  countryOptions: countries,
                  typeOptions: types,
                  initialFilter: _activeFilter,
                );

                if (result != null) {
                  setState(() => _activeFilter = result);
                  _refreshSummaryCount(tripsProvider);
                }
              },
              onClearFilter: () {
                setState(() => _activeFilter = null);
                _refreshSummaryCount(tripsProvider);
              },
            ),

            // ── Summary block (card view only) ──────────────────────────
            if (_isCardView)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _SummaryBlock(count: _summaryCount),
              ),

            // ── Past / Future tab selector ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: AppStepsTabBar(
                fullWidth: true,
                tabs: [
                  AppStepsTab(
                    label: loc.yearPastList,
                    leadingIcon: const Icon(Icons.restore),
                  ),
                  AppStepsTab(
                    label: loc.yearFutureList,
                    leadingIcon: const Icon(Icons.next_plan_outlined),
                  ),
                ],
                selectedIndex: _timeMoment == TimeMoment.past ? 0 : 1,
                onTabChanged: (i) {
                  setState(() => _timeMoment = i == 0 ? TimeMoment.past : TimeMoment.future);
                  _refreshSummaryCount(tripsProvider);
                },
              ),
            ),

            // ── Content view ─────────────────────────────────────────────
            Expanded(
              child: _isCardView
                  ? TripCardView(
                      key: ValueKey('card-$_timeMoment-${_activeFilter.hashCode}'),
                      repo: repo,
                      trainlog: trainlog,
                      filter: _activeFilter,
                      timeMoment: _timeMoment,
                    )
                  : TripTableView(
                      key: ValueKey('table-$_timeMoment-${_activeFilter.hashCode}'),
                      repo: repo,
                      trainlog: trainlog,
                      filter: _activeFilter,
                      timeMoment: _timeMoment,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  AppPrimaryAction _buildPrimaryAction(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AppPrimaryAction(
      onPressed: () async {
        final didSave = await Navigator.of(context).push<bool>(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => ChangeNotifierProvider(
              create: (_) => TripFormModel(),
              child: const AddTripPage(),
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );

        if (!context.mounted) return;

        if (didSave == true) {
          setState(() {});
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onPrimaryActionsReady([_buildPrimaryAction(context)]);
          });
        }
      },
      icon: AdaptiveIcons.add,
      label: loc.tripsAddButton,
    );
  }
}

// ---------------------------------------------------------------------------
// Page header with title, view toggle, filter
// ---------------------------------------------------------------------------

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.isCardView,
    required this.activeFilter,
    required this.onToggleView,
    required this.onFilterTap,
    required this.onClearFilter,
  });

  final bool isCardView;
  final TripsFilterResult? activeFilter;
  final VoidCallback onToggleView;
  final VoidCallback onFilterTap;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      child: Row(
        children: [
          // Title — only shown on Material (iOS has it in the nav bar)
          if (!AppPlatform.isApple)
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.menuTripsTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            )
          else
            const Spacer(),

          // View toggle
          AdaptiveAppBarSquareButton(
            icon: isCardView ? Icons.table_chart_outlined : Icons.view_agenda_outlined,
            onPressed: onToggleView,
            tooltip: isCardView ? 'Table view' : 'Card view',
            size: 36,
            iconSize: 18,
          ),

          // Clear filter (when active)
          if (activeFilter != null) ...[
            const SizedBox(width: 8),
            AdaptiveAppBarSquareButton(
              icon: Icons.search_off,
              onPressed: onClearFilter,
              tooltip: AppLocalizations.of(context)!.filterClearButton,
              size: 36,
              iconSize: 18,
              circle: true,
            ),
          ],

          const SizedBox(width: 8),

          // Filter button
          AdaptiveAppBarSquareButton(
            icon: AdaptiveIcons.filter,
            onPressed: onFilterTap,
            tooltip: AppLocalizations.of(context)!.filterButton,
            size: 36,
            iconSize: 18,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary block
// ---------------------------------------------------------------------------

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.inverseSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TripCountLine(count: count),
    );
  }
}
