import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => SettingsProvider(),
      child: const MyApp(),
    ),
  );
}

class AppPage {
  final AppPageId id;
  final Widget view;
  final String title;
  final IconData? icon; // null for drawer-only pages

  const AppPage({
    required this.id,
    required this.view,
    required this.title,
    this.icon,
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

  final List<AppPage> _pages = const [
    AppPage(id: AppPageId.map, view: MapPage(), title: 'Map', icon: Icons.map),
    AppPage(id: AppPageId.trips, view: TripsPage(), title: 'Trips', icon: Icons.card_travel),
    AppPage(id: AppPageId.ranking, view: RankingPage(), title: 'Ranking', icon: Icons.leaderboard),
    AppPage(id: AppPageId.statistics, view: StatisticsPage(), title: 'Statistics', icon: Icons.show_chart),
    AppPage(id: AppPageId.coverage, view: CoveragePage(), title: 'Coverage', icon: Icons.percent),
    AppPage(id: AppPageId.tags, view: TagsPage(), title: 'Tags', icon: Icons.label),
    AppPage(id: AppPageId.tickets, view: TicketsPage(), title: 'Tickets', icon: Icons.confirmation_number),
    AppPage(id: AppPageId.friends, view: FriendsPage(), title: 'Friends', icon: Icons.people),
    AppPage(id: AppPageId.settings, view: SettingsPage(), title: 'Settings', icon: Icons.settings),
  ];

  bool get isDrawerPage => _selectedIndex >= 4;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  void _onItemTapped(int index) {
    if (index < 4) {
      _previousBottomIndex = index;
    }
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
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
    final currentPage = _pages[_selectedIndex];

    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
          ),
          themeMode: settings.themeMode,
          home: Builder(
            builder: (context) => Scaffold(
              appBar: isDrawerPage
              ? AppBar(
                  title: Text(currentPage.title),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _goBackToBottomNavPage,
                  ),
                )
              : null,
          drawer: isDrawerPage
              ? null
              : Drawer(
                  child: Column(
                    children: [
                      const DrawerHeader(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Menu', style: TextStyle(color: Colors.white)),
                        ),
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
                        color: Colors.black,
                        tooltip: 'Open menu',
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
                        label: _pages[i].title,
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, int index) {
    final page = _pages[index];
    return ListTile(
      leading: Icon(page.icon),
      title: Text(page.title),
      onTap: () {
        Navigator.pop(context);
        _onItemTapped(index);
      },
    );
  }
}
