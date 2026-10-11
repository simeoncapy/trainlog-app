import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/features/user/widgets/auth_form.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';

/// Handles an expired session around the signed-in app, without ever
/// deleting local data:
/// - shows a banner while the session is expired;
/// - opens the log-in-again sheet from the banner, or when the user starts
///   something that needs the server ([TrainlogProvider.loginPrompts]);
/// - re-checks a session that could not be verified at startup when the
///   app comes back to the foreground.
class SessionExpiryHost extends StatefulWidget {
  final Widget child;

  const SessionExpiryHost({super.key, required this.child});

  @override
  State<SessionExpiryHost> createState() => _SessionExpiryHostState();
}

class _SessionExpiryHostState extends State<SessionExpiryHost>
    with WidgetsBindingObserver {
  /// An action often fires several requests: when the sheet is dismissed,
  /// the ones still in flight must not reopen it straight away.
  static const Duration _reopenCooldown = Duration(seconds: 2);

  // Keeps the app's state when the banner appears or disappears above it.
  final GlobalKey _childKey = GlobalKey();
  StreamSubscription<void>? _prompts;
  bool _sheetOpen = false;
  DateTime? _sheetClosedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prompts = context
        .read<TrainlogProvider>()
        .loginPrompts
        .listen((_) => _openSheet(fromBanner: false));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _prompts?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final trips = context.read<TripsProvider>();
    context.read<TrainlogProvider>().revalidateSession().then((confirmed) {
      if (confirmed) trips.syncInBackground();
    });
  }

  Future<void> _openSheet({required bool fromBanner}) async {
    if (_sheetOpen || !mounted) return;
    final closedAt = _sheetClosedAt;
    if (!fromBanner &&
        closedAt != null &&
        DateTime.now().difference(closedAt) < _reopenCooldown) {
      return;
    }

    _sheetOpen = true;
    final trips = context.read<TripsProvider>();
    final loggedIn = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => const _LogInAgainSheet(),
    );
    _sheetOpen = false;
    _sheetClosedAt = DateTime.now();

    if (loggedIn == true) unawaited(trips.syncInBackground());
  }

  @override
  Widget build(BuildContext context) {
    final expired = context.select<TrainlogProvider, bool>((a) => a.sessionExpired);

    return Column(
      children: [
        if (expired) _SessionExpiredBanner(onLogIn: () => _openSheet(fromBanner: true)),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            // The banner already takes the status bar area.
            removeTop: expired,
            child: KeyedSubtree(key: _childKey, child: widget.child),
          ),
        ),
      ],
    );
  }
}

/// Shown instead of a server page (WebView) while the session is expired.
class SessionExpiredPlaceholder extends StatelessWidget {
  const SessionExpiredPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(loc.sessionExpiredWebPage, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.read<TrainlogProvider>().requestLogin(),
              child: Text(loc.loginButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionExpiredBanner extends StatelessWidget {
  final VoidCallback onLogIn;

  const _SessionExpiredBanner({required this.onLogIn});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    const foreground = Colors.black87;

    // Same colours as ErrorBanner's warning.
    return Material(
      color: Colors.amber,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Row(
            children: [
              const Icon(Icons.cloud_off_outlined, size: 20, color: foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loc.sessionExpiredBanner,
                  style: const TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: onLogIn,
                style: TextButton.styleFrom(foregroundColor: foreground),
                child: Text(
                  loc.loginButton,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks the password of the signed-in user again. Pops true once logged in;
/// a failed attempt keeps the sheet open with the reason.
class _LogInAgainSheet extends StatefulWidget {
  const _LogInAgainSheet();

  @override
  State<_LogInAgainSheet> createState() => _LogInAgainSheetState();
}

class _LogInAgainSheetState extends State<_LogInAgainSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _submit(AuthResult result) async {
    if (_busy) return;
    final loc = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });

    final failure = await context.read<TrainlogProvider>().reLogin(result.password);
    if (!mounted) return;

    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = switch (failure) {
        ReLoginFailure.credentials => loc.sessionExpiredWrongPassword,
        ReLoginFailure.network => loc.sessionExpiredNetworkError,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final instanceUrl = context.read<TrainlogProvider>().instanceUrl;

    return Padding(
      // Move above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loc.sessionExpiredTitle,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(loc.sessionExpiredMessage, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(
                instanceUrl,
                style: theme.textTheme.bodySmall
                    ?.merge(AppTheme.monoFont)
                    .copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              AbsorbPointer(
                absorbing: _busy,
                child: AuthForm(
                  type: AuthFormType.login,
                  usernameReadOnly: true,
                  onSubmitted: _submit,
                ),
              ),
              if (_busy) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                child: Text(loc.sessionExpiredContinueOffline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
