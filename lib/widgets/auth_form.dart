import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

enum AuthFormType { login, createAccount }

class AuthResult {
  final AuthFormType type;
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

class AuthForm extends StatefulWidget {
  final AuthFormType type;
  final void Function(AuthResult) onSubmitted;

  const AuthForm({
    super.key,
    required this.type,
    required this.onSubmitted,
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
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

    widget.onSubmitted(
      AuthResult(
        type: widget.type,
        email: widget.type == AuthFormType.createAccount
            ? _emailCtrl.text.trim()
            : null,
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.type == AuthFormType.createAccount;
    final loc = AppLocalizations.of(context)!;

    return Form(
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
    );
  }
}
