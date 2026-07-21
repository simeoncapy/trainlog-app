// cupertino_shell.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icon, PageRouteBuilder, Scaffold, Theme;
import 'package:provider/provider.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/platform/adaptive_app_bar.dart';
import 'package:trainlog_app/platform/adaptive_bottom_navbar.dart'
    show AdaptiveBottomNavBar, kNavBarClearance;
import 'package:trainlog_app/platform/cupertino_fab.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

import 'package:trainlog_app/features/about/about_page.dart';
import 'package:trainlog_app/features/friends/friends_page.dart';
import 'package:trainlog_app/features/map/map_page.dart';
import 'package:trainlog_app/features/menu/full_screen_menu_page.dart';
import 'package:trainlog_app/features/ranking/ranking_page.dart';
import 'package:trainlog_app/features/settings/settings_page.dart';
import 'package:trainlog_app/features/spr/smart_prerecorder_page.dart';
import 'package:trainlog_app/features/statistics/statistics_page.dart';
import 'package:trainlog_app/features/tags/tags_page.dart';
import 'package:trainlog_app/features/tickets/tickets_page.dart';
import 'package:trainlog_app/features/trainlog/inbox_page.dart';
import 'package:trainlog_app/features/trainlog/trainlog_status_page.dart';
import 'package:trainlog_app/features/trips/trips_page.dart';
import 'package:trainlog_app/features/user/coverage_page.dart';
import 'package:trainlog_app/features/user/dashboard_page.dart';

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

  @override
  void initState() {
    super.initState();
    _currentIndex =
        context.read<SettingsProvider>().landingPage == LandingPage.trips
            ? 1
            : 0;
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      // Pop to root when tapping the active tab
      _navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
    } else {
      setState(() => _currentIndex = index);
    }
  }

  /// Pushes a full-screen sub-page, giving it the shared [AdaptiveAppBar] (with
  /// the back button) here in the shell rather than inside the page itself —
  /// the same way the root pages get their navigation bar from the shell.
  void _pushSubPage(
    BuildContext context,
    String Function(BuildContext) titleBuilder,
    Widget Function(BuildContext, SetPrimaryActions) builder,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _ShellSubPage(
          titleBuilder: titleBuilder,
          builder: builder,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  /// Resolves an [AppPageId] coming from the menu to its page and pushes it.
  /// The bottom-tab pages live in the tab bar and so are ignored here.
  void _pushPage(BuildContext context, AppPageId id) {
    switch (id) {
      case AppPageId.dashboard:
        _pushSubPage(context, (c) => AppLocalizations.of(c)!.menuDashboardTitle,
            (_, __) => const DashboardPage());
        break;
      case AppPageId.coverage:
        _pushSubPage(context, (c) => AppLocalizations.of(c)!.menuCoverageTitle,
            (_, __) => const CoveragePage());
        break;
      case AppPageId.tags:
        _pushSubPage(context, (c) => AppLocalizations.of(c)!.menuTagsTitle,
            (_, setActions) => TagsPage(onPrimaryActionsReady: setActions));
        break;
      case AppPageId.tickets:
        _pushSubPage(context, (c) => AppLocalizations.of(c)!.menuTicketsTitle,
            (_, setActions) => TicketsPage(onPrimaryActionsReady: setActions));
        break;
      case AppPageId.friends:
        _pushSubPage(context, (c) => AppLocalizations.of(c)!.menuFriendsTitle,
            (_, __) => const FriendsPage());
        break;
      case AppPageId.smartPrerecorder:
        _pushSubPage(
            context,
            (c) => AppLocalizations.of(c)!.menuSmartPrerecorderTitle,
            (_, setActions) =>
                SmartPrerecorderPage(onPrimaryActionsReady: setActions));
        break;
      case AppPageId.about:
        _pushSubPage(context, (c) => AppLocalizations.of(c)!.menuAboutTitle,
            (_, __) => const AboutPage());
        break;
      case AppPageId.settings:
      case AppPageId.map:
      case AppPageId.trips:
      case AppPageId.ranking:
      case AppPageId.statistics:
        // Settings has its own menu entry; the tab pages live in the bottom bar.
        break;
    }
  }

  void _openFullScreenMenu(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (ctx, _, __) => FullScreenMenuPage(
          onClose: () => Navigator.of(ctx).pop(),
          onSettingsTap: () {
            Navigator.of(ctx).pop();
            Navigator.of(context).push(PageRouteBuilder(
              pageBuilder: (_, __, ___) => const SettingsPage(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ));
          },
          onPageTap: (id) {
            Navigator.of(ctx).pop();
            _pushPage(context, id);
          },
          onInboxTap: () {
            Navigator.of(ctx).pop();
            _pushSubPage(
                context, InboxPage.pageTitle, (_, __) => const InboxPage());
          },
          onTrainlogStatusTap: () {
            Navigator.of(ctx).pop();
            _pushSubPage(context, TrainlogStatusPage.pageTitle,
                (_, __) => const TrainlogStatusPage());
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
              onMenuTap: () => _openFullScreenMenu(context),
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

/// Full-screen sub-page pushed from the menu (inbox, tags, about, …).
/// Provides the shared [AdaptiveAppBar] with a back button, and surfaces any
/// primary actions the page reports into the navigation bar trailing —
/// mirroring how [_CupertinoRootPage] handles the bottom-tab pages.
class _ShellSubPage extends StatefulWidget {
  final String Function(BuildContext context) titleBuilder;
  final Widget Function(BuildContext context, SetPrimaryActions setActions) builder;

  const _ShellSubPage({required this.titleBuilder, required this.builder});

  @override
  State<_ShellSubPage> createState() => _ShellSubPageState();
}

class _ShellSubPageState extends State<_ShellSubPage> {
  final ValueNotifier<List<AppPrimaryAction>> _actions = ValueNotifier(const []);

  @override
  void dispose() {
    _actions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AdaptiveAppBar(
          title: widget.titleBuilder(context),
          onBack: () => Navigator.of(context).pop(),
          cupertinoTrailing: ValueListenableBuilder<List<AppPrimaryAction>>(
            valueListenable: _actions,
            builder: (_, actions, __) => CupertinoPrimaryActionsRow(actions: actions),
          ),
        ),
        body: widget.builder(context, (actions) => _actions.value = actions),
      ),
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
          bottom: kNavBarClearance + 16,
          right: 16,
          child: ValueListenableBuilder<List<AppPrimaryAction>>(
            valueListenable: _actions,
            builder: (_, actions, __) {
              if (actions.isEmpty) return const SizedBox.shrink();
              final reversed = actions.reversed.toList();
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < reversed.length; i++) ...[
                    _CupertinoMapFab(action: reversed[i]),
                    if (i != reversed.length - 1) const SizedBox(height: 8),
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

/// Squarish primary-colour FAB used on the Cupertino map page (no nav bar).
class _CupertinoMapFab extends StatelessWidget {
  final AppPrimaryAction action;

  const _CupertinoMapFab({required this.action});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: action.onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Center(
            child: Icon(action.icon, size: 24, color: onPrimary),
          ),
        ),
      ),
    );
  }
}

