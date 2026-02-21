// cupertino_shell.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icon;
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/pages/settings/settings_cupertino_page.dart';
import 'package:trainlog_app/platform/cupertino_fab.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

import 'package:trainlog_app/pages/about_page.dart';
import 'package:trainlog_app/pages/coverage_page.dart';
import 'package:trainlog_app/pages/friends_page.dart';
import 'package:trainlog_app/pages/map_page.dart';
import 'package:trainlog_app/pages/ranking_page.dart';
import 'package:trainlog_app/pages/smart_prerecorder_page.dart';
import 'package:trainlog_app/pages/statistics_page.dart';
import 'package:trainlog_app/pages/tags_page.dart';
import 'package:trainlog_app/pages/tickets_page.dart';
import 'package:trainlog_app/pages/trips_page.dart';

typedef SetPrimaryActions = void Function(List<AppPrimaryAction> actions);

class CupertinoShell extends StatefulWidget {
  const CupertinoShell({super.key});

  @override
  State<CupertinoShell> createState() => _CupertinoShellState();
}

class _CupertinoShellState extends State<CupertinoShell> {
  late final CupertinoTabController _controller;
  static const double _tabBarHeight = 50.0; // keep consistent with CupertinoTabBar default

  @override
  void initState() {
    super.initState();
    _controller = CupertinoTabController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoTabScaffold(
      controller: _controller,
      tabBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(icon: Icon(AdaptiveIcons.map), label: l10n.menuMapTitle),
          BottomNavigationBarItem(icon: Icon(AdaptiveIcons.trips), label: l10n.menuTripsTitle),
          BottomNavigationBarItem(icon: Icon(AdaptiveIcons.ranking), label: l10n.menuRankingTitle),
          BottomNavigationBarItem(icon: Icon(AdaptiveIcons.statistics), label: l10n.menuStatisticsTitle),
          BottomNavigationBarItem(icon: Icon(AdaptiveIcons.other), label: l10n.menuIosMore),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (_) {
            switch (index) {
              case 0:
                return _CupertinoRootPage(
                  key: ValueKey(AppPageId.map.name),
                  title: l10n.menuMapTitle,
                  hasNavBar: false,
                  builder: (ctx, setActions) => MapPage(onPrimaryActionsReady: setActions),
                );
              case 1:
                return _CupertinoRootPage(
                  key: ValueKey(AppPageId.trips.name),
                  title: l10n.menuTripsTitle,
                  builder: (ctx, setActions) => TripsPage(onPrimaryActionsReady: setActions),
                );
              case 2:
                return _CupertinoRootPage(
                  key: ValueKey(AppPageId.ranking.name),
                  title: l10n.menuRankingTitle,
                  builder: (_, __) => const RankingPage(),
                );
              case 3:
                return _CupertinoRootPage(
                  key: ValueKey(AppPageId.statistics.name),
                  title: l10n.menuStatisticsTitle,
                  builder: (_, __) => const StatisticsPage(),
                );
              default:
                return _MorePage();
            }
          },
        );
      },
    );
  }
}

class CupertinoPrimaryActionsRow extends StatelessWidget {
  final List<AppPrimaryAction> actions;

  const CupertinoPrimaryActionsRow({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    // Multiple actions: show in a row with FIRST action on the right.
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
                  const SizedBox(width: 4,),
                  Text(reversed[i].label!)
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

    // Reserve: tab bar height + home indicator safe area
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

  Widget _childWithNavBar(double bottomPadding) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: widget.builder(context, (actions) => _actions.value = actions),
    );
  }

