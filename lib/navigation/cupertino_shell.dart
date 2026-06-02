// cupertino_shell.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icon;
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/platform/adaptive_bottom_navbar.dart'
    show AdaptiveBottomNavBar, kNavBarClearance;
import 'package:trainlog_app/platform/cupertino_fab.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

import 'package:trainlog_app/features/map/map_page.dart';
import 'package:trainlog_app/features/ranking/ranking_page.dart';
import 'package:trainlog_app/features/statistics/statistics_page.dart';
import 'package:trainlog_app/features/trips/trips_page.dart';

typedef SetPrimaryActions = void Function(List<AppPrimaryAction> actions);

class CupertinoShell extends StatefulWidget {
  const CupertinoShell({super.key});

  @override
  State<CupertinoShell> createState() => _CupertinoShellState();
}

class _CupertinoShellState extends State<CupertinoShell> {
  int _currentIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      // Pop to root when tapping the active tab
      _navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
    } else {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final navItems = [
      BottomNavigationBarItem(icon: Icon(AdaptiveIcons.map), label: l10n.menuMapTitle),
      BottomNavigationBarItem(icon: Icon(AdaptiveIcons.trips), label: l10n.menuTripsTitle),
      BottomNavigationBarItem(icon: Icon(AdaptiveIcons.ranking), label: l10n.menuRankingTitle),
      BottomNavigationBarItem(icon: Icon(AdaptiveIcons.statistics), label: l10n.menuStatisticsTitle),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _navigatorKeys[_currentIndex].currentState?.maybePop();
        }
      },
      child: Stack(
        children: [
          // Tab content — only the active tab's navigator is visible
          IndexedStack(
            index: _currentIndex,
            children: [
              _TabNavigator(
                navigatorKey: _navigatorKeys[0],
                builder: (ctx) => _CupertinoRootPage(
                  key: ValueKey(AppPageId.map.name),
                  title: l10n.menuMapTitle,
                  hasNavBar: false,
                  builder: (c, setActions) => MapPage(onPrimaryActionsReady: setActions),
                ),
              ),
              _TabNavigator(
                navigatorKey: _navigatorKeys[1],
                builder: (ctx) => _CupertinoRootPage(
                  key: ValueKey(AppPageId.trips.name),
                  title: l10n.menuTripsTitle,
                  builder: (c, setActions) => TripsPage(onPrimaryActionsReady: setActions),
                ),
              ),
              _TabNavigator(
                navigatorKey: _navigatorKeys[2],
                builder: (ctx) => _CupertinoRootPage(
                  key: ValueKey(AppPageId.ranking.name),
                  title: l10n.menuRankingTitle,
                  builder: (_, __) => const RankingPage(),
                ),
              ),
              _TabNavigator(
                navigatorKey: _navigatorKeys[3],
                builder: (ctx) => _CupertinoRootPage(
                  key: ValueKey(AppPageId.statistics.name),
                  title: l10n.menuStatisticsTitle,
                  builder: (_, __) => const StatisticsPage(),
                ),
              ),
            ],
          ),

          // Floating nav bar at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AdaptiveBottomNavBar(
              currentIndex: _currentIndex,
              items: navItems,
              onTap: _onTabTapped,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final WidgetBuilder builder;

  const _TabNavigator({required this.navigatorKey, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) => CupertinoPageRoute(
        settings: settings,
        builder: builder,
      ),
    );
  }
}

class CupertinoPrimaryActionsRow extends StatelessWidget {
  final List<AppPrimaryAction> actions;

  const CupertinoPrimaryActionsRow({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    final reversed = actions.reversed.toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < reversed.length; i++) ...[
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: reversed[i].onPressed,
            foregroundColor: reversed[i].isDestructive ? CupertinoColors.systemRed.resolveFrom(context) : null,
            child: reversed[i].label == null
                ? Icon(reversed[i].icon)
                : Row(
                    children: [
                      Icon(reversed[i].icon),
                      const SizedBox(width: 4),
                      Text(reversed[i].label!),
                    ],
                  ),
          ),
          if (i != reversed.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _CupertinoRootPage extends StatefulWidget {
  final String title;
  final Widget Function(BuildContext context, SetPrimaryActions setActions) builder;
  final bool hasNavBar;

  const _CupertinoRootPage({
    super.key,
    required this.title,
    required this.builder,
    this.hasNavBar = true,
  });

  @override
  State<_CupertinoRootPage> createState() => _CupertinoRootPageState();
}

class _CupertinoRootPageState extends State<_CupertinoRootPage> {
  final ValueNotifier<List<AppPrimaryAction>> _actions = ValueNotifier(const []);

  @override
  void dispose() {
    _actions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomPadding = mq.padding.bottom;
    final navBg = CupertinoTheme.of(context).scaffoldBackgroundColor;

    return CupertinoPageScaffold(
      navigationBar: widget.hasNavBar
          ? CupertinoNavigationBar(
              backgroundColor: navBg,
              middle: Text(widget.title),
              trailing: ValueListenableBuilder<List<AppPrimaryAction>>(
                valueListenable: _actions,
                builder: (_, actions, __) => CupertinoPrimaryActionsRow(actions: actions),
              ),
            )
          : null,
      child: widget.hasNavBar ? _childWithNavBar(bottomPadding) : _childWithoutNavBar(mq),
    );
  }

  Widget _childWithNavBar(double systemBottomPadding) {
    // Physical padding handles the system safe area (home indicator etc.).
    // The MediaQuery override exposes kNavBarClearance as padding.bottom so
    // scrollable pages can add the right bottom clearance without platform checks.
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(padding: mq.padding.copyWith(bottom: kNavBarClearance)),
      child: Padding(
        padding: EdgeInsets.only(bottom: systemBottomPadding),
        child: widget.builder(context, (actions) => _actions.value = actions),
      ),
    );
  }

  Widget _childWithoutNavBar(MediaQueryData mq) {
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.only(bottom: mq.padding.bottom),
            child: widget.builder(context, (actions) => _actions.value = actions),
          ),
        ),
        Positioned(
          top: mq.padding.top + 8,
          right: 12,
          child: ValueListenableBuilder<List<AppPrimaryAction>>(
            valueListenable: _actions,
            builder: (_, actions, __) {
              if (actions.isEmpty) return const SizedBox.shrink();
              final reversed = actions.reversed.toList();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < reversed.length; i++) ...[
                    CupertinoFloatingActionButton(action: reversed[i]),
                    if (i != reversed.length - 1) const SizedBox(width: 8),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

