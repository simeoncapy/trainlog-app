import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/widgets/auth_form.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Future<void> _onLogin(BuildContext context, AuthResult result) async {
    final auth = Provider.of<TrainlogProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    final success = await auth.login(
      username: result.username,
      password: result.password,
      settings: settings,
    );
    
    if (!success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          //SnackBar(content: Text(auth.error ?? 'Login failed')),
          SnackBar(content: Text(loc.connectionError)),
        );
    }
    else
    {
      print("DO THINGS HERE");
      // LOAD TRIPS
      //settings.setShouldReloadPolylines(true);
      settings.setShouldLoadTripsFromApi(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SafeArea(
      child: Scaffold(
        // appBar: AppBar(
        //   title:null,
        //   centerTitle: true,
        // ),
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
              //Spacer(),
              Expanded(
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
                        // showSubmitButton: true (default) -> tap to submit
                      ),
                      SizedBox(height: 24,),
                      ElevatedButton.icon(
                        onPressed: null, // TODO
                        label: Text(loc.createAccountButton),
                        icon: Icon(Icons.person_add_alt),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
