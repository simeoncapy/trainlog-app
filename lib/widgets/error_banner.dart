import 'package:flutter/material.dart';

enum ErrorSeverity {
  error,
  warning,
  info,
}

class ErrorBanner extends StatelessWidget {
  final String message;
  final ErrorSeverity severity;
  final bool compact;
  final VoidCallback? onClose;

  const ErrorBanner({
    super.key,
    required this.message,
    this.severity = ErrorSeverity.error,
    this.compact = false,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final _Style style = _styleForSeverity(scheme);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            style.icon,
            size: compact ? 16 : 20,
            color: style.foreground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: style.foreground,
                fontWeight: FontWeight.w600,
                fontSize: compact ? 12 : 14,
              ),
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: 4),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                Icons.close,
                size: compact ? 16 : 18,
                color: style.foreground,
              ),
              onPressed: onClose,
            ),
          ],
        ],
      ),
    );
  }

  _Style _styleForSeverity(ColorScheme scheme) {
    switch (severity) {
      case ErrorSeverity.warning:
        return _Style(
          background: Colors.amber,
          foreground: Colors.black87,
          icon: Icons.warning_amber_outlined,
        );
      case ErrorSeverity.info:
        return _Style(
          background: scheme.primaryContainer,
          foreground: scheme.onPrimaryContainer,
          icon: Icons.info_outline,
        );
      case ErrorSeverity.error:
      default:
        return _Style(
          background: scheme.errorContainer,
          foreground: scheme.onErrorContainer,
          icon: Icons.error_outline,
        );
    }
  }
}

class _Style {
  final Color background;
  final Color foreground;
  final IconData icon;

  const _Style({
    required this.background,
    required this.foreground,
    required this.icon,
  });
}
