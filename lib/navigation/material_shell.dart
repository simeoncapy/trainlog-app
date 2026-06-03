// material_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/features/settings/settings_page.dart';
import 'package:trainlog_app/platform/adaptive_app_bar.dart';
import 'package:trainlog_app/platform/adaptive_bottom_navbar.dart';
import 'package:trainlog_app/services/android_update_service.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

import 'package:trainlog_app/features/menu/full_screen_menu_page.dart';
import 'package:trainlog_app/features/trainlog/inbox_page.dart';
import 'package:trainlog_app/features/trainlog/trainlog_status_page.dart';
import 'package:trainlog_app/features/about/about_page.dart';
import 'package:trainlog_app/features/user/coverage_page.dart';
import 'package:trainlog_app/features/user/dashboard_page.dart';
import 'package:trainlog_app/features/friends/friends_page.dart';
import 'package:trainlog_app/features/map/map_page.dart';
import 'package:trainlog_app/features/ranking/ranking_page.dart';
import 'package:trainlog_app/features/spr/smart_prerecorder_page.dart';
import 'package:trainlog_app/features/statistics/statistics_page.dart';
import 'package:trainlog_app/features/tags/tags_page.dart';
import 'package:trainlog_app/features/tickets/tickets_page.dart';
import 'package:trainlog_app/features/trips/trips_page.dart';

typedef SetPrimaryActions = void Function(List<AppPrimaryAction> actions);

class MaterialPrimaryActionsFabStack extends StatelessWidget {
  final List<AppPrimaryAction> actions;

