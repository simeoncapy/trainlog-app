import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/services/trainlog_service.dart';
import 'package:trainlog_app/utils/app_info_utils.dart';
import 'package:trainlog_app/widgets/auth_form.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _loggingIn = false;

  Future<void> _onLogin(BuildContext context, AuthResult result) async {
    if (_loggingIn) return;

    setState(() => _loggingIn = true);

    final auth = context.read<TrainlogProvider>();
    final settings = context.read<SettingsProvider>();
    final loc = AppLocalizations.of(context)!;

    try {
      final success = await auth.login(
        username: result.username,
        password: result.password,
        settings: settings,
      );

      if (!mounted) return;

      if (!success) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text("${loc.connectionError} ${auth.error ?? ""}")));
      } else {
        // Do things here
        settings.setShouldLoadTripsFromApi(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text("${loc.connectionError} ${auth.error ?? ""}")));
    } finally {
      if (mounted) setState(() => _loggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final auth = context.read<TrainlogProvider>();

    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 30, right: 30, bottom: 10, top: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Image.asset(
                    'assets/logo/wide_cutted.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              Expanded(
                child: Stack(
                  children: [
                    // Main content
                    AbsorbPointer(
                      absorbing: _loggingIn, // blocks taps while loading
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              loc.loginToYourAccount,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 24),
                            AuthForm(
                              type: AuthFormType.login,
                              onSubmitted: (result) => _onLogin(context, result),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loggingIn ? null : () {}, // TODO
                              label: Text(loc.createAccountButton),
                              icon: const Icon(Icons.person_add_alt),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Overlay (only covers the Expanded area)
                    if (_loggingIn)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FutureBuilder<String>(
                      future: getAppVersionString(),
                      builder: (context, snap) {
                        if (!snap.hasData) return const SizedBox.shrink();
                        final version = 'v${snap.data}';
                        return Text(version);
                      },
                    ),
                    Text(
                      ' • 2026 Trainlog (${TrainlogService.baseUrl})',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
