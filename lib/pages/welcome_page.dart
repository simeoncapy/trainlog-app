import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/pages/signup_page.dart';
import 'package:trainlog_app/platform/adaptive_information_message.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/app_info_utils.dart';
import 'package:trainlog_app/widgets/auth_form.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _loggingIn = false;

  @override
  void initState() {
    super.initState();

    final auth = context.read<TrainlogProvider>();
    final settings = context.read<SettingsProvider>();
    // If there's a saved instance URL that differs from the current one, try to set it
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

  void _dialogInstanceUrl() {
    final settings = context.read<SettingsProvider>();
    final loc = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: settings.userInstanceUrl);
    final auth = context.read<TrainlogProvider>();
    
    // Initial value calculation
    InstanceType? instanceType = auth
        .getListOfInstances(settings: settings)
        .entries
        .firstWhere((e) => e.value == auth.instanceUrl,
            orElse: () => MapEntry(InstanceType.user, settings.userInstanceUrl))
        .key;

    showDialog(
      context: context,
      builder: (context) {
        // Use StatefulBuilder to allow the dialog to update its own state
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(loc.dialogueChangeInstanceTitle),
              content: RadioGroup<InstanceType>(
                groupValue: instanceType,
                onChanged: (InstanceType? value) {
                  // Use the local setDialogState instead of the page's setState
                  setDialogState(() {
                    instanceType = value;
                  });
                },
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (final e in auth.getListOfInstances(settings: settings).entries)
                        ListTile(
                          title: e.key == InstanceType.user
                              ? TextField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    labelText: loc.dialogueChangeInstanceCustomLabel,
                                  ),
                                  // Optional: Select radio button when typing
                                  onTap: () => setDialogState(() => instanceType = InstanceType.user),
                                )
                              : Text(e.value),
                          leading: Radio<InstanceType>(value: e.key),
                          // Makes the whole row clickable
                          onTap: () => setDialogState(() => instanceType = e.key),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: () async {
                    final userUrl = controller.text.trim();
                    String newUrl;
                    
                    if (instanceType == InstanceType.user && userUrl.isEmpty) {
                      AdaptiveInformationMessage.showInfo("Please enter a valid URL");
                      return;
                    }

                    if (instanceType != InstanceType.user) {
                      newUrl = auth.getListOfInstances(settings: settings)[instanceType]!;
                    } else {
                      newUrl = userUrl;
                    }

                    final success = await auth.setInstanceUrl(newUrl);
                    settings.setLastUsedInstanceUrl(newUrl);
                    if (!success) {
                      if (!context.mounted) return;
                      AdaptiveInformationMessage.showInfo("Error changing instance URL");
                    } else {
                      if (instanceType == InstanceType.user) settings.setUserInstanceUrl(userUrl);
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(loc.dialogueChangeInstanceButton),
                ),
              ],
            );
          },
        );
      },
    );
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
                              onSubmitted: (result) => _onLogin(context, result, auth),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loggingIn ? null : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const SignupPage()),
                                );
                              },
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
                        ElevatedButton.icon(
                          onPressed: _dialogInstanceUrl, 
                          label: Text(
                            loc.dialogueChangeInstanceTitle,
                          ),
                          icon: const Icon(Icons.keyboard_arrow_right),
                          style: ElevatedButton.styleFrom(
                            iconAlignment: IconAlignment.end,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12,),
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
