import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/features/onboarding/onboarding_screen.dart';
import 'package:trainlog_app/features/user/login_page.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/services/flag_cache.dart';
import 'package:trainlog_app/widgets/trips_loader.dart';

class HomeGate extends StatelessWidget {
  final WidgetBuilder signedInBuilder;

  const HomeGate({
    super.key,
    required this.signedInBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, TrainlogProvider>(
      builder: (_, settings, auth, __) {
        if (!settings.onboardingCompleted) {
          return const OnboardingScreen();
        }

        if (!auth.isAuthenticated) {
          return const LoginPage();
        }

        // Warm the flag cache in the background once signed in, so opening the
        // Ranking → Railway Coverage page doesn't wait on flag downloads. The
        // call is idempotent (only the first one does any work).
        context.read<FlagCache>().warmUp(() async {
          final res = await auth.fetchRankingForRailPercentage();
          return <String>{
            for (final e in res.countries) e.countryCode,
            for (final e in res.subdivisions) e.code,
          }.toList();
        });

        return TripsLoader(
          builder: signedInBuilder,
        );
      },
    );
  }
}
