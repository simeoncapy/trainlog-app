import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/features/ranking/cupertino/user_countries_cupertino_view.dart';
import 'package:trainlog_app/features/ranking/material/user_countries_material_view.dart';
import 'package:trainlog_app/features/ranking/user_countries_controller.dart';
import 'package:trainlog_app/ui/design.dart';

/// Drill-down page for the countries-visited leaderboard: the countries a
/// single user has visited, with their flag and localized name. Pushed when
/// a row of the country ranking (or the user's own flags) is tapped. The
/// state lives in [UserCountriesController]; each design has its own view.
class UserCountriesPage extends StatelessWidget {
  /// The user whose countries are listed (shown as the title).
  final String username;

  /// ISO country codes in the backend order (by trip count per country, most
  /// visited first).
  final List<String> countryCodes;

  const UserCountriesPage({
    super.key,
    required this.username,
    required this.countryCodes,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserCountriesController(
        username: username,
        countryCodes: countryCodes,
      ),
      child: PlatformView(
        material: (_) => const UserCountriesMaterialView(),
        cupertino: (_) => const UserCountriesCupertinoView(),
      ),
    );
  }
}
