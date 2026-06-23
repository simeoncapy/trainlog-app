import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_button.dart';
import 'package:trainlog_app/platform/adaptive_information_message.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';

class InstanceSelectorWidget extends StatelessWidget {
  const InstanceSelectorWidget({super.key});

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // Resize sheet when keyboard appears
      builder: (ctx) => const _InstanceBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<TrainlogProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outline),
      ),
      child: InkWell(
        onTap: () => _showBottomSheet(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.language_outlined, color: cs.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.instanceSelectorLabel.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      auth.instanceUrl,
                      style: theme.textTheme.bodyMedium?.merge(AppTheme.monoFont),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstanceBottomSheet extends StatefulWidget {
  const _InstanceBottomSheet();

  @override
  State<_InstanceBottomSheet> createState() => _InstanceBottomSheetState();
}

class _InstanceBottomSheetState extends State<_InstanceBottomSheet> {
  late InstanceType? _selectedType;
  late TextEditingController _controller;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<TrainlogProvider>();
    final settings = context.read<SettingsProvider>();

    _controller = TextEditingController(text: settings.userInstanceUrl);

    _selectedType = auth
        .getListOfInstances(settings: settings)
        .entries
        .firstWhere(
          (e) => e.value == auth.instanceUrl,
          orElse: () => MapEntry(InstanceType.user, settings.userInstanceUrl ?? ''),
        )
        .key;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final auth = context.read<TrainlogProvider>();
    final settings = context.read<SettingsProvider>();
    final loc = AppLocalizations.of(context)!;

    final userUrl = _controller.text.trim();

    if (_selectedType == InstanceType.user && userUrl.isEmpty) {
      AdaptiveInformationMessage.showInfo(loc.dialogueChangeInstanceCustomLabel);
      return;
    }

    final String newUrl;
    if (_selectedType != InstanceType.user) {
      newUrl = auth.getListOfInstances(settings: settings)[_selectedType]!;
    } else {
      newUrl = userUrl;
    }

    setState(() => _loading = true);
    final success = await auth.setInstanceUrl(newUrl);
    settings.setLastUsedInstanceUrl(newUrl);

    if (!mounted) return;
    setState(() => _loading = false);

    if (!success) {
      AdaptiveInformationMessage.showInfo("Error changing instance URL");
    } else {
      if (_selectedType == InstanceType.user) settings.setUserInstanceUrl(userUrl);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<TrainlogProvider>();
    final settings = context.read<SettingsProvider>();
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final instances = auth.getListOfInstances(settings: settings);

    // Pad for keyboard so content shifts up
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                loc.dialogueChangeInstanceTitle,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 20),

              // Preset instance tiles
              for (final e in instances.entries)
                if (e.key != InstanceType.user)
                  RadioListTile<InstanceType>(
                    value: e.key,
                    groupValue: _selectedType,
                    onChanged: (v) => setState(() => _selectedType = v),
                    title: Text(
                      e.value,
                      style: theme.textTheme.bodyMedium?.merge(AppTheme.monoFont),
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),

              // Custom URL tile
              RadioListTile<InstanceType>(
                value: InstanceType.user,
                groupValue: _selectedType,
                onChanged: (v) => setState(() => _selectedType = v),
                title: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: loc.dialogueChangeInstanceCustomLabel,
                    isDense: true,
                  ),
                  style: AppTheme.monoFont.copyWith(
                    fontSize: theme.textTheme.bodyMedium?.fontSize,
                  ),
                  onTap: () => setState(() => _selectedType = InstanceType.user),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _apply(),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),

              const SizedBox(height: 24),

              AdaptiveButton.build(
                context: context,
                onPressed: _loading ? null : _apply,
                label: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(loc.dialogueChangeInstanceButton),
                type: AdaptiveButtonType.primary,
                minimumSize: const Size(double.infinity, 52),
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
