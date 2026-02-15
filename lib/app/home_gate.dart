import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/pages/welcome_page.dart';
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
    return Consumer<TrainlogProvider>(
      builder: (_, auth, __) {
        if (!auth.isAuthenticated) {
          return const WelcomePage();
        }

        return TripsLoader(
          builder: signedInBuilder,
        );
      },
    );
  }
}
