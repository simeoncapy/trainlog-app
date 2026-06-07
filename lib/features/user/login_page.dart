import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/features/user/signup_page.dart';
import 'package:trainlog_app/features/user/widgets/instance_selector_widget.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/features/user/widgets/auth_form.dart';
import 'package:trainlog_app/widgets/divider_with_widget.dart';
import 'package:trainlog_app/widgets/footer.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loggingIn = false;

  @override
  void initState() {
    super.initState();

    final auth = context.read<TrainlogProvider>();
    final settings = context.read<SettingsProvider>();
    if (settings.lastUsedInstanceUrl != null && settings.lastUsedInstanceUrl != auth.instanceUrl) {
      auth.setInstanceUrl(settings.lastUsedInstanceUrl!);
    }
  }

  Future<void> _onLogin(BuildContext context, AuthResult result, TrainlogProvider auth) async {
    if (_loggingIn) return;

    setState(() => _loggingIn = true);

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
    final auth = context.watch<TrainlogProvider>();
    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            AbsorbPointer(
              absorbing: _loggingIn,
              child: Column(
                children: [
                  // Scrollable form area
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Logo
                              Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 320, maxHeight: 100),
                                  child: Image.asset(
                                    'assets/logo/wide_cutted.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),

                              // Welcome heading
                              Text(
                                loc.loginWelcomeBack,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                loc.loginSubtitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),

                              // Auth form (username + password + login button)
                              AuthForm(
                                type: AuthFormType.login,
                                onSubmitted: (result) => _onLogin(context, result, auth),
                              ),
                              const SizedBox(height: 24),

                              // Divider with "Change instance"
                              DividerWithText(text: loc.changeInstance),
                              const SizedBox(height: 16),

                              // Instance selector (handles its own bottom sheet)
                              const InstanceSelectorWidget(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Pinned bottom: New here? + Footer
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              loc.loginNewHere,
                              style: theme.textTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: _loggingIn
                                  ? null
                                  : () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const SignupPage()),
                                      ),
                              child: Text(loc.createAccountButton),
                            ),
                          ],
                        ),
                        const Footer(displayInstance: false),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Loading overlay
            if (_loggingIn)
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
    );
  }
}
