import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/auth_form.dart';

class AuthDialog extends StatefulWidget {
  final AuthFormType type;

  const AuthDialog({
    super.key,
    required this.type,
  });

  static Future<AuthResult?> show(
    BuildContext context, {
    required AuthFormType type,
  }) {
    return showDialog<AuthResult>(
      context: context,
      builder: (_) => AuthDialog(type: type),
    );
  }

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final _formKey = GlobalKey<AuthFormState>();

  void _submit(AuthResult result) {
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.type == AuthFormType.createAccount;
    final loc = AppLocalizations.of(context)!;
    final title = isCreate ? loc.createAccountButton : loc.loginButton;

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: AuthForm(
          key: _formKey,
          type: widget.type,
          onSubmitted: _submit,
          showSubmitButton: false, // use dialog action instead
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => _formKey.currentState?.submit(),
          child: Text(isCreate ? loc.createAccountButtonShort : loc.loginButton),
        ),
      ],
    );
  }
}
