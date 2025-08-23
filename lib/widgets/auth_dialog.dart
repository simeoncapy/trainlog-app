import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

enum AuthDialogType { login, createAccount }

class AuthResult {
  final AuthDialogType type;
  final String? email; // only set for create account
  final String username;
  final String password;

  AuthResult({
    required this.type,
    required this.username,
    required this.password,
    this.email,
  });
}

class AuthDialog extends StatefulWidget {
  final AuthDialogType type;

  const AuthDialog({
    super.key,
    required this.type,
  });

  /// Helper to show the dialog and get the result
  static Future<AuthResult?> show(
    BuildContext context, {
    required AuthDialogType type,
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
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      AuthResult(
        type: widget.type,
        email: widget.type == AuthDialogType.createAccount
            ? _emailCtrl.text.trim()
            : null,
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.type == AuthDialogType.createAccount;
    final loc = AppLocalizations.of(context)!;
    final title = isCreate ? loc.createAccountButton : loc.loginButton;

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCreate) ...[
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: loc.emailLabel,
                    hintText: loc.emailHint,
                    helperText: loc.emailHelper
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return loc.emailRequiredLabel;
                    // Simple email check
                    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value);
                    if (!ok) return loc.emailValidLabel;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _usernameCtrl,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: loc.usernameLabel,
                ),
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) return loc.usernameRequiredLabel;
                  return null;
                },
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                focusNode: _passwordFocus,
                decoration: InputDecoration(
                  labelText: loc.passwordLabel,
                  suffixIcon: IconButton(
                    tooltip: _obscure ? loc.passwordShowLabel : loc.passwordHideLabel,
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (v) {
                  if ((v ?? '').isEmpty) return loc.passwordRequiredLabel;
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isCreate ? loc.createAccountButtonShort : loc.loginButton),
        ),
      ],
    );
  }
}
