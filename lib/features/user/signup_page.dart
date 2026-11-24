import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/features/about/privacy_tab.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/core/services/api/api_import.dart';
import 'package:trainlog_app/core/services/signup_captcha.dart';
import 'package:trainlog_app/features/user/widgets/auth_form.dart';
import 'package:trainlog_app/widgets/error_banner.dart';
import 'package:trainlog_app/widgets/footer.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool _signingUp = false;
  bool _verifying = false;
  String? _error;
  late final SignupCaptcha _captcha;

  @override
  void initState() {
    super.initState();
    // Solve the anti-bot challenge while the user fills in the form
    final trainlog = context.read<TrainlogProvider>();
    _captcha = SignupCaptcha(trainlog.fetchSignupChallenge)..prepare();
  }

  Future<void> _onSignup(
    BuildContext context,
    AuthResult result,
    TrainlogProvider auth,
    AppLocalizations loc
  ) async {
    if (_signingUp) return;

    setState(() {
      _signingUp = true;
      _error = null;
    });

    final settings = context.read<SettingsProvider>();
    final navigator = Navigator.of(context);

    try {
      SignupResult res = await _attempt(result, auth, settings);
      // A refused captcha is usually an expired or already used challenge:
      // retry once with a fresh one (_attempt already asked for it) before
      // bothering the user
      if (!res.success && res.isCaptchaError && mounted) {
        res = await _attempt(result, auth, settings);
      }

      if (!mounted) return;

      if (!res.success) {
        _error = switch (res.code) {
          'unreachable' => loc.errorCreationAccountUnreachable,
          'login_failed' => loc.errorCreationAccountLogin,
          _ => res.message ?? loc.errorCreationAccount,
        };
      } else {
        navigator.pop();
        settings.setShouldLoadTripsFromApi(true);
      }
    } catch (e) {
      if (!mounted) return;
      _error = isServerUnreachable(e)
          ? loc.errorCreationAccountUnreachable
          : loc.errorCreationAccount;
    } finally {
      if (mounted) {
        setState(() {
          _signingUp = false;
          _verifying = false;
        });
      }
    }
  }

  Future<SignupResult> _attempt(
    AuthResult result,
    TrainlogProvider auth,
    SettingsProvider settings,
  ) async {
    if (mounted) setState(() => _verifying = true);
    final String altcha;
    try {
      altcha = await _captcha.payload();
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
    try {
      return await auth.signup(
        username: result.username,
        password: result.password,
        email: result.email!,
        altcha: altcha,
        settings: settings,
      );
    } finally {
      // The server accepts each solved challenge only once
      _captcha.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final auth = context.watch<TrainlogProvider>();
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final trainlog = Provider.of<TrainlogProvider>(context, listen: false);

    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 30, right: 30, bottom: 10, top: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320, maxHeight: 100),
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
                            SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                // Handle Privacy Policy link press
                                // PrivacyHtmlTab(url: Uri.parse('${trainlog.instanceUrl}/privacy/$languageCode'))
                                showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) => Dialog.fullscreen(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        Expanded(
                                          child: SingleChildScrollView(
                                            child: Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: PrivacyHtmlTab(url: Uri.parse('${trainlog.instanceUrl}/privacy/$languageCode')),
                                            ),
                                          ),
                                        ),                                        
                                        const SizedBox(height: 15),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
                                        ),
                                        const SizedBox(height: 15),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: Text(loc.createAccountPrivacyPolicy),
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
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                if (_verifying) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    loc.createAccountVerifying,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ],
                            ),
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
                    Footer(),
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