  const MaterialPrimaryActionsFabStack({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    // Preserve current behaviour for a single action.
    if (actions.length == 1) {
      final a = actions.first;

      if (a.isExtended) {
        return FloatingActionButton.extended(
          heroTag: 'fab_single',
          onPressed: a.onPressed,
          tooltip: a.tooltip,
          icon: Icon(a.icon),
          label: Text(a.label!),
        );
      }

      return FloatingActionButton(
        heroTag: 'fab_single',
        onPressed: a.onPressed,
        tooltip: a.tooltip,
        child: Icon(a.icon),
      );
    }

    // Multiple actions: FIRST action should be on the bottom.
    // Build a vertical stack where bottom-most is the first action.
    final reversed = actions.reversed.toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int i = 0; i < reversed.length; i++) ...[
          _buildFabFor(reversed[i], index: i),
          if (i != reversed.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildFabFor(AppPrimaryAction a, {required int index}) {
    // index 0 == bottom-most (original first action)
    final hero = 'fab_$index';

    // Only the bottom-most action may be extended (to keep the UI sane).
    if (index == 0 && a.isExtended) {
      return FloatingActionButton.extended(
        heroTag: hero,
        onPressed: a.onPressed,
        tooltip: a.tooltip,
        icon: Icon(a.icon),
        label: Text(a.label!),
      );
    }

    // Secondary actions: icon-only mini FABs.
    return FloatingActionButton(
      heroTag: hero,
      mini: index != 0,
      onPressed: a.onPressed,
      tooltip: a.tooltip,
      child: Icon(a.icon),
    );
  }
}

class MaterialShell extends StatefulWidget {
  const MaterialShell({super.key});

  @override
  State<MaterialShell> createState() => _MaterialShellState();
}

class _MaterialShellState extends State<MaterialShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final PageController _pageController;

  int _selectedIndex = 0;
  int _previousBottomIndex = 0;

  DateTime? _lastBackPress;

  late final List<AppPage> _pages;

  // NEW: list-of-actions per page
  late final List<List<AppPrimaryAction>> _actions;

  // NEW: notifier emits the current page list-of-actions
  final ValueNotifier<List<AppPrimaryAction>> _actionsNotifier = ValueNotifier(const []);

  bool get _isDrawerPage => _selectedIndex >= 4;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);

    _pages = [
      AppPage(
        id: AppPageId.map,
        view: MapPage(
          onPrimaryActionsReady: (actions) => _updateActionsForPage(AppPageId.map, actions),
        ),
        titleBuilder: (c) => AppLocalizations.of(c)!.menuMapTitle,
        icon: AdaptiveIcons.map,
      ),
      AppPage(
        id: AppPageId.trips,
        view: TripsPage(
          onPrimaryActionsReady: (actions) => _updateActionsForPage(AppPageId.trips, actions),
        ),
        titleBuilder: (c) => AppLocalizations.of(c)!.menuTripsTitle,
        icon: AdaptiveIcons.trips,
      ),
      AppPage(
        id: AppPageId.ranking,
        view: const RankingPage(),
        titleBuilder: (c) => AppLocalizations.of(c)!.menuRankingTitle,
        icon: AdaptiveIcons.ranking,
      ),
      AppPage(
        id: AppPageId.statistics,
        view: const StatisticsPage(),
        titleBuilder: (c) => AppLocalizations.of(c)!.menuStatisticsTitle,
        icon: AdaptiveIcons.statistics,
      ),

      // Drawer pages
      AppPage(
        id: AppPageId.dashboard,
        view: const DashboardPage(),
        titleBuilder: (c) => AppLocalizations.of(c)!.menuDashboardTitle,
        icon: AdaptiveIcons.dashboard,
      ),
      AppPage(
        id: AppPageId.coverage,
        view: const CoveragePage(),
        titleBuilder: (c) => AppLocalizations.of(c)!.menuCoverageTitle,
        icon: AdaptiveIcons.coverage,
      ),
      AppPage(
        id: AppPageId.tags,
        view: TagsPage(
          onPrimaryActionsReady: (actions) => _updateActionsForPage(AppPageId.tags, actions),
        ),
        titleBuilder: (c) => AppLocalizations.of(c)!.menuTagsTitle,
        icon: AdaptiveIcons.tags,
      ),
      AppPage(
        id: AppPageId.tickets,
        view: TicketsPage(
          onPrimaryActionsReady: (actions) => _updateActionsForPage(AppPageId.tickets, actions),
        ),
        titleBuilder: (c) => AppLocalizations.of(c)!.menuTicketsTitle,
        icon: AdaptiveIcons.tickets,
      ),
      AppPage(
        id: AppPageId.friends,
        view: const FriendsPage(),
        titleBuilder: (c) => AppLocalizations.of(c)!.menuFriendsTitle,
        icon: AdaptiveIcons.friends,
      ),
      AppPage(
        id: AppPageId.smartPrerecorder,
        view: SmartPrerecorderPage(
          onPrimaryActionsReady: (actions) => _updateActionsForPage(AppPageId.smartPrerecorder, actions),
        ),
        titleBuilder: (c) => AppLocalizations.of(c)!.menuSmartPrerecorderTitle,
        icon: AdaptiveIcons.smartPrerecorder,
      ),
      AppPage(
        id: AppPageId.settings,
        view: const SettingsPage(),
        titleBuilder: (c) => AppLocalizations.of(c)!.menuSettingsTitle,
        icon: AdaptiveIcons.settings,
      ),
      AppPage(
        id: AppPageId.about,
        view: const AboutPage(),
        titleBuilder: (c) => AppLocalizations.of(c)!.menuAboutTitle,
        icon: AdaptiveIcons.info,
      ),
    ];

    _actions = List<List<AppPrimaryAction>>.filled(_pages.length, const [], growable: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _actionsNotifier.value = _actions[_selectedIndex];
       AndroidUpdateService.checkForUpdate(context);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _actionsNotifier.dispose();
    super.dispose();
  }

  int _indexOf(AppPageId id) => _pages.indexWhere((p) => p.id == id);

  void _updateActionsForPage(AppPageId id, List<AppPrimaryAction> actions) {
    final index = _indexOf(id);
    if (index == -1) return;

    _actions[index] = actions;

    if (_selectedIndex == index) {
      _actionsNotifier.value = actions;
    }
  }

  void _onItemTapped(int index) {
    if (index < 4) _previousBottomIndex = index;

    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
    _actionsNotifier.value = _actions[index];
  }

  void _goBackToBottomNavPage() => _onItemTapped(_previousBottomIndex);

  void _openFullScreenMenu(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (ctx, _, __) => FullScreenMenuPage(
          onClose: () => Navigator.of(ctx).pop(),
          onSettingsTap: () {
            Navigator.of(ctx).pop();
            _onItemTapped(_indexOf(AppPageId.settings));
          },
          onPageTap: (id) {
            Navigator.of(ctx).pop();
            _onItemTapped(_indexOf(id));
          },
          onInboxTap: () {
            Navigator.of(ctx).pop();
            Navigator.of(context).push(PageRouteBuilder(
              pageBuilder: (_, __, ___) => const InboxPage(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ));
          },
          onTrainlogStatusTap: () {
            Navigator.of(ctx).pop();
            Navigator.of(context).push(PageRouteBuilder(
              pageBuilder: (_, __, ___) => const TrainlogStatusPage(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ));
          },
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 150),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = _pages[_selectedIndex];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isDrawerPage) {
          _goBackToBottomNavPage();
          return;
        }
        // Bottom-tab page: require a second back press within 2 s to exit.
        final now = DateTime.now();
        if (_lastBackPress != null && now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
          return;
        }
        _lastBackPress = now;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.tapAgainToExit),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: ColoredBox(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        child: SafeArea(
        child: Scaffold(
        extendBody: true,
        key: _scaffoldKey,
        appBar: _isDrawerPage
            ? AdaptiveAppBar(
                title: currentPage.titleBuilder(context),
                onBack: _goBackToBottomNavPage,
              )
            : null,

        floatingActionButton: ValueListenableBuilder<List<AppPrimaryAction>>(
          valueListenable: _actionsNotifier,
          builder: (_, actions, __) => MaterialPrimaryActionsFabStack(actions: actions),
        ),

        drawer: null,

        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _pages.map((p) => p.view).toList(),
            ),

            // Hamburger overlay for bottom-tab pages — opens the full-screen menu
            if (!_isDrawerPage)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceBright,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.menu),
                    color: Theme.of(context).colorScheme.onSurface,
                    tooltip: AppLocalizations.of(context)!.mainMenuButtonTooltip,
                    onPressed: () => _openFullScreenMenu(context),
                  ),
                ),
              ),
          ],
        ),

        bottomNavigationBar: _isDrawerPage
            ? null
            : AdaptiveBottomNavBar(
                currentIndex: _selectedIndex, // 0..3 here
                onTap: _onItemTapped,
                items: [
                  for (int i = 0; i < 4; i++)
                    BottomNavigationBarItem(
                      icon: Icon(_pages[i].icon),
                      label: _pages[i].titleBuilder(context),
                    ),
                ],
              ),
      ),
      ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, int index) {
    final page = _pages[index];
    return ListTile(
      leading: Icon(page.icon),
      title: Text(page.titleBuilder(context)),
      onTap: () {
        Navigator.pop(context);
        _onItemTapped(index);
      },
    );
  }
}