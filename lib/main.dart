import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/pages/about_page.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/utils/cached_data_utils.dart';
import 'package:trainlog_app/widgets/menu_header.dart';
import 'package:trainlog_app/widgets/trips_loader.dart';
import 'pages/map_page.dart';
import 'pages/trips_page.dart';
import 'pages/ranking_page.dart';
import 'pages/statistics_page.dart';
import 'pages/coverage_page.dart';
import 'pages/tags_page.dart';
import 'pages/tickets_page.dart';
import 'pages/friends_page.dart';
import 'pages/settings_page.dart';
import 'providers/settings_provider.dart';
import 'l10n/app_localizations.dart';

enum AppPageId {
  map,
  trips,
  ranking,
  statistics,
  coverage,
  tags,
  tickets,
  friends,
  settings,
  about,
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required before any async calls

  await AppCacheFilePath.init(); // Initialize paths here

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => TripsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class AppPage {
  final AppPageId id;
  final Widget view;
  final String Function(BuildContext context) titleBuilder;
  final IconData? icon;
  final FloatingActionButton? Function(BuildContext context)? fabBuilder;

  const AppPage({
    required this.id,
    required this.view,
    required this.titleBuilder,
    this.icon,
    this.fabBuilder,
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final PageController _pageController;
  int _selectedIndex = 0;
  int _previousBottomIndex = 0;

  List<AppPage> _pages = [];

  bool get isDrawerPage => _selectedIndex >= 4;
  final ValueNotifier<FloatingActionButton?> _fabNotifier = ValueNotifier(null);
  late final List<FloatingActionButton?> _fabs;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    
    _pages = [
      AppPage(
        id: AppPageId.map,
        view: MapPage(
          onFabReady: (fab) => _updateFabForPage(AppPageId.map, fab),
        ),
        titleBuilder: (context) => AppLocalizations.of(context)!.menuMapTitle,
        icon: Icons.map,
      ),
      AppPage(
        id: AppPageId.trips,
        view: TripsPage(
          onFabReady: (fab) => _updateFabForPage(AppPageId.trips, fab),
        ),
        titleBuilder: (context) => AppLocalizations.of(context)!.menuTripsTitle,
        icon: Icons.commute,
      ),
      AppPage(
        id: AppPageId.ranking,
        view: RankingPage(),
        titleBuilder: (context) =>
            AppLocalizations.of(context)!.menuRankingTitle,
        icon: Icons.emoji_events,
      ),
      AppPage(
        id: AppPageId.statistics,
        view: StatisticsPage(),
        titleBuilder: (context) =>
            AppLocalizations.of(context)!.menuStatisticsTitle,
        icon: Icons.bar_chart,
      ),
      AppPage(
        id: AppPageId.coverage,
        view: CoveragePage(),
        titleBuilder: (context) =>
            AppLocalizations.of(context)!.menuCoverageTitle,
        icon: Icons.percent,
      ),
      AppPage(
        id: AppPageId.tags,
        view: TagsPage(),
        titleBuilder: (context) => AppLocalizations.of(context)!.menuTagsTitle,
        icon: Icons.label,
      ),
      AppPage(
        id: AppPageId.tickets,
        view: TicketsPage(),
        titleBuilder: (context) =>
            AppLocalizations.of(context)!.menuTicketsTitle,
        icon: Icons.confirmation_number,
      ),
      AppPage(
        id: AppPageId.friends,
        view: FriendsPage(),
        titleBuilder: (context) =>
            AppLocalizations.of(context)!.menuFriendsTitle,
        icon: Icons.people,
      ),
      AppPage(
        id: AppPageId.settings,
        view: SettingsPage(),
        titleBuilder: (context) =>
            AppLocalizations.of(context)!.menuSettingsTitle,
        icon: Icons.settings,
      ),
      AppPage(
        id: AppPageId.about,
        view: AboutPage(),
        titleBuilder: (context) => AppLocalizations.of(context)!.menuAboutTitle,
        icon: Icons.info,
      ),
    ];
    _fabs = List<FloatingActionButton?>.filled(_pages.length, null);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fabNotifier.value = _fabs[_selectedIndex];
    });
  }

  void _updateFabForPage(AppPageId id, FloatingActionButton? fab) {
    final index = _indexOf(id);
    if (index != -1) {
      _fabs[index] = fab;
      if (_selectedIndex == index) {
        _fabNotifier.value = fab;
      }
    }
  }

  void _onItemTapped(int index) {
    if (index < 4) {
      _previousBottomIndex = index;
    }
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);

    _fabNotifier.value = _fabs[index];
  }

  void _goBackToBottomNavPage() {
    _onItemTapped(_previousBottomIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _indexOf(AppPageId id) => _pages.indexWhere((page) => page.id == id);

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          locale: settings.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
          ),
          themeMode: settings.themeMode,
          home: TripsLoader(
            //csvPath: r'C:\Users\simeo\Downloads\trainlog_papykpy_2025-07-26_034825.csv',
            builder: (context) => _buildAppScaffold(context),
          ),
        );
      },
    );
  }

  Scaffold _buildAppScaffold(BuildContext context) {
    final currentPage = _pages[_selectedIndex];

    return Scaffold(
      appBar: isDrawerPage
          ? AppBar(
              title: Text(currentPage.titleBuilder(context)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBackToBottomNavPage,
              ),
            )
          : null,
      floatingActionButton: ValueListenableBuilder<FloatingActionButton?>(
        valueListenable: _fabNotifier,
        builder: (_, fab, __) => fab ?? const SizedBox.shrink(),
      ),
      drawer: isDrawerPage
          ? null
          : Drawer(
              child: Column(
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(color: Colors.blue),
                    child: MenuHeader(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _buildDrawerItem(context, _indexOf(AppPageId.coverage)),
                        _buildDrawerItem(context, _indexOf(AppPageId.tags)),
                        _buildDrawerItem(context, _indexOf(AppPageId.tickets)),
                        _buildDrawerItem(context, _indexOf(AppPageId.friends)),
                      ],
                    ),
                  ),
                  const Divider(),
                  _buildDrawerItem(context, _indexOf(AppPageId.about)),
                  _buildDrawerItem(context, _indexOf(AppPageId.settings)),
                ],
              ),
            ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _pages.map((p) => p.view).toList(),
          ),
          if (!isDrawerPage)
            Positioned(
              top: 16,
              left: 16,
              child: Builder(
                builder: (innerContext) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceBright,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.menu),
                    color: Theme.of(context).colorScheme.onSurface,
                    tooltip: AppLocalizations.of(context)!.mainMenuButtonTooltip,
                    onPressed: () => Scaffold.of(innerContext).openDrawer(),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: isDrawerPage
          ? null
          : NavigationBar(
              onDestinationSelected: _onItemTapped,
              selectedIndex: _selectedIndex,
              destinations: [
                for (int i = 0; i < 4; i++)
                  NavigationDestination(
                    icon: Icon(_pages[i].icon),
                    selectedIcon: Icon(_pages[i].icon),
                    label: _pages[i].titleBuilder(context),
                  ),
              ],
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

