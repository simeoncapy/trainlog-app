import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/navigation/cupertino_shell.dart';
import 'package:trainlog_app/navigation/material_shell.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

class PlatformShell extends StatelessWidget {
  const PlatformShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AppPlatform.isApple ? const CupertinoShell() : const MaterialShell(),
        const _SyncProgressOverlay(),
      ],
    );
  }
}

/// A thin indeterminate [LinearProgressIndicator] pinned just below the
/// status bar.  It is only visible while [TripsProvider.isSyncing] is true,
/// i.e. when a background incremental sync is running after the local DB
/// data has already been presented to the user.
class _SyncProgressOverlay extends StatelessWidget {
  const _SyncProgressOverlay();

  @override
  Widget build(BuildContext context) {
    final isSyncing = context.select<TripsProvider, bool>((t) => t.isSyncing);
    if (!isSyncing) return const SizedBox.shrink();

    final topPadding = MediaQuery.of(context).padding.top; // status-bar height
    return Positioned(
      top: topPadding,
      left: 0,
      right: 0,
      child: LinearProgressIndicator(
        minHeight: 4,
        backgroundColor: Colors.transparent,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
      ),
    );
  }
}
