import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

class MenuHeader extends StatelessWidget {
  const MenuHeader({
    super.key,
  });
  final isConnected = false;

  @override
  Widget build(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    return Align(
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trainlog.me',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 20),
          if (!isConnected) ...[
            ElevatedButton.icon(
              onPressed: () {}, 
              label: Text(appLocalization.loginButton), 
              icon: Icon(Icons.login),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {}, 
              label: Text(appLocalization.createAccountButton), 
              icon: Icon(Icons.person_add_alt),
            ),
          ],
        ],
      ),
    );
  }
}