  Widget _childWithoutNavBar(MediaQueryData mq) {
    return Stack(
      children: [
        // Map content
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.only(bottom: mq.padding.bottom),
            child: widget.builder(context, (actions) => _actions.value = actions),
          ),
        ),

        // Top-right floating primary actions (replaces nav bar trailing)
        Positioned(
          top: mq.padding.top + 8,
          right: 12,
          child: ValueListenableBuilder<List<AppPrimaryAction>>(
            valueListenable: _actions,
            builder: (_, actions, __) {
              if (actions.isEmpty) return const SizedBox.shrink();

              // Multiple: row with FIRST action on the right.
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

class _MorePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mq = MediaQuery.of(context);
    final bottomPadding = mq.padding.bottom;

    final navBg = CupertinoTheme.of(context).scaffoldBackgroundColor;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: navBg,
        middle: Text(l10n.menuIosMore),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: ListView(
          children: [
            _sectionHeader('Pages'),
            _moreTile(
              context,
              icon: AdaptiveIcons.coverage,
              title: l10n.menuCoverageTitle,
              push: () => _pushSimple(context, l10n.menuCoverageTitle, const CoveragePage()),
            ),
            _moreTile(
              context,
              icon: AdaptiveIcons.tags,
              title: l10n.menuTagsTitle,
              push: () => _pushWithActions(
                context,
                l10n.menuTagsTitle,
                (setActions) => TagsPage(onPrimaryActionsReady: setActions),
              ),
            ),
            _moreTile(
              context,
              icon: AdaptiveIcons.tickets,
              title: l10n.menuTicketsTitle,
              push: () => _pushWithActions(
                context,
                l10n.menuTicketsTitle,
                (setActions) => TicketsPage(onPrimaryActionsReady: setActions),
              ),
            ),
            _moreTile(
              context,
              icon: AdaptiveIcons.friends,
              title: l10n.menuFriendsTitle,
              push: () => _pushSimple(context, l10n.menuFriendsTitle, const FriendsPage()),
            ),
            _moreTile(
              context,
              icon: AdaptiveIcons.smartPrerecorder,
              title: l10n.menuSmartPrerecorderTitle,
              push: () => _pushWithActions(
                context,
                l10n.menuSmartPrerecorderTitle,
                (setActions) => SmartPrerecorderPage(onPrimaryActionsReady: setActions),
              ),
            ),
            _sectionHeader('App'),
            _moreTile(
              context,
              icon: AdaptiveIcons.settings,
              title: l10n.menuSettingsTitle,
              push: () => _pushSimple(context, l10n.menuSettingsTitle, const SettingsCupertinoPage()),
            ),
            _moreTile(
              context,
              icon: AdaptiveIcons.info,
              title: l10n.menuAboutTitle,
              push: () => _pushSimple(context, l10n.menuAboutTitle, const AboutPage()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: CupertinoColors.systemGrey,
        ),
      ),
    );
  }

  Widget _moreTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback push,
  }) {
    return CupertinoListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const CupertinoListTileChevron(),
      onTap: push,
    );
  }

  void _pushSimple(BuildContext context, String title, Widget page) {
    final navBg = CupertinoTheme.of(context).scaffoldBackgroundColor;

    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            backgroundColor: navBg,
            middle: Text(title),
          ),
          child: page,
        ),
      ),
    );
  }

  void _pushWithActions(
    BuildContext context,
    String title,
    Widget Function(SetPrimaryActions setActions) builder,
  ) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => _CupertinoRoutedPage(
          title: title,
          builder: builder,
        ),
      ),
    );
  }
}

class _CupertinoRoutedPage extends StatefulWidget {
  final String title;
  final Widget Function(SetPrimaryActions setActions) builder;

  const _CupertinoRoutedPage({
    required this.title,
    required this.builder,
  });

  @override
  State<_CupertinoRoutedPage> createState() => _CupertinoRoutedPageState();
}

class _CupertinoRoutedPageState extends State<_CupertinoRoutedPage> {
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
      navigationBar: CupertinoNavigationBar(
        backgroundColor: navBg,
        middle: Text(widget.title),
        trailing: ValueListenableBuilder<List<AppPrimaryAction>>(
          valueListenable: _actions,
          builder: (_, actions, __) => CupertinoPrimaryActionsRow(actions: actions),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: widget.builder((actions) => _actions.value = actions),
      ),
    );
  }
}