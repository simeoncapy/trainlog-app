import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/widgets/error_banner.dart';

/// A dismissible error banner that collapses with animation.
/// When dismissed, it can either disappear completely
/// or be replaced by a fixed-height spacer.
class DismissibleErrorBannerBlock extends StatefulWidget {
  final String message;
  final ErrorSeverity severity;
  final EdgeInsets padding;
  final double? collapsedHeight; // ← nullable
  final Duration animationDuration;

  const DismissibleErrorBannerBlock({
    super.key,
    required this.message,
    this.severity = ErrorSeverity.warning,
    this.padding = const EdgeInsets.only(
      left: 8,
      top: 12,
      right: 8,
      bottom: 12,
    ),
    this.collapsedHeight, // ← null = nothing
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<DismissibleErrorBannerBlock> createState() =>
      _DismissibleErrorBannerBlockState();
}

class _DismissibleErrorBannerBlockState
    extends State<DismissibleErrorBannerBlock>
    with SingleTickerProviderStateMixin {

  bool _showBanner = true;

  @override
  void initState() {
    super.initState();

    final settings = context.read<SettingsProvider>();
    _showBanner = !settings.hideWarningMessage;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: widget.animationDuration,
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: _showBanner
          ? Padding(
              padding: widget.padding,
              child: ErrorBanner(
                message: widget.message,
                severity: widget.severity,
                onClose: () {
                  setState(() {
                    _showBanner = false;
                  });
                },
              ),
            )
          : _buildCollapsed(),
    );
  }

  Widget _buildCollapsed() {
    if (widget.collapsedHeight == null) {
      return const SizedBox.shrink(); // ← nothing
    }
    return SizedBox(height: widget.collapsedHeight);
  }
}
