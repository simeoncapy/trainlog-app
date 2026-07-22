import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/data/models/changelog.dart';
import 'package:trainlog_app/features/onboarding/onboarding_screen.dart';
import 'package:trainlog_app/features/user/login_page.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/services/changelog_service.dart';
import 'package:trainlog_app/services/flag_cache.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/widgets/changelog_dialog.dart';
import 'package:trainlog_app/widgets/trips_loader.dart';

class HomeGate extends StatefulWidget {
  final WidgetBuilder signedInBuilder;

  const HomeGate({
    super.key,
    required this.signedInBuilder,
  });

  @override
  State<HomeGate> createState() => _HomeGateState();
}

class _HomeGateState extends State<HomeGate> {
  @override
  void initState() {
    super.initState();
    // Deferred to after the first frame so a Navigator and the localizations
    // are available when the changelog dialogue needs to be shown.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkChangelog());
  }

  /// Runs once per launch and decides whether the changelog modal must be
  /// shown, then records the newest changelog version so it never re-triggers.
  ///
  /// - Fresh install (onboarding not completed yet): never show historical
  ///   changes, just remember the current version.
  /// - Existing user without a stored version (updated from an app version
  ///   that predates this feature): show only the latest entry.
  /// - Regular update: show every entry newer than the stored version.
  /// - Newer entries without any change item are recorded silently.
  ///
  /// Only changes relevant to the current platform are displayed: items
  /// tagged os "ios" on Apple devices, "android" on Material ones, and
  /// "all" (the default) everywhere.
  Future<void> _checkChangelog() async {
    final settings = context.read<SettingsProvider>();
    await settings.ready;
    if (!mounted) return;

    final doc = await ChangelogService.load(settings.locale.languageCode);
    final latest = doc.latest;
    if (latest == null) return;

    if (!settings.onboardingCompleted) {
      await settings.setLastSeenChangelog(
        version: latest.version,
        date: latest.date,
      );
      return;
    }

    final storedVersion = settings.lastSeenChangelogVersion;
    final List<ChangelogEntry> newEntries;
    if (storedVersion.isEmpty) {
      newEntries = [latest];
    } else {
      newEntries =
          doc.entries.where((e) => e.isNewerThan(storedVersion)).toList();
      if (newEntries.isEmpty) return; // Already up to date.
    }

    await settings.setLastSeenChangelog(
      version: latest.version,
      date: latest.date,
    );

    final platformOs =
        AppPlatform.isApple ? ChangelogOs.ios : ChangelogOs.android;
    final entriesToShow = newEntries
        .map((e) => e.forOs(platformOs))
        .where((e) => e.hasChanges)
        .toList();
    if (entriesToShow.isEmpty || !mounted) return;

    await ChangelogDialog.show(
      context,
      entries: entriesToShow,
      isFallback: doc.isFallback,
    );
  }

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
          builder: widget.signedInBuilder,
        );
      },
    );
  }
}
