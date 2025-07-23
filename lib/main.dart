import 'package:flutter/material.dart';
import 'pages/map_page.dart';
import 'pages/trips_page.dart';
import 'pages/ranking_page.dart';
import 'pages/statistics_page.dart';
import 'pages/coverage_page.dart';
import 'pages/tags_page.dart';
import 'pages/tickets_page.dart';
import 'pages/friends_page.dart';
import 'pages/settings_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  int _previousBottomIndex = 0;

  final List<Widget> _pages = [
    const MapPage(),        // 0
    const TripsPage(),      // 1
    const RankingPage(),    // 2
    const StatisticsPage(), // 3
    const CoveragePage(),   // 4
    const TagsPage(),       // 5
    const TicketsPage(),    // 6
    const FriendsPage(),    // 7
    const SettingsPage(),   // 8
  ];

  bool get isDrawerPage => _selectedIndex >= 4;

  void _onItemTapped(int index) {
    setState(() {
      if (index < 4) {
        _previousBottomIndex = index;
      }
      _selectedIndex = index;
    });
  }

  void _goBackToBottomNavPage() {
    setState(() {
      _selectedIndex = _previousBottomIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: Builder(
        builder: (context) => Scaffold(
          appBar: isDrawerPage
              ? AppBar(
                  title: const Text('My App'),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _goBackToBottomNavPage,
                  ),
                )
              : null,
          drawer: isDrawerPage
              ? null
              : Drawer(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      DrawerHeader(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        child: Text('Menu'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.percent),
                        title: const Text('Coverage'),
                        onTap: () {
                          Navigator.pop(context);
                          _onItemTapped(4);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.label_outline),
                        title: const Text('Tags'),
                        onTap: () {
                          Navigator.pop(context);
                          _onItemTapped(5);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.confirmation_num_outlined),
                        title: const Text('Tickets'),
                        onTap: () {
                          Navigator.pop(context);
                          _onItemTapped(6);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.group_outlined),
                        title: const Text('Friends'),
                        onTap: () {
                          Navigator.pop(context);
                          _onItemTapped(7);
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('Settings'),
                        onTap: () {
                          Navigator.pop(context);
                          _onItemTapped(8);
                        },
                      ),
                    ],
                  ),
                ),
          body: Stack(
            children: [
              _pages[_selectedIndex],
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
                          width: 3,
                        ),
                        boxShadow: [
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
                        onPressed: () => Scaffold.of(innerContext).openDrawer(),
                        tooltip: 'Open menu',
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
                  destinations: const <Widget>[
                    NavigationDestination(
                      icon: Icon(Icons.map_outlined),
                      selectedIcon: Icon(Icons.map),
                      label: 'Map',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.commute_outlined),
                      selectedIcon: Icon(Icons.commute),
                      label: 'Trips',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.emoji_events_outlined),
                      selectedIcon: Icon(Icons.emoji_events),
                      label: 'Ranking',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart),
                      label: 'Statistics',
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
