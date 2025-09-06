import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/auth_form.dart';

class AuthDialog extends StatefulWidget {
  final AuthFormType type;

  const AuthDialog({
    super.key,
    required this.type,
  });

  /// Helper to show the dialog and get the result
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
  void _submit(AuthResult result) {
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.type == AuthFormType.createAccount;
    final loc = AppLocalizations.of(context)!;
    final title = isCreate ? loc.createAccountButton : loc.loginButton;

    // The AuthForm provides the fields and validation.
    // The Dialog provides the window, title and buttons.
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: AuthForm(
          type: widget.type,
          onSubmitted: _submit,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          // This button is outside the form, so it needs to trigger the form's
          // internal submit method. We can't easily do this with a GlobalKey
          // as the AuthForm is internal.
          // A simpler way for now is to just not have this button and let the
          // user submit via the keyboard action.
          // TODO: Re-add this button with better form control.
          onPressed: null, // Simplified: user submits via keyboard
          child: Text(isCreate ? loc.createAccountButtonShort : loc.loginButton),
        ),
      ],
    );
  }
}
