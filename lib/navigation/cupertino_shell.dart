// cupertino_shell.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter/material.dart' show Scaffold;
import 'package:provider/provider.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/platform/adaptive_app_bar.dart';
import 'package:trainlog_app/platform/adaptive_bottom_navbar.dart'
    show AdaptiveBottomNavBar, kNavBarClearance;
import 'package:trainlog_app/platform/liquid_glass.dart';
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
      CupertinoPageRoute(
        builder: (_) => _ShellSubPage(
          titleBuilder: titleBuilder,
          builder: builder,
        ),
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

  /// The "You" menu is presented as an iOS sheet: it slides up over the
  /// current tab (which recedes behind it) and can be swiped down to dismiss.
  void _openFullScreenMenu(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      CupertinoSheetRoute<void>(
        scrollableBuilder: (ctx, scrollController) => FullScreenMenuPage(
          scrollController: scrollController,
          onClose: () => Navigator.of(ctx).pop(),
          onSettingsTap: () {
            Navigator.of(ctx).pop();
            _pushSubPage(context, (c) => AppLocalizations.of(c)!.menuSettingsTitle,
                (_, __) => const SettingsPage());
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
                  selfTitled: true,
                  builder: (_, __) => const RankingPage(),
                ),
              ),
              _TabNavigator(
                navigatorKey: _navigatorKeys[3],
                builder: (ctx) => _CupertinoRootPage(
                  key: ValueKey(AppPageId.statistics.name),
                  title: l10n.menuStatisticsTitle,
                  selfTitled: true,
                  builder: (_, __) => const StatisticsPage(),
                ),
              ),
            ],
          ),

          // Scroll-edge effect: content fading out softly under the glass
          // tab bar keeps the bar legible over busy lists (not on the map,
          // which is meant to be seen edge to edge).
          if (_currentIndex != 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: kNavBarClearance + MediaQuery.of(context).padding.bottom,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        CupertinoTheme.of(context)
                            .scaffoldBackgroundColor
                            .withValues(alpha: 0),
                        CupertinoTheme.of(context)
                            .scaffoldBackgroundColor
                            .withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),
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

/// Trailing navigation bar actions, iOS 26 style: the first (main) action is
/// an amber-tinted glass button, the others are grouped in one glass capsule.
class CupertinoPrimaryActionsRow extends StatelessWidget {
  final List<AppPrimaryAction> actions;

  const CupertinoPrimaryActionsRow({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    final main = actions.first;
    final others = actions.skip(1).toList().reversed.toList();
    final destructive = CupertinoColors.systemRed.resolveFrom(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (others.isNotEmpty) ...[
          GlassButtonGroup(
            children: [
              for (final a in others)
                GlassGroupItem(
                  icon: a.icon,
                  onPressed: a.onPressed,
                  semanticLabel: a.tooltip ?? a.label,
                  color: a.isDestructive ? destructive : null,
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        if (main.isDestructive)
          GlassIconButton(
            icon: main.icon,
            onPressed: main.onPressed,
            tooltip: main.tooltip ?? main.label,
            color: destructive,
          )
        else
          GlassIconButton(
            icon: main.icon,
            onPressed: main.onPressed,
            tooltip: main.tooltip ?? main.label,
            prominent: true,
          ),
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
    // The Scaffold spans the whole screen so its background (and the nav
    // bar's) fills the status bar and home indicator areas; wrapping it in a
    // SafeArea would leave those as black bands. The nav bar pads itself for
    // the status bar; the body only needs to keep clear of the bottom.
    return Scaffold(
      appBar: AdaptiveAppBar(
        title: widget.titleBuilder(context),
        onBack: () => Navigator.of(context).pop(),
        cupertinoTrailing: ValueListenableBuilder<List<AppPrimaryAction>>(
          valueListenable: _actions,
          builder: (_, actions, __) => CupertinoPrimaryActionsRow(actions: actions),
        ),
      ),
      body: SafeArea(
        top: false,
        child: widget.builder(context, (actions) => _actions.value = actions),
      ),
    );
  }
}

class _CupertinoRootPage extends StatefulWidget {
  final String title;
  final Widget Function(BuildContext context, SetPrimaryActions setActions) builder;
  final bool hasNavBar;

  /// The page draws its own title row (with its controls next to it), so the
  /// shell only keeps it clear of the status bar instead of adding a header.
  final bool selfTitled;

  const _CupertinoRootPage({
    super.key,
    required this.title,
    required this.builder,
    this.hasNavBar = true,
    this.selfTitled = false,
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

    return CupertinoPageScaffold(
      child: widget.hasNavBar ? _childWithNavBar() : _childWithoutNavBar(mq),
    );
  }

  Widget _childWithNavBar() {
    // The page runs under the floating glass tab bar, as on iOS 26: content
    // scrolls behind the glass instead of stopping above it. The MediaQuery
    // override exposes the tab bar height plus the system safe area as
    // padding.bottom so scrollable pages keep their last items reachable
    // without any platform checks.
    final mq = MediaQuery.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.selfTitled)
          SizedBox(height: mq.padding.top)
        else
          _LargeTitleBar(title: widget.title, actions: _actions),
        Expanded(
          child: MediaQuery(
            data: mq.copyWith(
              padding: mq.padding.copyWith(
                top: 0,
                bottom: kNavBarClearance + mq.padding.bottom,
              ),
            ),
            child: widget.builder(context, (actions) => _actions.value = actions),
          ),
        ),
      ],
    );
  }

  Widget _childWithoutNavBar(MediaQueryData mq) {
    // The page (the map) runs edge to edge, under the home indicator and the
    // floating nav bar, so no blank strip is left below it. The FABs sit above
    // the nav bar, which itself sits above the system safe area.
    // OSM tiles are always light, so keep dark status bar icons over the map
    // even in dark mode.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Stack(
        children: [
          Positioned.fill(
            child: widget.builder(context, (actions) => _actions.value = actions),
          ),
          Positioned(
            bottom: kNavBarClearance + mq.padding.bottom + 16,
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
      ),
    );
  }
}

/// Root-tab header in the iOS large-title style: the page name in the
/// Trainlog display font, left-aligned, with the page actions as glass
/// buttons on the trailing side.
class _LargeTitleBar extends StatelessWidget {
  final String title;
  final ValueListenable<List<AppPrimaryAction>> actions;

  const _LargeTitleBar({required this.title, required this.actions});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, top + 6, 16, 6),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
              ),
            ),
            ValueListenableBuilder<List<AppPrimaryAction>>(
              valueListenable: actions,
              builder: (_, a, __) => CupertinoPrimaryActionsRow(actions: a),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round amber glass button used for the map's primary action (no nav bar
/// on the map, so it floats above the tab bar instead).
class _CupertinoMapFab extends StatelessWidget {
  final AppPrimaryAction action;

  const _CupertinoMapFab({required this.action});

  @override
  Widget build(BuildContext context) {
    return GlassIconButton(
      icon: action.icon,
      onPressed: action.onPressed,
      tooltip: action.tooltip ?? action.label,
      size: 56,
      iconSize: 24,
      prominent: true,
    );
  }
}
