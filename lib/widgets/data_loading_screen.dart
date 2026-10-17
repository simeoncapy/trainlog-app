import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

/// Full-screen "loading data" view with the Lottie train animation.
///
/// Shown while the saved session is checked at startup, then as the overlay
/// of [TripsLoader] while trips load, so both steps look like one screen.
class DataLoadingScreen extends StatelessWidget {
  const DataLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text(l10n.dataLoading,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Expanded(child: Lottie.asset('assets/animations/loading.json')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
