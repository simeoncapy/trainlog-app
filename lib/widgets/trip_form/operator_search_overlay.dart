import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/features/trips_add/widgets/full_screen_search_overlay.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/widgets/trip_form/dashed_outline_button.dart';
import 'package:trainlog_app/widgets/trip_form/operator_tiles.dart';

/// Drives the app's full-screen operator search overlay.
///
/// Owns the search field state and the [OverlayEntry] so any form can offer
/// the same operator picker: the add-trip wizard step and the edit/duplicate
/// operator section both open it and only handle the picked name through
/// [onSelected].
///
/// A typed query that matches no known operator can still be committed as a
/// custom operator through the dashed action shown under the search field.
class OperatorSearchOverlay {
  OperatorSearchOverlay({required this.onSelected, this.onClosed});

  /// Called with the operator name the user picked, typed or submitted.
  final ValueChanged<String> onSelected;

  /// Called once the overlay is gone, e.g. to rebuild the host.
  final VoidCallback? onClosed;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  OverlayEntry? _entry;
  List<String> _results = const [];
  TrainlogProvider? _trainlog;

  bool get isOpen => _entry != null;

  void open(BuildContext context) {
    if (_entry != null) return;

    _trainlog = context.read<TrainlogProvider>();
    _controller.clear();
    _results = const [];

    _entry = _buildEntry(AppLocalizations.of(context)!);
    Overlay.of(context).insert(_entry!);

    Future.microtask(() => _focusNode.requestFocus());
  }

  void close() {
    _entry?.remove();
    _entry = null;
    _controller.clear();
    _results = const [];
    _focusNode.unfocus();
    onClosed?.call();
  }

  void dispose() {
    _entry?.remove();
    _entry = null;
    _controller.dispose();
    _focusNode.dispose();
  }

  void _onTextChanged(String value) {
    final query = value.trim();
    _results = query.isEmpty
        ? const []
        : _trainlog?.getClosestOperators(query, limit: 10) ?? const [];
    _entry?.markNeedsBuild();
  }

  /// Commits a raw string, matching it to a known operator when the typed
  /// text is exactly one (case aside).
  void _commitRaw(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;

    final closest = _trainlog?.getClosestOperators(trimmed, limit: 1) ?? const [];
    final toAdd = (closest.isNotEmpty &&
            closest.first.toLowerCase() == trimmed.toLowerCase())
        ? closest.first
        : trimmed;

    onSelected(toAdd);
  }

  OverlayEntry _buildEntry(AppLocalizations loc) {
    return OverlayEntry(
      builder: (context) {
        final query = _controller.text.trim();

        return FullScreenSearchOverlay<String>(
          controller: _controller,
          focusNode: _focusNode,
          items: _results,
          hintText: loc.addTripOperatorHint,
          onChanged: _onTextChanged,
          onSubmitted: (value) {
            _commitRaw(value);
            close();
          },
          onSelected: (op) {
            onSelected(op);
            close();
          },
          onClose: close,
          // Dashed "add as custom" action: hidden until the user has typed
          // at least one character.
          belowSearchField: query.isEmpty
              ? null
              : DashedOutlineButton(
                  label: loc.addTripAddCustomOperator,
                  onTap: () {
                    onSelected(query);
                    close();
                  },
                ),
          itemBuilder: (context, op) => ListTile(
            leading: OperatorLogo(name: op),
            title: Text(op),
          ),
        );
      },
    );
  }
}
