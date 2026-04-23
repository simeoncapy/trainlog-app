import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/app_info_utils.dart';
import 'package:trainlog_app/widgets/auth_form.dart';
import 'package:trainlog_app/widgets/error_banner.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool _signingUp = false;
  String? _error;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _onSignup(
    BuildContext context,
    AuthResult result,
    TrainlogProvider auth,
    AppLocalizations loc
  ) async {
    if (_signingUp) return;

    setState(() => _signingUp = true);

    final settings = context.read<SettingsProvider>();
    final tempError = loc.errorCreationAccount;

    try {
      final (success, failureReason) = await auth.signup(
        username: result.username,
        password: result.password,
        email: result.email!,
        settings: settings,
      );

      if (!mounted) return;

      if (!success) {
          _error = failureReason ?? tempError;
      } else {
        Navigator.of(context).pop();
        settings.setShouldLoadTripsFromApi(true);
      }
    } catch (e) {
      if (!mounted) return;
       _error = tempError;
    } finally {
      if (mounted) setState(() => _signingUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final auth = context.watch<TrainlogProvider>();

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
                      absorbing: _signingUp, // blocks taps while loading
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              loc.createAccountTitle,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 24),
                            AuthForm(
                              type: AuthFormType.createAccount,
                              onSubmitted: (result) => _onSignup(context, result, auth, loc),
                            ),

                            if(_error != null) ... [
                              const SizedBox(height: 16),
                              ErrorBanner(message: _error!)
                            ]
                          ],
                        ),
                      ),
                    ),

                    // Overlay (only covers the Expanded area)
                    if (_signingUp)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
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
                padding: const EdgeInsets.only(bottom: 12, top: 8, left: 16, right: 16),
                child: Column(
                  children: [                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FutureBuilder<String>(
                          future: getAppVersionString(),
                          builder: (context, snap) {
                            if (!snap.hasData) return const SizedBox.shrink();
                            final version = 'v${snap.data} • 2026 Trainlog ';
                            return Text(version);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 4,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            '(${auth.instanceUrl})',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
