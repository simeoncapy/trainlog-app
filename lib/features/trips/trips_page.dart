import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainlog_app/app/app_colors.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
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

            // ── Summary block ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _SummaryBlock(count: _summaryCount),
            ),

            // ── Past / Future tab selector ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: AppStepsTabBar(
                tabs: [
                  AppStepsTab(label: loc.yearPastList),
                  AppStepsTab(label: loc.yearFutureList),
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
          _HeaderIconButton(
            icon: isCardView ? Icons.table_rows_outlined : Icons.view_agenda_outlined,
            tooltip: isCardView ? 'Table view' : 'Card view',
            onPressed: onToggleView,
          ),

          // Clear filter (when active)
          if (activeFilter != null) ...[
            const SizedBox(width: 4),
            _HeaderIconButton(
              icon: Icons.search_off,
              tooltip: AppLocalizations.of(context)!.filterClearButton,
              onPressed: onClearFilter,
            ),
          ],

          const SizedBox(width: 4),

          // Filter button
          _AdaptiveFilterButton(
            onPressed: onFilterTap,
            tooltip: AppLocalizations.of(context)!.filterButton,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.isApple) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: CupertinoColors.systemFill.resolveFrom(context),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        tooltip: tooltip,
        iconSize: 20,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }
}

class _AdaptiveFilterButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;

  const _AdaptiveFilterButton({required this.onPressed, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.isApple) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: CupertinoColors.systemFill.resolveFrom(context),
            shape: BoxShape.circle,
          ),
          child: Icon(AdaptiveIcons.filter, size: 20),
        ),
      );
    }

    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.filter_alt),
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        tooltip: tooltip,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.navy;
    final labelColor = isDark ? AppColors.navy : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$count',
              style: TextStyle(
                color: AppColors.amber,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            TextSpan(
              text: ' TRIPS',
              style: TextStyle(
                color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
