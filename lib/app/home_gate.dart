import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/features/onboarding/onboarding_screen.dart';
import 'package:trainlog_app/features/user/login_page.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
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

        return TripsLoader(
          builder: signedInBuilder,
        );
      },
    );
  }
}
