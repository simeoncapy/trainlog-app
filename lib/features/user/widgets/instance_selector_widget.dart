import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';

class InstanceSelectorWidget extends StatelessWidget {
  final VoidCallback onTap;

  const InstanceSelectorWidget({
    super.key,
    required this.onTap,
  });

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
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
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
                      style: theme.textTheme.bodyMedium,
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
