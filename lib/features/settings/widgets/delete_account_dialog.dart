import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_button.dart';
import 'package:trainlog_app/platform/adaptive_dialog.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/services/api/account_api.dart';

/// Asks for the password and the username typed back, then deletes the
/// account on the server. Returns true once the account is deleted (the user
/// is then logged out), false or null when cancelled.
///
/// Errors (wrong password, mismatching username, network) are shown inside
/// the dialog so the user can correct them without starting over.
Future<bool?> showDeleteAccountDialog(BuildContext context) {
  return AdaptiveDialog.showCustom<bool>(
    context: context,
    barrierDismissible: false,
    maxHeightFactor: 0.85,
    builder: (_) => const _DeleteAccountDialog(),
  );
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_onChanged);
    _usernameCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() => _error = null);

  bool _canSubmit(String username) =>
      !_busy &&
      _passwordCtrl.text.isNotEmpty &&
      _usernameCtrl.text.trim() == username;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final trainlog = context.read<TrainlogProvider>();
    if (!_canSubmit(trainlog.username ?? '')) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await trainlog.deleteAccount(
      password: _passwordCtrl.text,
      confirmUsername: _usernameCtrl.text.trim(),
      settings: context.read<SettingsProvider>(),
      trips: context.read<TripsProvider>(),
    );
    if (!mounted) return;

    if (result == DeleteAccountResult.deleted) {
      AdaptiveDialog.pop(context, true);
      return;
    }

    setState(() {
      _busy = false;
      _error = switch (result) {
        DeleteAccountResult.wrongPassword => l10n.deleteAccountWrongPassword,
        DeleteAccountResult.confirmMismatch => l10n.deleteAccountConfirmMismatch,
        _ => l10n.deleteAccountFailed,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final username = context.read<TrainlogProvider>().username ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: cs.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.deleteAccountDialogTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(l10n.deleteAccountDialogWarning),
          const SizedBox(height: 16),
          Text(l10n.deleteAccountPasswordLabel, style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordCtrl,
            enabled: !_busy,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            // No autofill hint on purpose: the password must be typed, not
            // filled in, as a deliberate confirmation step.
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: IconButton(
                tooltip: _obscure ? l10n.passwordShowLabel : l10n.passwordHideLabel,
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.deleteAccountConfirmLabel(username),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _usernameCtrl,
            enabled: !_busy,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: cs.error)),
          ],
          const SizedBox(height: 20),
          AdaptiveButton.build(
            context: context,
            type: AdaptiveButtonType.destructive,
            onPressed: _canSubmit(username) ? _submit : null,
            iconWidget: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  )
                : null,
            icon: _busy ? null : Icons.delete_forever,
            label: Text(l10n.deleteAccountConfirmButton),
          ),
          const SizedBox(height: 8),
          AdaptiveButton.build(
            context: context,
            type: AdaptiveButtonType.secondary,
            onPressed: _busy ? null : () => AdaptiveDialog.pop(context, false),
            label: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
        ],
      ),
    );
  }
}
